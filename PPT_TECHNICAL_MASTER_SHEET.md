# Flashbook Technical Master Sheet (For Prototype Submission PPT)

Generated on: 2026-03-08
Audience: judges/reviewers evaluating technical architecture and implementation depth.

## 1. One-Line System Definition

Flashbook is a Flutter mobile app that ingests books/PDFs, converts them into AI-generated learning cards, and serves cross-device progress/content through a serverless AWS backend (API Gateway + Lambda + DynamoDB + S3 + Cognito), with Gemini as the active AI provider.

## 2. Architecture at a Glance

Client: Flutter (`lib/`)

Edge/API: API Gateway REST stage `Prod` (`backend/aws/template.yaml`)

Compute: Lambda handlers (`backend/aws/handlers/*.py`)

Data: DynamoDB (3 tables) + S3 (2 buckets)

Identity: Cognito User Pool + User Pool Client

AI: Google Gemini text/image APIs from Lambda

Observability: CloudWatch logs (implicit for Lambda/API Gateway)

## 3. Service-by-Service Technical Details

## 3.1 AWS Lambda

Purpose:
- Serverless execution for all backend API logic.

Where implemented:
- `backend/aws/template.yaml`
- `backend/aws/handlers/`

Functions and responsibilities:
- `flashbook-health`: health endpoint.
- `flashbook-auth`: signup/login/verify/refresh against Cognito.
- `flashbook-extract-text`: PDF extraction (multipart upload + S3 batch mode).
- `flashbook-generate-summary`: AI summary generation + cache lookup/write.
- `flashbook-generate-image`: AI image generation + S3 storage + presigned URL.
- `flashbook-notes`: notes CRUD in DynamoDB.
- `flashbook-books`: upload workflow, metadata, progress updates, delete.

Configuration detail:
- Global runtime: `python3.13`.
- Global defaults: `Timeout=29s`, `Memory=512MB`.
- Function overrides:
  - health: `128MB`, `5s`
  - auth: `256MB`, `10s`
  - extractText: `512MB`, `30s`
  - generateSummary: `1024MB`, `29s`
  - generateImage: `1024MB`, `29s`
  - notes: `256MB`, `10s`
  - books: `512MB`, `15s`

Extent of usage:
- Core backend is fully Lambda-based in AWS mode (high usage).
- All primary app capabilities route through Lambda.

Why Lambda was chosen:
- Zero server management.
- Pay-per-invocation for prototype cost control.
- Easy scaling for bursty usage (uploads/AI generation).

Current constraints:
- Long-running AI operations bounded by function timeout.
- No queue/workflow orchestration (Step Functions/SQS) yet.

PPT line:
- "100% of production API business logic is serverless Lambda, with per-endpoint memory/time tuning for cost-performance balance."

## 3.2 Amazon API Gateway

Purpose:
- Public HTTPS API surface and request routing.

Where implemented:
- `FlashbookApi` in `backend/aws/template.yaml`.

Routes implemented (no `/v1` prefix in current code):
- `GET /health`
- `POST /auth/signup|login|verify|refresh`
- `POST /extractText`
- `POST /generateSummary`
- `POST /generateImage`
- `GET|POST|PUT|DELETE /notes/*`
- `POST|GET|PUT|DELETE /books/*`

Security model:
- Default authorizer: Cognito.
- Explicitly public: `/health`, `/auth/*`, `OPTIONS` routes.

CORS and binary support:
- CORS allows methods `GET,POST,PUT,DELETE,OPTIONS`.
- Binary media includes multipart and octet-stream for file payloads.

Extent of usage:
- Full entry point for mobile app in AWS deployment.

Why API Gateway was chosen:
- Native Lambda integration.
- Auth integration with Cognito.
- Operationally low-maintenance for prototypes.

Current constraints:
- Public CORS (`*`) is prototype-friendly but not strict production policy.

PPT line:
- "Single API Gateway stage routes every client request to least-privilege Lambda handlers, with Cognito auth by default."

## 3.3 Amazon Cognito

Purpose:
- User identity, token issuance, and secure auth flows.

Where implemented:
- `CognitoUserPool`, `CognitoUserPoolClient` in `backend/aws/template.yaml`.
- Auth operations in `backend/aws/handlers/auth.py`.
- Client integration in `lib/services/auth_service.dart`.

Technical implementation:
- Username attribute: email.
- Auto-verify email enabled.
- Password policy enforced (min 8, lowercase + numbers).
- Auth flows enabled:
  - `USER_PASSWORD_AUTH`
  - `REFRESH_TOKEN_AUTH`

Token usage:
- Flutter stores `id/access/refresh` tokens in `SharedPreferences`.
- API calls attach `Authorization: Bearer <id_token>`.

Extent of usage:
- Fully used for signup/login/session restore in AWS path.

Why Cognito was chosen:
- Managed authentication with JWT support.
- Native API Gateway authorizer compatibility.

Current constraints:
- Client-side token storage currently uses `SharedPreferences` (good for prototype, weaker than secure keystore/keychain).

