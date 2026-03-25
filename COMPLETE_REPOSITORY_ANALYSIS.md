# Flashbook Complete Repository Analysis

Generated on: 2026-03-08
Scope: Entire repository (`flashbook`) including Flutter app, Python backend(s), AWS SAM infrastructure, architecture docs, and operational flow.

## 1. Executive Summary

Flashbook is a Flutter-based reading/learning app that transforms books/PDFs into vertically scrollable AI-generated learning cards. The repository currently contains two backend execution paths:

1. Local/container backend using FastAPI (`backend/main.py`) and in-memory persistence.
2. AWS serverless backend using SAM (`backend/aws/template.yaml`) with Lambda + API Gateway + Cognito + DynamoDB + S3.

AI generation is currently implemented with Google Gemini APIs (text + image). Some documents describe a broader target AWS architecture (Bedrock, CloudFront, Redis, analytics services), but those are not fully implemented in code.

## 2. Repository Topology

## 2.1 Frontend

- Flutter app source: `lib/`
- Entry point: `lib/main.dart`
- App/provider setup: `lib/app.dart`
- State orchestration: `lib/state/`
- API clients/config: `lib/services/`
- Main user flows: `lib/screens/`

## 2.2 Backend

- FastAPI backend: `backend/main.py`, `backend/src/**`
- AWS serverless backend: `backend/aws/template.yaml`, `backend/aws/handlers/**`

## 2.3 Documentation / Design / Planning

- High-level design: `design.md`
- Formal requirements: `requirements.md`
- Migration strategy: `AWS_MIGRATION_PLAN.md`
- Mermaid backend architecture: `backend_architecture.mmd`

## 3. Frontend Architecture (Flutter)

## 3.1 Bootstrapping and App Shell

- `lib/main.dart`
  - Locks orientation to portrait.
  - Applies system UI styling.
  - Launches `FlashbookApp`.
- `lib/app.dart`
  - Registers providers: `ThemeProvider`, `ApiConfig`, `AuthProvider`, `BookProvider`, `ReadingProgressProvider`, `BookmarkProvider`, `NoteProvider`.
  - Uses `ChangeNotifierProxyProvider2<ApiConfig, AuthProvider, BookProvider>` to inject API config and token getter into `BookProvider`.

## 3.2 State Management Model

- `AuthProvider`: authentication/session state and Cognito auth operations.
- `BookProvider`: core book lifecycle, upload, extraction, lazy chapter processing, AI summary/image generation, persistence cache.
- `ReadingProgressProvider`: local progress and backend progress sync.
- `BookmarkProvider`: bookmark management (local storage service-backed).
- `NoteProvider`: notes CRUD using local `SharedPreferences` storage (not the backend notes API).

## 3.3 Navigation / UX Flow Structure

- Splash -> onboarding/login/home decision: `lib/screens/splash_screen.dart`
- Home tabs: `lib/screens/home_screen.dart`
  - Library
  - Discover
  - Bookmarks
  - Profile
- Upload source chooser: `lib/screens/book_source_screen.dart`
- Processing view: `lib/screens/processing_screen.dart`
- Reading feed core: `lib/screens/learning_feed_screen.dart`

## 3.4 Frontend Service Layer

### API base config

- `lib/services/api_config.dart`
  - Production URL hardcoded to API Gateway:
    - `https://lnvkdza1u2.execute-api.ap-south-1.amazonaws.com/Prod/`
  - Health check on startup (`/health`).
  - Persists custom backend URL in `SharedPreferences`.

### Backend API client

- `lib/services/backend_api_client.dart`
  - HTTP client with optional `Authorization: Bearer <id_token>` header.
  - Encapsulates summary/image/text extraction, notes, and books endpoints.

### Auth service

- `lib/services/auth_service.dart`
  - Cognito-backed login/signup/verify/refresh via `/auth/*` endpoints.
  - Persists tokens and user identity in `SharedPreferences`.

### Local storage service

- `lib/services/storage_service.dart`
  - In-memory reading progress and bookmarks (demo-style behavior).
  - Notes persisted in `SharedPreferences` list (`notes`).

## 4. Backend Architecture

## 4.1 FastAPI Backend (Local / Container)

### Entry and route mounting

