# Flashbook — AWS Migration Implementation Plan

> **Goal:** Replace FastAPI/Render backend with AWS Lambda + API Gateway + DynamoDB
> **AI:** Gemini API called directly from Lambda (no Bedrock needed)
> **Storage:** DynamoDB for slides cache + notes
> **Flutter changes:** 1 line only (`PROD_URL` constant)

---

## Architecture

```
Flutter App
  │
  ├─ GET  /health            → Lambda → { "status": "healthy" }
  ├─ POST /extractText       → Lambda → pypdf → { text, page_count }
  ├─ POST /generateSummary   → Lambda → Gemini API → DynamoDB cache → SummaryResponse
  ├─ POST /generateImage     → Lambda → Gemini Imagen (Pollinations fallback) → image URL
  └─ /notes/*                → Lambda → DynamoDB CRUD
         ↑
  API Gateway REST (us-east-1)
```

> **Key win:** Flutter already calls `/generateSummary` with the exact same JSON schema.
> Zero Flutter code changes except updating the backend URL constant.

---

## Phase 0 — AWS Account Setup

Do this before writing any code.

```bash
# 1. Create IAM user in AWS Console
#    Console → IAM → Users → Create User → "flashbook-deploy"
#    Attach policy: AdministratorAccess
#    Create Access Key → download CSV

# 2. Install tooling (Windows)
winget install Amazon.SAM-CLI
winget install Amazon.AWSCLI

# 3. Configure credentials
aws configure
#   AWS Access Key ID:     <from CSV>
#   AWS Secret Access Key: <from CSV>
#   Default region name:   us-east-1
#   Default output format: json

# 4. Verify it works
aws sts get-caller-identity
```

---

## Phase 1 — New Backend Folder Structure

Create `backend/aws/` alongside the existing `backend/` folder. The old FastAPI backend is untouched until the new one is confirmed working.

```
backend/aws/
├── template.yaml                        ← SAM infra (Lambda + API GW + DynamoDB)
├── requirements.txt                     ← google-generativeai, pypdf, boto3
├── handlers/
│   ├── __init__.py                      ← empty
│   ├── health.py                        ← GET /health
│   ├── extract_text.py                  ← POST /extractText
│   ├── generate_summary.py              ← POST /generateSummary  (core handler)
│   ├── generate_image.py                ← POST /generateImage
│   └── notes.py                         ← /notes/* CRUD
└── events/
    └── generate_summary_event.json      ← local test payload
```

---

## Phase 2 — SAM Template (`template.yaml`)

### AWS Resources

| Resource | Type | Key Config |
|---|---|---|
| `FlashbookApi` | `AWS::Serverless::Api` | Stage: `Prod`, CORS: `*`, BinaryMedia: `multipart/form-data` |
| `HealthFunction` | Lambda Python 3.12 | 128 MB, 5s timeout |
| `ExtractTextFunction` | Lambda Python 3.12 | 512 MB, 30s timeout |
| `GenerateSummaryFunction` | Lambda Python 3.12 | 1024 MB, 29s timeout |
| `GenerateImageFunction` | Lambda Python 3.12 | 1024 MB, 29s timeout |
| `NotesFunction` | Lambda Python 3.12 | 256 MB, 10s timeout |
| `SlidesTable` | DynamoDB | PAY_PER_REQUEST, PK: `book_id`, SK: `chapter_hash`, TTL: `expires_at` |
| `NotesTable` | DynamoDB | PAY_PER_REQUEST, PK: `note_id`, GSI on `book_id` |

### Environment Variables (injected into all functions)

```yaml
GEMINI_API_KEY:        !Ref GeminiApiKeyParam    # entered at sam deploy time
GEMINI_MODEL_TEXT:     gemini-2.0-flash
GEMINI_MODEL_IMAGE:    gemini-2.0-flash-exp-image-generation
SLIDES_TABLE:          !Ref SlidesTable
NOTES_TABLE:           !Ref NotesTable
```

### IAM Policies

| Function | DynamoDB Permissions |
|---|---|
| `GenerateSummaryFunction` | `GetItem`, `PutItem` on `SlidesTable` |
| `NotesFunction` | `PutItem`, `GetItem`, `UpdateItem`, `DeleteItem`, `Query`, `Scan` on `NotesTable` |

---

## Phase 3 — Lambda Handlers

### `health.py`
```
Route:  GET /health
Output: { "status": "healthy", "service": "flashbook-aws" }
Logic:  Single return statement — no external calls
```

---

### `extract_text.py`
```
Route:  POST /extractText  (multipart/form-data, field name: "file")
Output: { "text": "...", "page_count": N, "char_count": N }

Logic:
  1. Read event['isBase64Encoded'] → base64 decode the body bytes
  2. Parse multipart using Python built-in email module
       email.message_from_bytes(b"Content-Type: {content_type}\r\n\r\n" + body_bytes)
  3. Find the part whose filename ends in .pdf → get_payload(decode=True)
  4. pypdf.PdfReader(io.BytesIO(pdf_bytes))
  5. Concatenate all page.extract_text() strings
  6. Return JSON + CORS headers
```

