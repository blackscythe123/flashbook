"""
Gemini API client wrapper.
Handles all AI interactions with structured prompts and response parsing.
"""

import json
import logging
from typing import Optional

import google.generativeai as genai
from google.generativeai.types import GenerationConfig

from ..core.config import get_settings
from ..core.schemas import (
    SummaryRequest,
    SummaryResponse,
    ContentBlock,
    GenerationNotes,
    BlockType,
    GeminiOutput,
)

logger = logging.getLogger(__name__)


# ============================================================
# SYSTEM PROMPT - The core instruction set for Gemini
# ============================================================

SYSTEM_PROMPT = """You are a learning content architect. Your task is to transform book chapter text into structured learning slides for an educational app.

STRICT RULES:
1. Generate ONLY from the TARGET CHAPTER TEXT provided
2. prev_context and next_context are for continuity awareness ONLY - NEVER summarize or reference them in output
3. Output MUST be valid JSON matching the exact schema provided
4. Generate 5-8 slides maximum, following the ordered structure

SLIDE STRUCTURE (in this order):
1. core_idea - The central concept of the chapter
2. explanation - Clear breakdown of the idea
3. example - Concrete illustration or case study
4. insight - A deeper observation or implication
5. takeaway - Actionable summary for the reader

OPTIONAL (still max 8 total):
6. nuance - Important caveats or edge cases
7. contrast - Compare with alternative views
8. reflection - Thought-provoking question

FORMATTING RULES:
- Keep each slide concise (2-4 sentences max)
- If text is too long for one slide, use "lyric_scroll" type with lyric_lines array
- Maximum 2 image_hint markers per chapter
- Set image_hint=true only for highly visual concepts

OUTPUT FORMAT (strict JSON):
{
  "unit_title": "A compelling title for this learning unit",
  "blocks": [
    {
      "type": "core_idea|explanation|example|insight|takeaway|nuance|contrast|reflection|lyric_scroll",
      "text": "Main content (empty string for lyric_scroll)",
      "lyric_lines": ["line1", "line2"],
      "image_hint": false
    }
  ],
  "visual_slots_used": 0,
  "notes": {
    "compression_applied": false,
    "long_chapter_handled": false
  }
}

RESPOND ONLY WITH VALID JSON. NO MARKDOWN, NO EXPLANATIONS."""


def _build_user_prompt(request: SummaryRequest) -> str:
    """Build the user prompt from the request."""
    
    parts = []
    
    # Mode instruction
    mode_instructions = {
        "chapter": "Summarize this chapter as a learning unit.",
        "concept": "Extract and explain the core concept from this text.",
        "law": "Identify and break down the principle/law presented in this text."
    }
    parts.append(f"MODE: {mode_instructions.get(request.mode.value, mode_instructions['chapter'])}")
    
    # Context (for continuity only)
    if request.prev_context:
        parts.append(f"\n[PREV_CONTEXT - for continuity awareness only, do NOT summarize]:\n{request.prev_context[:500]}...")
    
    if request.next_context:
        parts.append(f"\n[NEXT_CONTEXT - for continuity awareness only, do NOT summarize]:\n{request.next_context[:500]}...")
    
    # Chapter title if provided
    if request.chapter_title:
        parts.append(f"\nCHAPTER TITLE: {request.chapter_title}")
    
    # The main content
    parts.append(f"\n---TARGET CHAPTER TEXT (summarize ONLY this)---\n{request.text_chunk}\n---END OF TARGET CHAPTER---")
    
    parts.append("\nGenerate the structured JSON output now:")
    
    return "\n".join(parts)


