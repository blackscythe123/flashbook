"""
Image generation service using various APIs.
Primary: Gemini 2.5 Flash Image (Nano Banana)
Fallback: Pollinations.ai (free, AI-generated)
Fallback: Picsum (placeholder images)
"""

import logging
import asyncio
import time
import urllib.parse
import hashlib
import os
from typing import Optional
from pathlib import Path
import uuid
import base64

# Configure basic logging for direct testing
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)

# Try importing Google Gen AI SDK
try:
    from google import genai
    from google.genai import types
    HAS_GEMINI = True
except ImportError:
    HAS_GEMINI = False
    logger.warning("google-genai package not installed. Gemini generation disabled.")

class ImageGenerationService:
    """
    Service for generating images from prompts.
    Primary: Gemini 2.5 Flash Image ("Nano Banana")
    Secondary: Pollinations.ai (AI-generated)
    Fallback: Picsum (placeholder images)
    """
    
    POLLINATIONS_URL = "https://image.pollinations.ai/prompt"
    PICSUM_URL = "https://picsum.photos"
    
    # Rate limiting for Gemini
    _last_gemini_call: float = 0
    _gemini_min_interval: float = 5  # "Flash" models are faster, reduced wait time
    
    def __init__(self):
        self._genai_client = None
        self._images_dir: Optional[Path] = None
        self._setup_images_dir()
        
        if HAS_GEMINI:
            api_key = os.getenv("GEMINI_API_KEY")
            if api_key:
                try:
                    self._genai_client = genai.Client(api_key=api_key)
                    logger.info("Gemini Image Client initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize Gemini Image Client: {e}")
            else:
                logger.warning("GEMINI_API_KEY not found in environment variables.")
    
    def _setup_images_dir(self):
        """Create directory for storing generated images."""
        try:
            # Robust way to find the 'static' folder relative to the project root
            base_dir = Path(os.getcwd())
            
            # Check common locations for static/images
            candidates = [
                base_dir / "backend" / "static" / "images",
                base_dir / "static" / "images",
                base_dir / "images"
            ]
            
            for path in candidates:
                if path.parent.parent.exists(): 
                    self._images_dir = path
                    break
            
            # Fallback if structure is unknown
            if not self._images_dir:
                self._images_dir = base_dir / "static" / "images"

            self._images_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Images directory set to: {self._images_dir}")
        except Exception as e:
            logger.error(f"Failed to create images directory: {e}")
            self._images_dir = Path("/tmp/gen_images")
            self._images_dir.mkdir(parents=True, exist_ok=True)
    
    async def _wait_for_gemini_rate_limit(self):
        """Wait if needed to respect Gemini rate limits."""
        now = time.time()
        elapsed = now - self._last_gemini_call
        if elapsed < self._gemini_min_interval:
            wait_time = self._gemini_min_interval - elapsed
            await asyncio.sleep(wait_time)
        self._last_gemini_call = time.time()
    
    def _get_seed_from_prompt(self, prompt: str) -> int:
        return int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 1000000

    async def generate_gemini_image(
        self,
        prompt: str,
        style: str = "anime",
        book_title: str = "",
        character_context: str = ""
    ) -> Optional[str]:
        """
        Generate an image using Gemini 2.5 Flash Image ("Nano Banana").
        """
        if not self._genai_client:
            return None

        try:
            await self._wait_for_gemini_rate_limit()
            
            # Contextual Prompt
            enhanced_prompt = f"Create a high quality {style} style illustration. {prompt}"
            if character_context:
                enhanced_prompt += f" Characters: {character_context}"
            if book_title:
                enhanced_prompt += f" Context: {book_title}"
            aspect_ratio = "16:9" # "1:1","2:3","3:2","3:4","4:3","4:5","5:4","9:16","16:9","21:9"
            resolution = "1K" # "1K", "2K", "4K"    
            enhanced_prompt = enhanced_prompt[:450]
            logger.info(f"Attempting Gemini (Nano Banana) generation: {enhanced_prompt[:50]}...")
            
            # --- CHANGED: Using generate_content for Gemini 2.5 Flash Image ---
            # Run blocking call in a separate thread to avoid blocking the event loop
            response = await asyncio.to_thread(
                self._genai_client.models.generate_content,
                model=os.getenv("GEMINI_MODEL_Image"), # or 'gemini-2.5-flash-image' if available in your region
                contents=enhanced_prompt,
                # config=types.GenerateContentConfig(
                #     response_modalities=['IMAGE'],
                #     image_config=types.ImageConfig(
                #         aspect_ratio=aspect_ratio,
                #         image_size=resolution
                #     ),
                # )
            )

            # Handle response (Nano Banana returns inline_data, not generated_images)
            image_data = None
            
            # Check for inline data in parts
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if part.inline_data:
                        image_data = part.inline_data.data
                        break
            
            # Fallback check (sometimes it wraps differently)
            if not image_data and hasattr(response, 'text') and not response.text:
                 # If text is empty, check raw parts if available
                 pass

            if image_data:
                # Decode if it's base64 string, otherwise it's bytes
                if isinstance(image_data, str):
                    image_bytes = base64.b64decode(image_data)
                else:
                    image_bytes = image_data

                # Return Data URI for direct frontend usage (Zero RTT)
                b64_str = base64.b64encode(image_bytes).decode('utf-8')
                return f"data:image/png;base64,{b64_str}"
            
            logger.warning("Gemini response contained no image data.")
            return None

        except Exception as e:
            logger.error(f"Gemini image generation failed: {e}")
            return None
    
    def generate_pollinations_url(
        self,
        prompt: str,
        width: int = 512,
        height: int = 768,
        style: str = "anime",
        book_title: str = "",
    ) -> str:
        clean_prompt = prompt.replace("'", "").replace('"', "").replace('\n', ' ')[:300]
        style_suffix = f"{style} style illustration high quality"
        final_prompt = f"{clean_prompt} {style_suffix}"
        if book_title:
            final_prompt += f" ({book_title})"
            
        seed = self._get_seed_from_prompt(prompt)
        encoded_prompt = urllib.parse.quote(final_prompt)
        return f"{self.POLLINATIONS_URL}/{encoded_prompt}?width={width}&height={height}&seed={seed}&nologo=true&model=flux"
    
    def generate_picsum_url(self, prompt: str, width: int = 512, height: int = 768) -> str:
        seed = self._get_seed_from_prompt(prompt)
        return f"{self.PICSUM_URL}/seed/{seed}/{width}/{height}"
    
    async def generate_image_url(
        self,
        prompt: str,
        width: int = 512,
        height: int = 768,
        style: str = "anime",
        book_title: str = "",
        character_context: str = ""
    ) -> str:
        # 1. Try Gemini (Nano Banana)
        if self._genai_client:
            gemini_url = await self.generate_gemini_image(
                prompt, style=style, book_title=book_title, character_context=character_context
            )
            if gemini_url:
                return gemini_url

        # 2. Fallback to Pollinations
        try:
            url = self.generate_pollinations_url(prompt, width, height, style, book_title)
            logger.info(f"Using Pollinations URL: {url[:50]}...")
            return url
        except Exception as e:
            logger.error(f"Pollinations generation failed: {e}")
            
        # 3. Last resort
        return self.generate_picsum_url(prompt, width, height)

# Singleton logic
_service: Optional[ImageGenerationService] = None

def get_image_service() -> ImageGenerationService:
    global _service
    if _service is None:
        _service = ImageGenerationService()
    return _service

if __name__ == "__main__":
    from dotenv import load_dotenv
    # Find .env
    env_path = Path(__file__).resolve().parent.parent.parent.parent / '.env'
    if not env_path.exists():
         env_path = Path(__file__).resolve().parent.parent.parent / '.env'
    load_dotenv(env_path)
    
    async def test_service():
        print("--- Starting Image Service Test ---")
        svc = get_image_service()
        prompt = "A futuristic cyberpunk detective standing in rain"
        
        print(f"\nGenerating image for prompt: '{prompt}'")
        url = await svc.generate_image_url(prompt)
        
        print(f"\nResult URL: {url}")
        if "/static/" in url:
            print("SUCCESS: Generated using Gemini.")
        else:
            print("FALLBACK: Generated using Pollinations.")

    asyncio.run(test_service())