PPT line:
- "Auth is fully delegated to Cognito with refresh-token based session restore and JWT-protected APIs."

## 3.4 Amazon DynamoDB

Purpose:
- Persistent low-latency NoSQL storage for summaries cache, notes, and user library/progress.

Where implemented:
- Table resources in `backend/aws/template.yaml`.
- Accessed by Lambda handlers `generate_summary.py`, `notes.py`, `books.py`.

Tables and schema:

1. `flashbook-slides`
- PK: `book_id`
- SK: `chapter_hash`
- TTL attribute: `expires_at`
- Stores serialized summary responses.

2. `flashbook-notes`
- PK: `note_id`
- GSI: `book_id-index` on `book_id`
- Stores note text + metadata timestamps/card references.

3. `flashbook-user-books`
- PK: `user_id`
- SK: `book_id`
- Stores upload metadata, reading status, chapter/block progress, pages extracted, optional generated image URL map.

Capacity mode:
- `PAY_PER_REQUEST` (on-demand billing) on all tables.

Extent of usage:
- High and central in AWS mode.
- Summary cache and user continuity depend on it.

Why DynamoDB was chosen:
- Millisecond key-value/doc access.
- Serverless scaling and simple table design.
- TTL support for automatic cache expiry.

Current constraints:
- No advanced analytics model; data modeled for operational access patterns.

PPT line:
- "DynamoDB powers both fast AI-response caching and cross-device continuity with fully serverless on-demand scaling."

## 3.5 Amazon S3

Purpose:
- Object storage for user-uploaded PDFs and generated images.

Where implemented:
- `ImagesBucket`, `PdfBucket` in `backend/aws/template.yaml`.
- Used by `books.py`, `extract_text.py`, `generate_image.py`.

Buckets:
- PDF bucket: `flashbook-pdfs-<account>`
  - CORS for `GET,PUT`.
  - Lifecycle cleanup rule: delete after 90 days.
- Image bucket: `flashbook-images-<account>`
  - CORS for `GET`.

Usage patterns:
- Presigned PUT URL for PDF upload from app.
- Server-side PDF fetch for extraction and page counting.
- Generated images uploaded by Lambda and returned as presigned GET URLs.

Extent of usage:
- High; mandatory for ingestion and generated media delivery.

Why S3 was chosen:
- Durable storage for files.
- Presigned URL workflows reduce backend transfer overhead.

Current constraints:
- No CloudFront CDN in current implementation.

PPT line:
- "S3 handles both source documents and generated assets through presigned secure access patterns."

## 3.6 Amazon CloudWatch

Purpose:
- Runtime logs and operational visibility.

Where used:
- Lambda log output (`logging`) in all handlers.
- API Gateway and Lambda naturally emit logs/metrics to CloudWatch.

Current implementation depth:
- Logging is present and actively used.
- Advanced observability (custom dashboards/alarms/tracing correlation) is not explicitly provisioned in template.

Extent of usage:
- Medium.
- Essential for debugging and validation during prototype runs.

Why CloudWatch matters:
- Primary troubleshooting channel for serverless systems.

PPT line:
- "CloudWatch is the operational backbone for request-level debugging, with room to expand into alarms and dashboards in the production hardening phase."

## 3.7 Google Gemini (Active AI Service)

Purpose:
- Text summarization into structured learning blocks.
- Image generation for visual cards.

Where implemented:
- Lambda: `backend/aws/handlers/generate_summary.py`, `generate_image.py`
- FastAPI path: `backend/src/services/gemini_client.py`, `image_service.py`

Models configured:
- Text: `gemini-2.0-flash`
- Image: `gemini-2.0-flash-exp-image-generation`

Generation details:
- Structured JSON response expected.
- Summary parser enforces block limits and image-hint cap.
- Caching used to reduce repeat AI cost/latency.

Extent of usage:
- Very high.
- Core product value (book -> learning card transformation) depends on this.

Why Gemini was chosen:
- Strong multimodal API availability.
- Fast generation suitable for app interactions.

Fallback behavior:
- Local FastAPI image service includes Pollinations/Picsum fallback.

PPT line:
- "AI is not a side feature; it is the core pipeline transforming raw text into structured, visual learning units."

## 3.8 IAM/SAM Security Model

Purpose:
- Enforce least-privilege access from each Lambda to required resources.

Where implemented:
- Policy templates in `backend/aws/template.yaml`.

Examples:
- `GenerateSummaryFunction`: DynamoDB CRUD on slides table.
- `GenerateImageFunction`: S3 CRUD on images bucket.
- `ExtractTextFunction`: S3 read on PDF bucket.
- `BooksFunction`: DynamoDB CRUD (books) + S3 CRUD (PDF).

Extent of usage:
- High and foundational.

Why chosen:
- Fast secure defaults through SAM policy templates.

## 3.9 Frontend State + Persistence Stack

Purpose:
- Real-time app state + offline/local continuity.

Tech used:
- `provider` for app state orchestration.
- `shared_preferences` for auth/session/book state and note persistence.
- `http` for API calls.