---

### `generate_summary.py` (most important)
```
Route:  POST /generateSummary
Input:  { text_chunk, book_id?, chapter_title?, mode?, prev_context?, next_context? }
Output: SummaryResponse — identical schema Flutter already parses

Logic:
  1. Parse body, validate len(text_chunk) >= 100
  2. Compute cache key: sha256(text_chunk.encode()).hexdigest()[:16]
  3. DynamoDB GetItem(PK=book_id or "anon", SK=cache_key)
       → HIT:  json.loads(item['slides_json']) + set cached=True → return
  4. Build user_prompt (same logic as _build_user_prompt in gemini_client.py):
       - Prepend MODE: instruction
       - Append prev_context / next_context blocks if provided
       - Append CHAPTER TITLE if provided
       - Wrap text_chunk between ---TARGET CHAPTER TEXT--- markers
  5. Gemini call (synchronous — Lambda does not need async):
       genai.configure(api_key=os.environ['GEMINI_API_KEY'])
       model = genai.GenerativeModel(
           model_name=os.environ['GEMINI_MODEL_TEXT'],
           system_instruction=SYSTEM_PROMPT,       ← copied verbatim from gemini_client.py
           generation_config=GenerationConfig(
               temperature=0.7,
               max_output_tokens=4096,
               response_mime_type="application/json"
           )
       )
       response = model.generate_content(user_prompt)
  6. Parse response (same logic as _parse_gemini_response in gemini_client.py):
       - Strip ```json fencing if present
       - json.loads → validate block types
       - Enforce max 2 image_hint slots
       - Fall back BlockType.INSIGHT for unknown types
  7. DynamoDB PutItem:
       { book_id, chapter_hash, slides_json, expires_at: int(time.time()) + 604800 }
  8. Return SummaryResponse JSON + CORS headers
```

> The `SYSTEM_PROMPT` constant and both helper functions are copied directly from
> `backend/src/services/gemini_client.py` — no prompt engineering needed.

---

### `generate_image.py`
```
Route:  POST /generateImage
Input:  { prompt, width?, height?, style?, book_title?, character_context? }
Output: { "image_url": "data:image/png;base64,..." OR pollinations URL, "prompt": "..." }

Logic:
  1. Try Gemini image generation:
       client = genai.Client(api_key=os.environ['GEMINI_API_KEY'])
       response = client.models.generate_content(
           model=os.environ['GEMINI_MODEL_IMAGE'],
           contents=f"Create a high quality {style} illustration. {prompt}"
       )
       → if response.candidates[0].content.parts[x].inline_data found:
           b64 = base64.b64encode(image_bytes).decode()
           return { "image_url": f"data:image/png;base64,{b64}" }

  2. Fallback — build Pollinations URL (no API key, always works):
       seed = int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 1000000
       encoded = urllib.parse.quote(f"{prompt} {style} style illustration")
       url = f"https://image.pollinations.ai/prompt/{encoded}?width={width}&height={height}&seed={seed}&nologo=true&model=flux"
       return { "image_url": url }

Note: No S3 required. Base64 data URIs are ~150-400 KB — well within API Gateway's
      6 MB response limit. Flutter's cached_network_image handles data URIs natively.
