"""
Image generation service using various APIs.
Primary: Pollinations.ai (free, AI-generated)
Fallback: Unsplash Source (placeholder images)
"""

import logging
import asyncio
import base64
import time
import urllib.parse
import hashlib
from typing import Optional
from pathlib import Path
import uuid

logger = logging.getLogger(__name__)


class ImageGenerationService:
    """
    Service for generating images from prompts.
    Primary: Pollinations.ai (AI-generated)
    Fallback: Unsplash/Picsum (placeholder images)
    """
    
    POLLINATIONS_URL = "https://image.pollinations.ai/prompt"
    PICSUM_URL = "https://picsum.photos"
    
    # Rate limiting for Gemini (2 RPM for imagen)
    _last_gemini_call: float = 0
    _gemini_min_interval: float = 35  # seconds between calls (safe margin)
    
    def __init__(self):
        self._genai_client = None
        self._images_dir: Optional[Path] = None
        self._setup_images_dir()
    
    def _setup_images_dir(self):
        """Create directory for storing generated images."""
        try:
            # Store in backend/static/images
            backend_dir = Path(__file__).parent.parent.parent
            self._images_dir = backend_dir / "static" / "images"
            self._images_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Images directory: {self._images_dir}")
        except Exception as e:
            logger.error(f"Failed to create images directory: {e}")
    
    async def _wait_for_gemini_rate_limit(self):
        """Wait if needed to respect Gemini rate limits."""
        now = time.time()
        elapsed = now - self._last_gemini_call
        if elapsed < self._gemini_min_interval:
            wait_time = self._gemini_min_interval - elapsed
            logger.info(f"Rate limiting: waiting {wait_time:.1f}s")
            await asyncio.sleep(wait_time)
        self._last_gemini_call = time.time()
    
    def _get_seed_from_prompt(self, prompt: str) -> int:
        """Generate a consistent seed from prompt for reproducible images."""
        return int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 1000000
    
    def generate_pollinations_url(
        self,
        prompt: str,
        width: int = 512,
        height: int = 768,
        style: str = "anime",
        book_title: str = "",
        character_context: str = ""
    ) -> str:
        """
        Generate a Pollinations.ai URL for the image.
        Image is generated on-demand when URL is accessed.
        """
        # Clean and simplify the prompt
        clean_prompt = prompt.replace("'", "").replace('"', "").replace('\n', ' ')
        clean_prompt = ' '.join(clean_prompt.split())
        
        # Truncate if too long
        if len(clean_prompt) > 200:
            clean_prompt = clean_prompt[:200]
        
        # Build context
        parts = []
        if book_title:
            clean_title = book_title.replace("'", "").replace('"', "")[:50]
            parts.append(clean_title)
        
        # Simple, clean prompt for better results
        style_suffix = "anime style illustration high quality"
        
        if parts:
            final_prompt = f"{clean_prompt} {' '.join(parts)} {style_suffix}"
        else:
            final_prompt = f"{clean_prompt} {style_suffix}"
        
        # Use seed for consistent images
        seed = self._get_seed_from_prompt(prompt)
        
        encoded_prompt = urllib.parse.quote(final_prompt, safe='')
        url = f"{self.POLLINATIONS_URL}/{encoded_prompt}?width={width}&height={height}&seed={seed}&nologo=true"
        return url
    
    def generate_picsum_url(self, prompt: str, width: int = 512, height: int = 768) -> str:
        """
        Generate a Picsum placeholder image URL.
        Uses prompt hash as seed for consistent images.
        """
        seed = self._get_seed_from_prompt(prompt)
        # Picsum provides random images, seed ensures consistency
        url = f"{self.PICSUM_URL}/seed/{seed}/{width}/{height}"
        return url
    
    def generate_image_url(
        self,
        prompt: str,
        width: int = 512,
        height: int = 768,
        seed: Optional[int] = None,
        style: str = "anime",
        book_title: str = "",
        character_context: str = ""
    ) -> str:
        """
        Generate an image URL from a prompt.
        Primary: Pollinations.ai (AI-generated)
        Fallback: Picsum (reliable placeholder)
        
        Args:
            prompt: The image description
            width: Image width
            height: Image height
            seed: Random seed
            style: Style hint
            book_title: Title of the book for context
            character_context: Character names and details
            
        Returns:
            URL string for the image
        """
        # Use Pollinations for AI-generated images
        url = self.generate_pollinations_url(prompt, width, height, style, book_title, character_context)
        logger.info(f"Generated Pollinations URL for: {prompt[:50]}...")
        return url
    
    def generate_fallback_url(
        self,
        prompt: str,
        width: int = 512,
        height: int = 768,
    ) -> str:
        """
        Generate a fallback image URL using Picsum.
        Used when Pollinations is unavailable.
        """
        url = self.generate_picsum_url(prompt, width, height)
        logger.info(f"Generated Picsum fallback URL for: {prompt[:50]}...")
        return url


# Singleton instance
_service: Optional[ImageGenerationService] = None


def get_image_service() -> ImageGenerationService:
    """Get the singleton image generation service instance."""
    global _service
    if _service is None:
        _service = ImageGenerationService()
    return _service
