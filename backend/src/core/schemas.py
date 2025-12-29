"""
Pydantic schemas for request/response validation.
Defines the API contract for the summary generation endpoint.
"""

from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


# ============================================================
# ENUMS
# ============================================================

class SummaryMode(str, Enum):
    """Available summary generation modes."""
    CHAPTER = "chapter"
    CONCEPT = "concept"
    LAW = "law"


class BlockType(str, Enum):
    """Types of content blocks in the output."""
    # Story-focused types
    SCENE = "scene"
    REVEAL = "reveal"
    EMOTION = "emotion"
    TENSION = "tension"
    INSIGHT = "insight"
    QUOTE = "quote"
    VISUAL = "visual"
    LYRIC_SCROLL = "lyric_scroll"
    # Legacy types (for backwards compatibility)
    CORE_IDEA = "core_idea"
    EXPLANATION = "explanation"
    EXAMPLE = "example"
    TAKEAWAY = "takeaway"
    NUANCE = "nuance"
    CONTRAST = "contrast"
    REFLECTION = "reflection"


# ============================================================
# REQUEST MODELS
# ============================================================

class SummaryRequest(BaseModel):
    """Request body for POST /generateSummary."""
    
    book_id: Optional[str] = Field(
        default=None,
        description="Optional book identifier for caching"
    )
    chapter_title: Optional[str] = Field(
        default=None,
        max_length=200,
        description="Optional chapter title for context"
    )
    text_chunk: str = Field(
        ...,
        min_length=100,
        max_length=15000,
        description="The chapter text to summarize (100-15000 chars)"
    )
    mode: SummaryMode = Field(
        default=SummaryMode.CHAPTER,
        description="Summary generation mode"
    )
    prev_context: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Optional previous chapter context for continuity"
    )
    next_context: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="Optional next chapter context for continuity"
    )
    
    @field_validator('text_chunk')
    @classmethod
    def validate_text_chunk(cls, v: str) -> str:
        """Ensure text chunk is not just whitespace."""
        stripped = v.strip()
        if len(stripped) < 100:
            raise ValueError("text_chunk must contain at least 100 meaningful characters")
        return stripped


# ============================================================
# RESPONSE MODELS
# ============================================================

class ContentBlock(BaseModel):
    """A single content block in the summary output."""
    
    type: BlockType = Field(
        ...,
        description="The semantic type of this block"
    )
    slide_title: str = Field(
        default="",
        max_length=30,
        description="1-2 word slide title (e.g., 'PLOT TWIST', 'INNER CONFLICT')"
    )
    headline: str = Field(
        default="",
        max_length=100,
        description="Short punchy headline (5-10 words)"
    )
    body: str = Field(
        default="",
        description="Main narrative content of the block"
    )
    text: str = Field(
        default="",
        description="Legacy field - use body instead"
    )
    lyric_lines: List[str] = Field(
        default_factory=list,
        description="Flowing text lines for lyric_scroll blocks"
    )
    image_hint: bool = Field(
        default=False,
        description="Whether this block should have an illustration"
    )
    image_prompt: str = Field(
        default="",
        max_length=500,
        description="Detailed prompt for image generation if image_hint is true"
    )


class GenerationNotes(BaseModel):
    """Metadata about the generation process."""
    
    compression_applied: bool = Field(
        default=False,
        description="Whether the chapter was compressed to fit limits"
    )
    long_chapter_handled: bool = Field(
        default=False,
        description="Whether special handling was applied for long content"
    )
    context_used_only_for_continuity: bool = Field(
        default=True,
        description="Confirms context was not included in output"
    )


class SummaryResponse(BaseModel):
    """Response body for POST /generateSummary."""
    
    unit_title: str = Field(
        ...,
        description="Title for this learning unit"
    )
    blocks: List[ContentBlock] = Field(
        ...,
        min_length=1,
        max_length=8,
        description="5-8 structured content blocks"
    )
    visual_slots_used: int = Field(
        default=0,
        ge=0,
        le=2,
        description="Number of image hints (0-2)"
    )
    cached: bool = Field(
        default=False,
        description="Whether this response was served from cache"
    )
    notes: GenerationNotes = Field(
        default_factory=GenerationNotes,
        description="Generation metadata"
    )


class ErrorResponse(BaseModel):
    """Standard error response."""
    
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Human-readable error message")
    detail: Optional[str] = Field(default=None, description="Additional details")


# ============================================================
# INTERNAL MODELS (for Gemini parsing)
# ============================================================

class GeminiOutputBlock(BaseModel):
    """Schema for parsing Gemini's raw block output."""
    type: str
    slide_title: str = ""
    headline: str = ""
    body: str = ""
    text: str = ""  # Legacy field
    lyric_lines: List[str] = []
    image_hint: bool = False
    image_prompt: str = ""


class GeminiOutput(BaseModel):
    """Schema for parsing Gemini's full response."""
    unit_title: str
    blocks: List[GeminiOutputBlock]
    visual_slots_used: int = 0
    notes: dict = {}
