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

### GET /recommend/{book_index}

Returns similar books from a small dummy content dataset using TF-IDF + cosine similarity.

**Path Parameter:**
- `book_index`: index of the base book in the dummy dataset (`0` to `9`)

**Query Parameter:**
- `top_k` (optional): number of recommendations to return (`1` to `10`, default `3`)

**Response (example):**
```json
{
  "book_index": 0,
  "recommendations": [
    "FastAPI Backend Development",
    "Machine Learning Foundations",
    "Data Engineering Pipelines"
  ],
  "details": [
    {"index": 5, "title": "FastAPI Backend Development", "score": 0.15}
  ]
}
```

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

## ML Recommendation System

This backend now includes a simple, modular content-based recommendation pipeline in `backend/ml/`.

### What it does

- Uses a structured dataset file (`data/books.csv`) with book title + description.
- Converts content to TF-IDF vectors (`ml/recommendation.py`).
- Computes cosine similarity and returns top similar books.

### Files

- `data/books.csv`: structured recommendation dataset (10 entries)
- `ml/data.py`: CSV loader with fallback dataset
- `ml/recommendation.py`: recommendation and scoring utilities
- `ml/mlflow_experiments.py`: experiment tracking for parameter grid
- `ml/optuna_tuning.py`: Optuna-based hyperparameter tuning

### Run Recommendation API

```bash
cd backend
python main.py
```

Open:

- `http://localhost:8080/docs`
- `GET /recommend/{book_index}`

### Run MLflow Experiments

```bash
cd backend
python -m ml.mlflow_experiments
mlflow ui --port 5000
```

Then open `http://localhost:5000` to inspect runs under experiment `flashbook-recommendation`.

### Run Optuna Tuning

```bash
cd backend
python -m ml.optuna_tuning
```

Expected output includes:

- best parameters (`max_features`, `ngram_range`)
- best average cosine similarity score

## Detailed Implementation Log (MLflow + Optuna)

This section summarizes the full implementation done in this repository for assignment documentation.

### 1. Problem Framing

We implemented a **content-based recommendation system** (not a supervised classifier/regressor).

- Input: book metadata text (title + description/content)
- Representation: TF-IDF vectors
- Ranking logic: cosine similarity
- Output: top-k most similar books

This is valid applied ML for recommendation where labels are unavailable.

### 2. Dataset Design

A structured mini dataset was formalized in:

- `backend/data/books.csv`

Schema:

- `id`
- `title`
- `description`

Why this matters:

- Improves viva clarity when asked, "what data was used?"
- Converts informal hardcoded examples into a reusable, auditable dataset
- Aligns with user-content style recommendation workflows

### 3. Data Loader Layer

Implemented in:

- `backend/ml/data.py`

Responsibilities:

- Loads records from `data/books.csv`
- Maps `title + description` into recommendation-ready fields (`title`, `content`)
- Provides fallback dataset if CSV is missing (keeps demo robust)

### 4. Recommendation Engine

Implemented in:

- `backend/ml/recommendation.py`

Functions:

- `build_similarity_matrix(max_features, ngram_range)`
  - TF-IDF vectorization using scikit-learn
  - cosine similarity matrix generation
- `average_cosine_similarity(max_features, ngram_range)`
  - simple scalar metric for experiment comparison
- `get_recommendations(book_index, top_k)`
  - returns top similar titles with scores

### 5. API Integration

Implemented in:

- `backend/src/api/recommendations.py`
- `backend/src/api/__init__.py`
- `backend/main.py`

Route:

- `GET /recommend/{book_index}`

Response includes:

- recommended titles
- detailed list with score and index

### 6. MLflow Experiment Tracking

Implemented in:

- `backend/ml/mlflow_experiments.py`

Tracked experiment:

- `flashbook-recommendation`

Grid:

- `max_features`: 20, 50, 100
- `ngram_range`: (1,1), (1,2)

Logged each run:

- Parameters: `max_features`, `ngram_range`
- Metric: `average_cosine_similarity`

Important reliability fix:

- Explicit tracking URI now points to `backend/mlruns` so runs are always written/read from one location.
- This prevents empty-dashboard confusion caused by multiple `mlruns` directories.

Recommended dashboard command:

```bash
mlflow ui --host 127.0.0.1 --port 5000 --backend-store-uri file:///C:/Desktop/Folders/College/SEM-4/flashbook/backend/mlruns
```

### 7. Optuna Hyperparameter Optimization

Implemented in:

- `backend/ml/optuna_tuning.py`

Objective:

- maximize `average_cosine_similarity`

Search space:

- `max_features`: 10 to 200
- `ngram_range`: 1 or 2 (implemented as `(1, ngram_range)`)

Result output:

- best parameter set
- best score

### 8. Optuna Visualization Support

Dependency added:

- `plotly`

Why:

- `optuna.visualization.plot_optimization_history(study)` requires Plotly.

Generated artifact (runtime output, not source):

- `backend/optuna_optimization_history.html`

### 9. Dependency Updates

Updated in:

- `backend/requirements.txt`

Added:

- `scikit-learn`
- `mlflow`
- `optuna`
- `plotly`

### 10. Repository Hygiene for Experiments

Updated ignore rules:

- `.gitignore`
- `backend/.gitignore`

Ignored generated artifacts:

- `mlruns/`
- `backend/mlruns/`
- `backend/optuna_optimization_history.html`

Reason:

- keep version control clean and store only reproducible source/config files

### 11. Validation Checklist

Validated during implementation:

- Dependency installation from `requirements.txt`
- MLflow script execution and run logging
- MLflow API-based run count verification
- Optuna tuning execution and best result print
- Recommendation function output (`get_recommendations(0)`)
- FastAPI route response for `/recommend/{book_index}`

### 12. Suggested Documentation Tables

For assignment report, include:

1. MLflow run comparison table
   - columns: `max_features`, `ngram_range`, `average_cosine_similarity`
2. Baseline vs optimized table
   - baseline: fixed TF-IDF setting
   - optimized: Optuna best setting

### 13. Viva-Safe Positioning

Use this framing:

- Dataset: structured metadata dataset (`books.csv`), representing user/content corpus
- Model: TF-IDF + cosine similarity (content-based recommendation)
- MLflow: experiment tracking for vectorizer configuration impact
- Optuna: hyperparameter optimization for recommendation quality metric

## License

MIT - Flashbook Hackathon Project