def _parse_gemini_response(raw_response: str, request: SummaryRequest) -> SummaryResponse:
    """
    Parse and validate Gemini's response into our schema.
    Applies fallback handling for malformed responses.
    """
    
    # Clean up potential markdown wrapping
    cleaned = raw_response.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    if cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()
    
    try:
        data = json.loads(cleaned)
        parsed = GeminiOutput(**data)
        
        # Convert to response schema
        blocks = []
        visual_count = 0
        
        for block in parsed.blocks[:8]:  # Enforce max 8
            # Validate block type
            try:
                block_type = BlockType(block.type)
            except ValueError:
                block_type = BlockType.INSIGHT  # Safe fallback
            
            # Count visual hints
            if block.image_hint and visual_count < 2:
                visual_count += 1
                image_hint = True
            else:
                image_hint = False
            
            blocks.append(ContentBlock(
                type=block_type,
                text=block.text or "",
                lyric_lines=block.lyric_lines or [],
                image_hint=image_hint
            ))
        
        # Ensure minimum slides
        if len(blocks) < 5:
            logger.warning(f"Gemini returned only {len(blocks)} blocks, padding required")
        
        notes = GenerationNotes(
            compression_applied=parsed.notes.get("compression_applied", False),
            long_chapter_handled=parsed.notes.get("long_chapter_handled", False),
            context_used_only_for_continuity=True
        )
        
        return SummaryResponse(
            unit_title=parsed.unit_title or request.chapter_title or "Learning Unit",
            blocks=blocks,
            visual_slots_used=visual_count,
            cached=False,
            notes=notes
        )
        
    except (json.JSONDecodeError, Exception) as e:
        logger.error(f"Failed to parse Gemini response: {e}")
        logger.debug(f"Raw response: {raw_response[:500]}...")
        raise ValueError(f"AI response parsing failed: {str(e)}")


class GeminiClient:
    """
    Wrapper for Google Gemini API.
    Handles prompt construction, API calls, and response parsing.
    """
    
    def __init__(self):
        self.settings = get_settings()
        self._initialized = False
        self._model = None
    
    def _ensure_initialized(self) -> None:
        """Lazy initialization of the Gemini client."""
        if self._initialized:
            return
        
        if not self.settings.GEMINI_API_KEY:
            raise ValueError("GEMINI_API_KEY not configured")
        
        genai.configure(api_key=self.settings.GEMINI_API_KEY)
        
        self._model = genai.GenerativeModel(
            model_name=self.settings.GEMINI_MODEL,
            system_instruction=SYSTEM_PROMPT,
            generation_config=GenerationConfig(
                temperature=0.7,
                top_p=0.9,
                max_output_tokens=4096,
                response_mime_type="application/json"
            )
        )
        
        self._initialized = True
        logger.info(f"Gemini client initialized with model: {self.settings.GEMINI_MODEL}")
    
    async def generate_summary(self, request: SummaryRequest) -> SummaryResponse:
        """
        Generate a structured summary from the request.
        
        Args:
            request: Validated SummaryRequest
            
        Returns:
            SummaryResponse with structured content blocks
            
        Raises:
            ValueError: If response parsing fails
            Exception: If API call fails
        """
        self._ensure_initialized()
        
        user_prompt = _build_user_prompt(request)
        
        logger.info(f"Generating summary for chunk of {len(request.text_chunk)} chars")
        
        try:
            # Call Gemini API
            response = await self._model.generate_content_async(user_prompt)
            
            if not response.text:
                raise ValueError("Empty response from Gemini")
            
            # Parse and validate response
            return _parse_gemini_response(response.text, request)
            
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise
    
    def generate_summary_sync(self, request: SummaryRequest) -> SummaryResponse:
        """Synchronous version for simpler use cases."""
        self._ensure_initialized()
        
        user_prompt = _build_user_prompt(request)
        
        logger.info(f"Generating summary (sync) for chunk of {len(request.text_chunk)} chars")
        
        try:
            response = self._model.generate_content(user_prompt)
            
            if not response.text:
                raise ValueError("Empty response from Gemini")
            
            return _parse_gemini_response(response.text, request)
            
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise


# Singleton instance
_client: Optional[GeminiClient] = None


def get_gemini_client() -> GeminiClient:
    """Get the singleton Gemini client instance."""
    global _client
    if _client is None:
        _client = GeminiClient()
    return _client