Extent of usage:
- High on client side.

Why chosen:
- Lightweight, rapid prototype velocity.

Current constraints:
- Notes are still local in `NoteProvider`, even though backend notes APIs exist.

## 4. "Everything Else" (Implemented Support Components)

## 4.1 PDF Processing

- Library: `pypdf`.
- Used in Lambda and FastAPI extraction handlers.
- Supports whole-file extraction and batch page-range extraction (S3 mode).

## 4.2 Image Download to Device

- Flutter packages: `gal`, `permission_handler`.
- Enables user-initiated save of generated image to gallery.

## 4.3 Cached Image Rendering

- Flutter package: `cached_network_image`.
- Avoids repeated image fetches and improves feed smoothness.

## 5. Feature-to-Service Mapping (Judge-Friendly)

1. Signup/login/session restore
- Services: Cognito + API Gateway + Lambda(auth) + SharedPreferences.

2. Upload PDF
- Services: API Gateway + Lambda(books) + S3 presigned PUT + DynamoDB(user-books).

3. Parse document pages
- Services: Lambda(extract_text) + S3 + pypdf.

4. Generate learning cards
- Services: Lambda(generate_summary) + Gemini + DynamoDB(slides cache).

5. Generate visuals
- Services: Lambda(generate_image) + Gemini image + S3.

6. Continue where user left off
- Services: DynamoDB(user-books progress) + SharedPreferences local restore.

7. Notes/bookmarks
- Services: DynamoDB notes API exists; current UI note provider stores locally; bookmarks local provider-backed.

8. Monitoring
- Services: CloudWatch logs + Lambda metrics.

## 6. Extent/Maturity Matrix (Prototype Readiness)

Legend:
- High: production-path actively used.
- Medium: used but not fully hardened.
- Low: present in docs/plans but not active.

1. Lambda: High
2. API Gateway: High
3. Cognito: High
4. DynamoDB: High
5. S3: High
6. CloudWatch logs: Medium
7. IAM policy scoping: Medium-High
8. Gemini integration: High
9. Redis/ElastiCache: Low (planned, not deployed in SAM)
10. CloudFront: Low (planned, not deployed)
11. X-Ray: Low (planned, not enabled)
12. Secrets Manager: Low (planned in docs, SAM currently uses parameter/env)
13. EventBridge/Kinesis/Athena analytics: Low (documented target, not implemented)

## 7. Critical "Planned vs Built" Transparency Section

Built now (demonstrable):
- API Gateway + Lambda + Cognito + DynamoDB + S3 + Gemini.
- End-to-end upload -> AI -> feed -> progress update.

Planned/architecture vision (documented):
- Bedrock, Redis, CloudFront CDN, X-Ray tracing, Secrets Manager rotation, analytics pipeline.

How to present this confidently:
- "Prototype validates the core product loop on a serverless foundation; advanced enterprise observability and analytics are the next hardening layer."

## 8. Why This Stack is Technically Strong for a Prototype

1. Serverless-first
- Low infra management overhead, fast iteration.

2. Cost-aware architecture
- On-demand DynamoDB + event-driven Lambda + cache table + lifecycle cleanup.

3. Scalable by default
- API/Lambda/Dynamo scale with usage bursts.

4. Security baseline
- Token-based auth, authorizer-default API routes, scoped function policies.

5. Product-focused AI integration
- AI calls are embedded in core reading workflow, not demo-only wrappers.

## 9. Risks and Mitigations (for Q&A slide)

1. AI latency variance
- Mitigation: caching summaries, chunked processing, lazy image generation.

2. Partial feature split (local notes vs backend notes)
- Mitigation: unify NoteProvider to backend `/notes/*` as next sprint.

3. Token storage security on device
- Mitigation: move from SharedPreferences to secure platform keystore/keychain.

4. Observability depth
- Mitigation: add structured metrics, alarms, dashboards, X-Ray in hardening phase.

## 10. Suggested PPT Slide Sequence (Ready to use)

1. Problem + product loop
2. High-level architecture (client -> API -> lambda -> data/AI)
3. Service deep dive (Lambda/API Gateway/Cognito)
4. Data layer deep dive (DynamoDB/S3)
5. AI pipeline deep dive (summary + image + caching)
6. Security + reliability (IAM/auth/logging)
7. Built vs planned transparency
8. Performance/cost/scalability rationale
9. Risks + roadmap
10. Demo flow recap

## 11. 30-Second Technical Pitch Script

"Flashbook uses a fully serverless AWS backend: API Gateway routes requests to specialized Lambda functions for auth, ingestion, AI summary generation, image generation, and progress sync. Cognito secures user sessions with JWTs. DynamoDB stores summary cache, notes, and user reading state, while S3 handles PDFs and generated images through presigned URLs. CloudWatch provides runtime visibility. The core AI pipeline is powered by Gemini for both text and image generation. This gives us a scalable, low-ops prototype architecture with a clear path to production hardening through deeper observability and analytics services." 
