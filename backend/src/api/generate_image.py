"""
HTTP handler for the /generateImage endpoint.
Generates image URLs from text prompts for story visualization.
"""

import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional

from ..services.image_service import get_image_service

logger = logging.getLogger(__name__)

router = APIRouter()


class ImageRequest(BaseModel):
    """Request body for POST /generateImage."""
    prompt: str = Field(
        ...,
        min_length=10,
        max_length=500,
        description="Image description prompt"
    )
    width: int = Field(default=512, ge=256, le=1024)
    height: int = Field(default=768, ge=256, le=1024)
    style: str = Field(default="anime", description="Art style hint")
    seed: Optional[int] = Field(default=None, description="Random seed for reproducibility")
    book_title: str = Field(default="", description="Title of the book for context")
    character_context: str = Field(default="", description="Character names and details")


class ImageResponse(BaseModel):
    """Response body for POST /generateImage."""
    image_url: str = Field(..., description="URL to the generated image")
    prompt: str = Field(..., description="The prompt used")


@router.post(
    "/generateImage",
    response_model=ImageResponse,
    summary="Generate an image from a prompt",
    description="Returns a URL that generates an image. Uses Gemini (Imagen 3) if available, with Pollinations.ai fallback."
)
async def generate_image(request: ImageRequest) -> ImageResponse:
    """
    Generate an image URL from a text prompt.
    
    Primary: Gemini (Imagen 3) - Returns a local URL to the generated image.
    Fallback: Pollinations.ai - Returns a dynamic URL that generates on access.
    """
    try:
        service = get_image_service()
        
        image_url = await service.generate_image_url(
            prompt=request.prompt,
            width=request.width,
            height=request.height,
            style=request.style,
            seed=request.seed,
            book_title=request.book_title,
            character_context=request.character_context
        )
        
        return ImageResponse(
            image_url=image_url,
            prompt=request.prompt
        )
        
    except Exception as e:
        logger.error(f"Image generation error: {e}")
        raise HTTPException(status_code=500, detail=f"Image generation failed: {str(e)}")
