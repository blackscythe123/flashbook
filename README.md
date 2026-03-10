# Flashbook

Flashbook is a Flutter-based learning app that converts books and PDFs into swipeable, AI-generated learning cards with progress sync, visual generation, and cloud-backed user state.

## What Flashbook Does

1. Upload a PDF (or choose a demo source).
2. Extract and chunk text.
3. Generate structured chapter cards using AI.
4. Render an Instagram-style vertical feed for reading.
5. Save progress and resume across sessions/devices.

## Current Architecture (Implemented)

Production path:

`Flutter app -> API Gateway -> Lambda handlers -> DynamoDB/S3/Cognito -> Gemini APIs`

The repository also contains a local FastAPI backend for local/dev workflows.

## Core Features

- AI chapter summarization into structured learning cards.
- Vertical reading feed with progressive loading.
- PDF upload via presigned S3 URL.
- Batch text extraction from S3-stored PDF pages.
- On-demand AI image generation for visual blocks.
- Reading progress sync and resume support.
- Cognito-based auth with token refresh.
- Library management (list, resume, delete books).
- Bookmarks and notes support (notes backend exists; current UI uses local note persistence).

## Tech Stack

Frontend:
- Flutter
- Provider (state management)
- HTTP package
- SharedPreferences

Backend (AWS path):
- API Gateway (REST)
- AWS Lambda (Python)
- DynamoDB
- S3
- Cognito
- CloudWatch logs

AI:
- Google Gemini text model (summary generation)
- Google Gemini image model (image generation)

Local/dev backend:
- FastAPI + Uvicorn
- Pydantic
- pypdf

## Repository Structure

```text
flashbook/
├── lib/                          # Flutter app
│   ├── screens/                  # UI screens
│   ├── state/                    # Providers
│   ├── services/                 # API/auth/storage services
│   ├── models/                   # Data models
│   └── widgets/                  # Reusable UI widgets
├── backend/
│   ├── main.py                   # FastAPI entrypoint (local mode)
│   ├── src/                      # FastAPI modules (api/core/services)
│   └── aws/
│       ├── template.yaml         # SAM infrastructure
│       ├── handlers/             # Lambda handlers
│       └── events/               # Local SAM test events
├── assets/                       # Static app assets
└── *.md                          # Design, analysis, architecture docs
```

## API Surface (AWS)

Public endpoints:
- `GET /health`
- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/verify`
- `POST /auth/refresh`

Protected endpoints (Cognito authorizer by default):
- `POST /extractText`
- `POST /generateSummary`
- `POST /generateImage`
- `GET|POST|PUT|DELETE /notes/*`
- `POST|GET|PUT|DELETE /books/*`

## Data Model Overview

DynamoDB tables:

1. `flashbook-slides`
- PK: `book_id`
- SK: `chapter_hash`
- TTL: `expires_at`
- Purpose: summary response cache

2. `flashbook-notes`
- PK: `note_id`
- GSI: `book_id-index`
- Purpose: notes storage

3. `flashbook-user-books`
- PK: `user_id`
- SK: `book_id`
- Purpose: user library metadata, progress, extraction status, image URL map

S3 buckets:
- `flashbook-pdfs-<account>`: uploaded source PDFs
- `flashbook-images-<account>`: generated images

## Main User Flow

1. App launches and checks API health.
2. Auth session restore runs via refresh token.
3. User uploads PDF.
4. App requests upload URL (`/books/upload`) and uploads to S3.
5. Backend confirms and counts pages (`/books/{id}/confirm`).
6. App extracts first page batch (`/extractText`).
7. App generates chapter cards (`/generateSummary`) with cache support.
8. User reads in vertical feed; progress syncs (`/books/{id}/progress`).
9. Visual cards trigger lazy image generation (`/generateImage`).

## Running the Flutter App

Prerequisites:
- Flutter SDK (stable)
- Android Studio/Xcode or connected device

Commands:

```bash
flutter pub get
flutter run
```

Backend URL config:
- Production URL is configured in `lib/services/api_config.dart`.

## Running Local FastAPI Backend (Optional)

Use this for local backend development/testing.

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

pip install -r requirements.txt
python main.py
```

Open docs at:
- `http://localhost:8080/docs`

## Deploying AWS Backend (SAM)

Prerequisites:
- AWS CLI configured
- SAM CLI installed

```bash
cd backend/aws
sam build
sam deploy --guided
```

After deploy:
1. Copy `ApiUrl` from stack outputs.
2. Set/update `prodUrl` in `lib/services/api_config.dart` if needed.

## Important Implementation Notes

1. Built vs documented target architecture
- Implemented backend uses Gemini APIs directly.
- Some docs mention Bedrock/CloudFront/Redis/X-Ray/analytics as future architecture targets.

2. Dual backend code paths
- AWS Lambda path is the main production path.
- FastAPI path remains for local/dev and migration support.

3. Notes behavior
- Backend notes APIs are implemented.
- Current app `NoteProvider` still stores notes locally in SharedPreferences.

## Security Notes

- Cognito JWT auth protects most API routes.
- Public routes are mainly health/auth and CORS preflight handlers.
- Tokens are currently stored in SharedPreferences for prototype speed.
- For production hardening, migrate token storage to secure keystore/keychain.



