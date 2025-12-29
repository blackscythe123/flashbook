"""
Configuration management for the Flashbook AI backend.
Loads environment variables and defines system limits.
"""

import os
from pathlib import Path
from functools import lru_cache
from typing import Optional

# Load .env file from backend directory
try:
    from dotenv import load_dotenv
    # Find the backend directory (where .env is located)
    backend_dir = Path(__file__).parent.parent.parent
    env_path = backend_dir / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        print(f"Loaded .env from: {env_path}")
    else:
        print(f".env not found at: {env_path}")
except ImportError:
    print("python-dotenv not installed, using system environment variables only")


class Settings:
    """Application settings loaded from environment variables."""
    
    # Gemini API
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    
    # Text limits (characters)
    MIN_CHUNK_LENGTH: int = int(os.getenv("MIN_CHUNK_LENGTH", "100"))
    MAX_CHUNK_LENGTH: int = int(os.getenv("MAX_CHUNK_LENGTH", "15000"))
    MAX_CONTEXT_LENGTH: int = int(os.getenv("MAX_CONTEXT_LENGTH", "2000"))
    
    # AI generation limits
    MAX_SLIDES: int = 8
    MIN_SLIDES: int = 5
    MAX_VISUAL_SLOTS: int = 2
    
    # Cache settings
    CACHE_TTL_SECONDS: int = int(os.getenv("CACHE_TTL_SECONDS", "86400"))  # 24 hours
    
    # Server settings
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8080"))
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    
    def validate(self) -> None:
        """Validate required configuration."""
        if not self.GEMINI_API_KEY:
            raise ValueError("GEMINI_API_KEY environment variable is required")


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
