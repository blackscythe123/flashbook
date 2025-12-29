# Flashbook AI Backend

Minimal, production-ready AI backend for generating structured book summaries using Google Gemini.

## Architecture

```
backend/
├── main.py                    # FastAPI entry point
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Cloud Run deployment
├── .env.example              # Environment template
└── src/
    ├── api/
    │   └── generate_summary.py    # HTTP handler
    ├── services/
    │   ├── gemini_client.py       # AI wrapper
    │   └── cache_service.py       # Response caching
    └── core/
        ├── config.py              # Environment config
        └── schemas.py             # Request/response models
```

## Quick Start (Local)

### 1. Setup Environment

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure API Key

```bash
# Copy example env file
cp .env.example .env

# Edit .env and add your Gemini API key
# Get one at: https://aistudio.google.com/app/apikey
```

### 3. Run Server

```bash
# Development mode (with auto-reload)
python main.py

# Or using uvicorn directly
uvicorn main:app --reload --port 8080
```

### 4. Test the API

Open http://localhost:8080/docs for interactive API documentation.

**Example request:**

```bash
curl -X POST http://localhost:8080/generateSummary \
  -H "Content-Type: application/json" \
  -d '{
    "text_chunk": "The 1% Rule states that small improvements compound over time. If you get 1% better each day, you will be 37 times better after one year. This is the power of atomic habits - tiny changes that deliver remarkable results. The key is consistency over intensity. Most people overestimate what they can do in a day and underestimate what they can achieve in a year. Focus on systems, not goals. Goals are about the results you want to achieve. Systems are about the processes that lead to those results.",
    "mode": "chapter",
    "chapter_title": "The Power of Tiny Gains"
  }'
```

## API Reference

### POST /generateSummary

Transform book chapter text into structured learning slides.

**Request Body:**
```json
{
  "book_id": "optional-book-id",
  "chapter_title": "Optional Chapter Title",
  "text_chunk": "The chapter text to summarize (100-15000 chars)",
  "mode": "chapter|concept|law",
  "prev_context": "Optional previous chapter context",
  "next_context": "Optional next chapter context"
}
```

**Response:**
```json
{
  "unit_title": "Learning Unit Title",
  "blocks": [
    {
      "type": "core_idea|explanation|example|insight|takeaway|nuance|contrast|reflection|lyric_scroll",
      "text": "Block content",
      "lyric_lines": [],
      "image_hint": false
    }
  ],
  "visual_slots_used": 0,
  "cached": false,
  "notes": {
    "compression_applied": false,
    "long_chapter_handled": false,
    "context_used_only_for_continuity": true
  }
}
```

### GET /cache/stats

Returns cache hit/miss statistics.

### DELETE /cache

Clears all cached entries (debug only).

## Deploy to Cloud Run

### Prerequisites
- Google Cloud CLI installed
- Project with billing enabled
- Gemini API key

### Deploy

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Deploy (from backend directory)
gcloud run deploy flashbook-ai \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "GEMINI_API_KEY=your_key_here"
```

### After Deployment

1. Note the service URL (e.g., `https://flashbook-ai-xxxxx.run.app`)
2. Update your Flutter app to use this URL
3. Test: `curl https://your-service-url/health`

## Deploy to Firebase Functions (Alternative)

Create `functions/main.py`:

```python
from firebase_functions import https_fn
from main import app

@https_fn.on_request()
def flashbook_api(req: https_fn.Request) -> https_fn.Response:
    with app.request_context(req.environ):
        return app.full_dispatch_request()
```

Deploy:
```bash
firebase deploy --only functions
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GEMINI_API_KEY` | Yes | - | Google Gemini API key |
| `GEMINI_MODEL` | No | `gemini-2.5-flash` | Model to use |
| `MAX_CHUNK_LENGTH` | No | `15000` | Max input text length |
| `CACHE_TTL_SECONDS` | No | `86400` | Cache expiration (24h) |
| `DEBUG` | No | `false` | Enable debug mode |
| `PORT` | No | `8080` | Server port |

## Scaling Notes

**Current implementation (demo-ready):**
- In-memory cache (resets on restart)
- Single-instance suitable
- ~15k char input limit

**Future scaling (swap in when needed):**
- Replace `cache_service.py` with Redis/Firestore implementation
- Add rate limiting middleware
- Add authentication
- Queue long-running jobs

## License

MIT - Flashbook Hackathon Project
