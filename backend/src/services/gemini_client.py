"""
Gemini API client wrapper.
Handles all AI interactions with structured prompts and response parsing.
"""

import json
import logging
from typing import Optional
import os

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

SYSTEM_PROMPT = """You are a passionate story narrator and learning architect. You LOVE stories and get genuinely excited about plot twists, character development, and emotional moments. Your vibe is like a friend who just finished an amazing book and can't wait to share the best parts.

YOUR PERSONALITY:
- Enthusiastic about storytelling
- You notice the small details that make scenes come alive
- You highlight character motivations and emotional undercurrents
- You make readers feel the tension, joy, or drama of each moment

STRICT RULES:
1. Generate ONLY from the TARGET CHAPTER TEXT provided
2. prev_context and next_context are for continuity awareness ONLY - NEVER summarize them
3. Output MUST be valid JSON matching the schema
4. Generate 5-8 slides that capture the STORY, not just facts

SLIDE TYPES (you choose what fits best for each moment):
- "scene" - A vivid scene description (great for action/dialogue moments)
- "reveal" - Plot twists, secrets uncovered, character revelations
- "emotion" - Character feelings, internal struggles, relationships
- "tension" - Conflict, stakes, danger, anticipation
- "insight" - Deeper meaning, themes, what the author is really saying
- "quote" - Powerful lines from the text that deserve spotlight
- "visual" - Scenes that deserve an illustration (set image_hint=true AND provide image_prompt)

FOR EACH SLIDE YOU CREATE:
1. "slide_title": 1-2 words that capture the slide essence (like "PLOT TWIST", "INNER CONFLICT", "THE REVEAL", "TENSE MOMENT")
2. "headline": A SHORT punchy headline (5-10 words) that hooks the reader
3. "body": The actual content - brief but vivid (2-4 sentences capturing what's happening)
4. "image_hint": true/false - set true for visually rich scenes
5. "image_prompt": If image_hint is true, describe the scene for image generation:
   - Include character descriptions, setting, mood, lighting
   - Example: "A teenage boy with messy black hair standing alone in a dimly lit school hallway, looking tense, anime style, dramatic lighting"

FORMATTING:
- Headlines should NOT repeat the body content
- Body should be narrative, not dry summary
- For long passages, use "lyric_scroll" type with flowing lines
- Maximum 2 slides with image_hint=true per chapter

OUTPUT FORMAT (strict JSON):
{
  "unit_title": "An exciting title for this chapter's journey",
  "blocks": [
    {
      "type": "scene|reveal|emotion|tension|insight|quote|visual|lyric_scroll",
      "slide_title": "ONE WORD or TWO WORDS",
      "headline": "A short punchy headline that hooks",
      "body": "The narrative content describing what's happening",
      "lyric_lines": ["line1", "line2"],
      "image_hint": false,
      "image_prompt": ""
    }
  ],
  "visual_slots_used": 0,
  "notes": {
    "compression_applied": false,
    "long_chapter_handled": false
  }
}

RESPOND ONLY WITH VALID JSON. NO MARKDOWN, NO EXPLANATIONS. BE A STORYTELLER!"""


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
                image_prompt = block.image_prompt or ""
            else:
                image_hint = False
                image_prompt = ""
            
            # Use body if available, fallback to text for legacy
            body_text = block.body or block.text or ""
            headline_text = block.headline or ""
            slide_title = block.slide_title or block.type.upper().replace("_", " ")
            
            blocks.append(ContentBlock(
                type=block_type,
                slide_title=slide_title,
                headline=headline_text,
                body=body_text,
                text=body_text,  # Keep for backwards compatibility
                lyric_lines=block.lyric_lines or [],
                image_hint=image_hint,
                image_prompt=image_prompt
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
            model_name=self.settings.GEMINI_MODEL_Text,
            system_instruction=SYSTEM_PROMPT,
            generation_config=GenerationConfig(
                temperature=0.7,
                top_p=0.9,
                max_output_tokens=4096,
                response_mime_type="application/json"
            )
        )
        
        self._initialized = True
        logger.info(f"Gemini client initialized with model: {self.settings.GEMINI_MODEL_Text}")
    
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
