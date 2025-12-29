"""
Configuration management for the Flashbook AI backend.
Loads environment variables and defines system limits.
"""

import os
from functools import lru_cache
from typing import Optional


class Settings:
    """Application settings loaded from environment variables."""
    
    # Gemini API
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "AIzaSyCiHQqbN0YGVyD2LDFK5SIsWDRzvtxb7Fc")
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