- `backend/main.py`
  - FastAPI app with CORS and global exception handling.
  - Mounted routers:
    - summary: `backend/src/api/generate_summary.py`
    - extract text: `backend/src/api/extract_text.py`
    - image generation: `backend/src/api/generate_image.py`
    - notes: `backend/src/api/notes.py`
  - Health endpoints:
    - `GET /`
    - `GET /health`

### Core backend modules

- Config: `backend/src/core/config.py`
  - Reads `.env`, Gemini model/key settings, limits.
- Schema contracts: `backend/src/core/schemas.py`
  - Pydantic request/response models for summary + notes.
- Gemini text client: `backend/src/services/gemini_client.py`
  - Constructs prompts and parses JSON responses into structured blocks.
- Cache: `backend/src/services/cache_service.py`
  - In-memory TTL cache keyed by hash of request dimensions.
- Image service: `backend/src/services/image_service.py`
  - Primary: Gemini image generation.
  - Fallbacks: Pollinations URL, then Picsum URL.
- Notes service: `backend/src/services/notes_service.py`
  - In-memory notes store.

### FastAPI runtime characteristics

- Persistence is process-local for cache + notes (non-durable across restarts).
- Meant for local dev / demo / containerized single-service usage.

## 4.2 AWS Serverless Backend (SAM)

### Infra definition

- `backend/aws/template.yaml`
  - API Gateway REST API (stage `Prod`) with Cognito authorizer by default.
  - Lambda handlers under `backend/aws/handlers/`.
  - DynamoDB tables:
    - `flashbook-slides`
    - `flashbook-notes` (+ `book_id-index` GSI)
    - `flashbook-user-books`
  - S3 buckets:
    - `flashbook-images-<account>`
    - `flashbook-pdfs-<account>`
  - Cognito User Pool + User Pool Client.

### Lambda handlers

- `health.py`: liveness response.
- `auth.py`: `/auth/signup`, `/auth/login`, `/auth/verify`, `/auth/refresh` via Cognito IDP.
- `extract_text.py`: multipart PDF extraction and JSON batch extraction from S3.
- `generate_summary.py`: Gemini summary generation + DynamoDB slides cache.
- `generate_image.py`: Gemini image generation -> upload to S3 -> return presigned GET URL.
- `notes.py`: notes CRUD in DynamoDB.
- `books.py`: book upload/progress/list/delete with S3 + DynamoDB.

## 5. Database and Storage Analysis

There is no relational SQL database in this repository. Data is spread across DynamoDB, S3, in-memory stores, and SharedPreferences.

## 5.1 DynamoDB (AWS backend)

### `flashbook-slides`

- Key design: `book_id` (PK), `chapter_hash` (SK).
- Stores generated summary payload as JSON string.
- TTL field: `expires_at`.

### `flashbook-notes`

- PK: `note_id`.
- GSI: `book_id-index` for listing notes by book.
- Used by `backend/aws/handlers/notes.py`.

### `flashbook-user-books`

- PK/SK: `user_id` + `book_id`.
- Stores metadata and progress state:
  - `s3_key`, `total_pages`, `pages_extracted`, `status`, chapter/block indices, progress %, optional `image_urls` map.

## 5.2 S3

- PDF uploads bucket (`PDF_BUCKET`) stores source documents.
- Images bucket (`IMAGES_BUCKET`) stores generated image assets.
- Book upload flow uses presigned PUT URL.
- Generated images are returned as presigned GET URLs.

## 5.3 Frontend Local Persistence

- `SharedPreferences`:
  - auth tokens and user identity
  - backend URL and onboarding flags
  - persisted current book/chunks/image cache
  - local notes list
- In-memory (session only): some bookmark/progress structures in `StorageService`.

## 5.4 FastAPI Local Persistence

- In-memory cache service and notes service only.
- Not durable or horizontally shared.

## 6. AWS Services Inventory

## 6.1 Implemented and actively used in code/infrastructure

- Amazon API Gateway (`AWS::Serverless::Api`)
- AWS Lambda (multiple handlers)
- Amazon DynamoDB (3 tables)
- Amazon S3 (PDF + image buckets)
- Amazon Cognito (user pool + client, auth flows)
- AWS IAM policies/roles (via SAM policy templates)
- Amazon CloudWatch Logs (implicit Lambda/API operational logs)

