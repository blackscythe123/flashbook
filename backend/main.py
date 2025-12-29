"""
Flashbook AI Backend
=====================

FastAPI server for generating structured book summaries using Google Gemini.

Entry point for local development and Cloud Run deployment.
"""

import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api import summary_router, extract_router
from src.core.config import get_settings

# ============================================================
# LOGGING SETUP
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)

logger = logging.getLogger(__name__)


# ============================================================
# APP LIFECYCLE
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    # Startup
    settings = get_settings()
    logger.info("=" * 50)
    logger.info("Flashbook AI Backend starting...")
    logger.info(f"Model: {settings.GEMINI_MODEL}")
    logger.info(f"Debug: {settings.DEBUG}")
    logger.info("=" * 50)
    
    # Validate config (will raise if API key missing)
    try:
        settings.validate()
        logger.info("Configuration validated successfully")
    except ValueError as e:
        logger.warning(f"Configuration warning: {e}")
        logger.warning("Server will start but AI features may not work")
    
    yield
    
    # Shutdown
    logger.info("Flashbook AI Backend shutting down...")


# ============================================================
# APP CREATION
# ============================================================

app = FastAPI(
    title="Flashbook AI Backend",
    description="""
    AI-powered book summary generation service for the Flashbook learning app.
    
    ## Features
    
    - **Chapter Summaries**: Transform book chapters into 5-8 structured learning slides
    - **Intelligent Caching**: Responses cached by content hash for efficiency
    - **Fallback Handling**: Graceful degradation if AI generation fails
    
    ## Usage
    
    Send a POST request to `/generateSummary` with your book chapter text.
    The response will contain structured content blocks ready for the mobile app.
    """,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)


# ============================================================
# MIDDLEWARE
# ============================================================

# CORS - allow Flutter app and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",
        "http://127.0.0.1:*",
        "https://*.web.app",  # Firebase hosting
        "https://*.firebaseapp.com",
        "*"  # For hackathon demo - restrict in production
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)


# ============================================================
# ERROR HANDLING
# ============================================================

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_error",
            "message": "An unexpected error occurred",
            "detail": str(exc) if get_settings().DEBUG else None
        }
    )


# ============================================================
# ROUTES
# ============================================================

# Health check
@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {
        "service": "flashbook-ai-backend",
        "status": "healthy",
        "version": "1.0.0"
    }


@app.get("/health", tags=["Health"])
async def health():
    """Detailed health check."""
    settings = get_settings()
    return {
        "status": "healthy",
        "model": settings.GEMINI_MODEL,
        "api_key_configured": bool(settings.GEMINI_API_KEY),
    }


# Summary generation routes
app.include_router(summary_router, tags=["Summary Generation"])
app.include_router(extract_router, tags=["Text Extraction"])


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    import uvicorn
    
    settings = get_settings()
    
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )
