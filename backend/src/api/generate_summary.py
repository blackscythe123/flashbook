"""
HTTP handler for the /generateSummary endpoint.
Orchestrates validation, caching, and AI generation.
"""

import logging
from fastapi import APIRouter, HTTPException, status

from ..core.schemas import (
    SummaryRequest,
    SummaryResponse,
    ErrorResponse,
    ContentBlock,
    GenerationNotes,
    BlockType,
)
from ..services.gemini_client import get_gemini_client
from ..services.cache_service import get_cache_service

logger = logging.getLogger(__name__)

router = APIRouter()


def _create_fallback_response(request: SummaryRequest, error_msg: str) -> SummaryResponse:
    """
    Create a safe fallback response when AI generation fails.
    Returns a minimal valid response so the app doesn't crash.
    """
    logger.warning(f"Creating fallback response due to: {error_msg}")
    
    # Extract a simple summary from the text
    text_preview = request.text_chunk[:300].strip()
    if len(request.text_chunk) > 300:
        text_preview += "..."
    
    return SummaryResponse(
        unit_title=request.chapter_title or "Chapter Summary",
        blocks=[
            ContentBlock(
                type=BlockType.CORE_IDEA,
                text=f"This chapter covers: {text_preview}",
                lyric_lines=[],
                image_hint=False
            ),
            ContentBlock(
                type=BlockType.INSIGHT,
                text="AI summary generation encountered an issue. Please try again or continue reading.",
                lyric_lines=[],
                image_hint=False
            ),
            ContentBlock(
                type=BlockType.TAKEAWAY,
                text="Consider reviewing the full chapter for complete understanding.",
                lyric_lines=[],
                image_hint=False
            )
        ],
        visual_slots_used=0,
        cached=False,
        notes=GenerationNotes(
            compression_applied=False,
            long_chapter_handled=False,
            context_used_only_for_continuity=True
        )
    )


@router.post(
    "/generateSummary",
    response_model=SummaryResponse,
    responses={
        200: {"description": "Summary generated successfully"},
        400: {"model": ErrorResponse, "description": "Invalid request"},
        500: {"model": ErrorResponse, "description": "Server error"},
    },
    summary="Generate structured chapter summary",
    description="""
    Transform a book chapter into 5-8 structured learning slides using AI.
    
    **Caching**: Responses are cached by content hash. Repeat requests return cached results.
    
    **Modes**:
    - `chapter`: Full chapter summary (default)
    - `concept`: Focus on core concept extraction
    - `law`: Extract and explain principles/laws
    
    **Context**: prev_context and next_context are used ONLY for continuity awareness.
    They are NOT included in the output summary.
    """
)
async def generate_summary(request: SummaryRequest) -> SummaryResponse:
    """
    Generate a structured summary from book chapter text.
    
    Flow:
    1. Validate request (handled by Pydantic)
    2. Check cache
    3. If cached → return cached response
    4. If not → call Gemini → parse → cache → return
    5. On failure → return safe fallback
    """
    
    cache = get_cache_service()
    gemini = get_gemini_client()
    
    # Log request info (without full text for privacy)
    logger.info(
        f"Summary request: mode={request.mode.value}, "
        f"book_id={request.book_id}, "
        f"chapter={request.chapter_title}, "
        f"text_len={len(request.text_chunk)}"
    )
    
    # Step 1: Check cache
    cached_response = cache.get(request)
    if cached_response is not None:
        logger.info("Returning cached response")
        return cached_response
    
    # Step 2: Generate with Gemini
    try:
        response = await gemini.generate_summary(request)
        
        # Validate response has enough blocks
        if len(response.blocks) < 3:
            logger.warning("Response has too few blocks, using fallback")
            response = _create_fallback_response(request, "Insufficient content generated")
        
        # Step 3: Cache the response
        cache.store(request, response)
        
        logger.info(f"Generated summary with {len(response.blocks)} blocks")
        return response
        
    except ValueError as e:
        # Parsing error - return fallback
        logger.error(f"AI response parsing error: {e}")
        return _create_fallback_response(request, str(e))
        
    except Exception as e:
        # API error - could be transient, return fallback
        logger.error(f"AI generation error: {e}")
        return _create_fallback_response(request, str(e))


@router.get(
    "/cache/stats",
    summary="Get cache statistics",
    description="Returns cache hit/miss statistics and current entry count."
)
async def get_cache_stats():
    """Get cache performance statistics."""
    cache = get_cache_service()
    return cache.get_stats()


@router.delete(
    "/cache",
    summary="Clear cache",
    description="Removes all cached entries. Use for debugging only."
)
async def clear_cache():
    """Clear all cached entries."""
    cache = get_cache_service()
    count = cache.clear()
    return {"cleared": count, "message": f"Cleared {count} cache entries"}