## 6.2 Mentioned in documentation but not implemented in current executable code

From `design.md`/`requirements.md`, these are described as target architecture elements, but no concrete infra/resources/handlers are present in SAM template:

- Amazon Bedrock
- Amazon CloudFront
- Amazon ElastiCache (Redis)
- AWS X-Ray
- AWS Secrets Manager
- AWS KMS
- Amazon EventBridge
- Amazon Kinesis Data Firehose
- Amazon Athena

Practical conclusion: current implementation uses Google Gemini directly, not Bedrock.

## 7. Complete API Surface and Call Mapping

## 7.1 Frontend -> Backend Calls (from Flutter)

Defined in `lib/services/backend_api_client.dart` and `lib/services/auth_service.dart`.

### Health

- `GET /health`
  - Called during API initialization and health checks.

### Auth

- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/verify`
- `POST /auth/refresh`

### Summary + Text + Image

- `POST /generateSummary`
  - Request fields include `text_chunk`, `mode`, optional `book_id`, `chapter_title`, `prev_context`, `next_context`.
- `POST /extractText`
  - Multipart file upload mode (`file`) for PDF extraction.
  - JSON mode (`s3_key`, `start_page`, `page_count`) for S3 batch extraction.
- `POST /generateImage`
  - Prompt + style/context data.

### Cache endpoints (FastAPI route set)

- `GET /cache/stats`

### Notes

- `POST /notes/create`
- `GET /notes/{note_id}`
- `PUT /notes/{note_id}`
- `DELETE /notes/{note_id}`
- `GET /notes/book/{book_id}`
- `GET /notes/`

### Books

- `POST /books/upload`
- `POST /books/{book_id}/confirm`
- `GET /books`
- `PUT /books/{book_id}/progress`
- `DELETE /books/{book_id}`

## 7.2 Backend -> External API Calls

### Gemini (Google)

- Text generation
  - FastAPI: `backend/src/services/gemini_client.py`
  - Lambda: `backend/aws/handlers/generate_summary.py`
- Image generation
  - FastAPI service: `backend/src/services/image_service.py`
  - Lambda: `backend/aws/handlers/generate_image.py`

### Image fallback providers

- Pollinations AI URL generation (`image.pollinations.ai`)
- Picsum placeholder URL generation (`picsum.photos`)

## 7.3 Backend -> AWS Service Calls

- DynamoDB read/write/query/update/delete via `boto3.resource('dynamodb')`.
- S3 put/get/delete and presigned URLs via `boto3.client('s3')`.
- Cognito auth operations via `boto3.client('cognito-idp')`.

## 8. End-to-End Application Flow

## 8.1 Startup and Session Flow

1. App starts -> `SplashScreen`.
2. `ApiConfig.initializeWithFallback()` performs `/health` check.
3. `AuthProvider` attempts session restore using refresh token (`/auth/refresh`).
4. Route decision:
  - onboarding not completed -> `OnboardingScreen`
  - unauthenticated -> `LoginScreen`
  - authenticated -> `HomeScreen`

## 8.2 Authentication Flow

1. User signs up (`/auth/signup`) -> verify email (`/auth/verify`).
2. User signs in (`/auth/login`) -> receives tokens.
3. Tokens stored in `SharedPreferences`.
4. Token injected into API clients for authorized endpoints.

## 8.3 Book Upload and Processing Flow (AWS path)

1. User picks PDF in `BookSourceScreen` or `pickAndUploadPDF`.
2. Frontend calls `POST /books/upload` to get `upload_url` and `book_id`.
3. Frontend uploads file bytes to S3 presigned URL (manual redirect handling).
4. Frontend calls `POST /books/{book_id}/confirm` (backend counts pages).
5. Frontend calls `POST /extractText` JSON mode for first batch.
6. `BookProvider` initializes lazy chapter placeholders.
7. For each chapter chunk, frontend calls `POST /generateSummary`.
8. Blocks with image prompts call `POST /generateImage` lazily.
9. Reading progress and image URL map sync via `PUT /books/{book_id}/progress`.

## 8.4 Reading Feed Flow

1. `LearningFeedScreen` displays flattened blocks.
2. On page change:
  - local progress update
  - backend progress sync
  - chapter prefetch trigger
3. Near end of loaded blocks (80%), app calls `loadMorePages()` -> `/extractText` batch.
4. New chapters are appended and processed in sliding window.

## 8.5 Library Resume Flow

1. `LibraryScreen` fetches user books (`GET /books`).
2. On resume:
  - restore `book_id`, `s3_key`, indices, and `image_urls` cache.
  - load existing persisted state or begin extraction from S3.

## 8.6 Bookmark and Note Flow

### Bookmarks

- Stored via `BookmarkProvider` + `StorageService` in-memory list.
- Displayed in `BookmarkScreen`.
- Bookmark tap navigates to `LearningFeedScreen(bookId, initialCardIndex)`.

### Notes

- Two parallel note paths exist:
  - Backend notes API exists (`/notes/*`).
  - `NoteProvider` currently uses local `SharedPreferences` notes.
- This is an architectural inconsistency: frontend note UI path is not fully wired to backend notes CRUD.

## 9. Architecture Layers and Responsibilities

## 9.1 Client Layer

- Flutter UI and providers manage user interactions, incremental loading, and local caching.

## 9.2 API Layer

- API Gateway in AWS deployment.
- FastAPI app in local deployment.

## 9.3 Compute Layer

- AWS Lambda handlers for serverless production path.
- Python FastAPI process for local/dev path.

## 9.4 AI Layer

- Google Gemini text/image generation APIs.

## 9.5 Data Layer

- DynamoDB + S3 for cloud persistence.
- SharedPreferences + in-memory collections for local/device state.

## 10. Key Implementation Mismatches and Observations

1. Documentation vs implementation
  - Docs describe Bedrock/CloudFront/Redis analytics stack, but executable backend uses Gemini direct + DynamoDB + S3 + Cognito.

2. Dual backend strategy
  - FastAPI and AWS Lambda both implement overlapping endpoints. This is useful for dev/migration, but introduces drift risk.

3. Notes path split
  - Backend notes endpoints are present, but `NoteProvider` is local-only.

4. Persistence split
  - Some critical user state is local (`SharedPreferences`) and some is cloud (`user_books` DynamoDB), causing possible cross-device behavior differences.

5. Cache behavior differs by backend mode
  - FastAPI: in-memory cache.
  - Lambda: DynamoDB-backed cache with TTL.

## 11. Security and Auth Model

- AWS path uses Cognito JWT and API Gateway authorizer as default for protected routes.
- Public/no-auth exceptions include health and auth endpoints, plus OPTIONS preflight routes.
- Flutter stores JWT tokens in `SharedPreferences` (convenient, but less secure than OS secure storage).

## 12. Deployment and Runtime Modes

## 12.1 Local mode

- Run FastAPI locally (`backend/main.py` / uvicorn).
- Uses local env and in-memory services.

## 12.2 Container mode

- `backend/Dockerfile` supports containerized FastAPI deployment.

## 12.3 AWS serverless mode

- SAM stack in `backend/aws/template.yaml`.
- Deploys API, functions, tables, buckets, and Cognito.
- Flutter points to API Gateway `Prod` URL in `ApiConfig.prodUrl`.

## 13. Canonical Source Files for Each Concern

- Flutter bootstrap/providers: `lib/app.dart`, `lib/main.dart`
- API base URL/config: `lib/services/api_config.dart`
- Frontend HTTP client: `lib/services/backend_api_client.dart`
- Auth integration: `lib/services/auth_service.dart`
- Core ingestion/processing logic: `lib/state/book_provider.dart`
- AWS infrastructure: `backend/aws/template.yaml`
- Lambda handlers: `backend/aws/handlers/*.py`
- FastAPI entry and routes: `backend/main.py`, `backend/src/api/*.py`
- Backend schemas/config: `backend/src/core/*.py`

## 14. Final Architecture Statement

The implemented production-oriented architecture in this repository is:

Flutter client -> API Gateway (REST) -> Lambda handlers -> DynamoDB/S3/Cognito, with Google Gemini as the AI provider.

A local FastAPI implementation remains in parallel for development and fallback workflows. Repository documentation includes a broader aspirational AWS platform, but the active code path is the Lambda + Gemini + DynamoDB + S3 + Cognito stack described above.