```

---

### `notes.py`
```
Routes: All /notes/* paths handled in one Lambda with httpMethod + path routing

  POST   /notes/create          → DynamoDB PutItem, return note with generated UUID
  GET    /notes/                 → DynamoDB Scan NotesTable
  GET    /notes/book/{book_id}   → DynamoDB Query by book_id GSI
  GET    /notes/{note_id}        → DynamoDB GetItem
  PUT    /notes/{note_id}        → DynamoDB UpdateItem (note_text + updated_at)
  DELETE /notes/{note_id}        → DynamoDB DeleteItem, return 204

DynamoDB item shape matches NoteResponse schema exactly:
  { note_id, book_id, card_index, card_title, note_text, created_at, updated_at }
```

---

## Phase 4 — DynamoDB Schema

### Table: `flashbook-slides`

| Attribute | Type | Role |
|---|---|---|
| `book_id` | String | Partition Key |
| `chapter_hash` | String | Sort Key (sha256[:16] of text_chunk) |
| `slides_json` | String | Full SummaryResponse as JSON string |
| `created_at` | String | ISO 8601 timestamp |
| `expires_at` | Number | Unix timestamp — DynamoDB TTL (7 days) |

### Table: `flashbook-notes`

| Attribute | Type | Role |
|---|---|---|
| `note_id` | String | Partition Key (UUID) |
| `book_id` | String | GSI Partition Key — for querying by book |
| `card_index` | Number | Card position in feed |
| `card_title` | String | Card headline |
| `note_text` | String | User's note content |
| `created_at` | String | ISO 8601 |
| `updated_at` | String | ISO 8601 |

---

## Phase 5 — Flutter Changes (1 line)

**File:** `lib/services/api_config.dart` — line 10

```dart
// BEFORE:
static const String PROD_URL = "https://flashbook-fepc.onrender.com";

// AFTER (fill in your API ID after sam deploy):
static const String PROD_URL = "https://{api-id}.execute-api.us-east-1.amazonaws.com/Prod";
```

**Everything else stays identical:**
- All endpoint names (`/generateSummary`, `/extractText`, `/generateImage`, `/notes/*`)
- All request/response models in `backend_api_client.dart`
- All screens, widgets, providers, state management
- Timeout values (60s for summary, 30s for image — already set correctly)

---

## Phase 6 — Deploy

```bash
cd backend/aws

# Step 1: Package Lambda + dependencies
sam build

# Step 2: First-time guided deploy (answers saved to samconfig.toml)
sam deploy --guided
#   Stack name:          flashbook-backend
#   AWS Region:          us-east-1
#   GeminiApiKeyParam:   <paste your Gemini API key>
#   Confirm changeset:   Y

# Step 3: SAM prints outputs at the end — copy the API URL:
#   Outputs:
#     ApiUrl = https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/Prod
#
# → Paste this URL into api_config.dart PROD_URL

# Subsequent deploys (after code changes):
sam build && sam deploy
```

### Local Testing Before Deploy

```bash
# Test a single function locally (no AWS needed)
sam local invoke GenerateSummaryFunction \
  -e events/generate_summary_event.json \
  --env-vars env.json

# Run full local API Gateway (hit it from Postman or Flutter)
sam local start-api --env-vars env.json

# env.json format:
# {
#   "GenerateSummaryFunction": {
#     "GEMINI_API_KEY": "your-key-here",
#     "GEMINI_MODEL_TEXT": "gemini-2.0-flash",
#     "SLIDES_TABLE": "flashbook-slides",
#     "NOTES_TABLE": "flashbook-notes"
#   }
# }
```

---

## Files Created / Modified

| # | Action | File | What it does |
|---|--------|------|---|
| 1 | CREATE | `backend/aws/template.yaml` | All AWS infra as code |
| 2 | CREATE | `backend/aws/requirements.txt` | `google-generativeai`, `pypdf` |
| 3 | CREATE | `backend/aws/handlers/__init__.py` | Empty — makes handlers a package |
| 4 | CREATE | `backend/aws/handlers/health.py` | `{ "status": "healthy" }` |
| 5 | CREATE | `backend/aws/handlers/extract_text.py` | PDF → text via pypdf |
| 6 | CREATE | `backend/aws/handlers/generate_summary.py` | Gemini + DynamoDB cache |
| 7 | CREATE | `backend/aws/handlers/generate_image.py` | Gemini Image + Pollinations fallback |
| 8 | CREATE | `backend/aws/handlers/notes.py` | Notes CRUD via DynamoDB |
| 9 | CREATE | `backend/aws/events/generate_summary_event.json` | Local test payload |
| 10 | **MODIFY** | `lib/services/api_config.dart` | 1 line: update `PROD_URL` |

---

## Response Time Analysis

| Endpoint | Cold Start | Warm | Notes |
|---|---|---|---|
| `GET /health` | 2-3s | <100ms | 128 MB Lambda — tiny |
| `POST /extractText` | 4-6s | 1-3s | pypdf is fast |
| `POST /generateSummary` (cache hit) | 2s | <500ms | DynamoDB read only |
| `POST /generateSummary` (no cache) | 6-10s | 5-8s | Gemini 2.0 Flash is fast |
| `POST /generateImage` (Gemini) | 8-14s | 6-12s | Image models are slower |
| `POST /generateImage` (Pollinations) | 2s | <500ms | Just builds a URL |

**Flutter strategy:** `/generateSummary` finishes first → show slides immediately.
Images load lazily per-card as user scrolls. `visual_reveal_widget.dart` already handles this correctly — no changes needed.

---

## Verification Checklist

- [ ] `aws sts get-caller-identity` returns your account ID
- [ ] `sam build` completes with no errors
- [ ] `sam local invoke GenerateSummaryFunction` returns valid JSON with `blocks` array
- [ ] `sam deploy --guided` completes and prints `ApiUrl` in Outputs
- [ ] Flutter app shows green connection indicator with new URL
- [ ] Upload a PDF → processing screen → slides appear in feed
- [ ] Upload same PDF again → `"cached": true` in response (faster)
- [ ] AWS Console → DynamoDB → `flashbook-slides` table shows the cached item
- [ ] Image blocks load illustrated images in the feed
- [ ] Notes create / view / delete works end-to-end
- [ ] End-to-end time from PDF upload to slides visible: **< 15 seconds**

---

## Estimated AWS Cost (with $100 credit)

| Service | Usage | Cost |
|---|---|---|
| Lambda | 1M requests/month free tier | **$0** |
| API Gateway | 1M calls/month free tier | **$0** |
| DynamoDB | 25 GB + 200M requests free tier | **$0** |
| Gemini API | Free tier: 15 RPM, 1M TPD | **$0** |

> The entire demo runs within AWS free tier limits.
> The $100 credit is a safety net — you will not need it for the hackathon.
