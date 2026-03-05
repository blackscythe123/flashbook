"""
POST /generateSummary
Calls Gemini API, caches result in DynamoDB (SlidesTable), and returns the
SummaryResponse schema that Flutter already parses.
"""
import hashlib
import json
import logging
import os
import time
from typing import Optional

import boto3
import google.generativeai as genai
from google.generativeai.types import GenerationConfig

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}

# ── DynamoDB ─────────────────────────────────────────────────────────────────
_dynamo = None

def _get_dynamo():
    global _dynamo
    if _dynamo is None:
        _dynamo = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _dynamo

def _slides_table():
    return _get_dynamo().Table(os.environ["SLIDES_TABLE"])

# ── Gemini ────────────────────────────────────────────────────────────────────
_gemini_model = None

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
5. "image_prompt": If image_hint is true, describe the scene for image generation

FORMATTING:
- Headlines should NOT repeat the body content
- Body should be narrative, not dry summary
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
      "lyric_lines": [],
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


def _get_model():
    global _gemini_model
    if _gemini_model is None:
        api_key = os.environ.get("GEMINI_API_KEY", "")
        model_name = os.environ.get("GEMINI_MODEL_TEXT", "gemini-2.0-flash")
        genai.configure(api_key=api_key)
        _gemini_model = genai.GenerativeModel(
            model_name=model_name,
            system_instruction=SYSTEM_PROMPT,
            generation_config=GenerationConfig(
                temperature=0.7,
                top_p=0.9,
                max_output_tokens=4096,
                response_mime_type="application/json",
            ),
        )
        logger.info(f"Gemini model initialised: {model_name}")
    return _gemini_model


# ── Cache helpers ─────────────────────────────────────────────────────────────
def _cache_key(text_chunk: str) -> str:
    return hashlib.sha256(text_chunk.encode()).hexdigest()[:32]

def _cache_get(book_id: str, chapter_hash: str) -> Optional[dict]:
    try:
        resp = _slides_table().get_item(Key={"book_id": book_id, "chapter_hash": chapter_hash})
        item = resp.get("Item")
        if item and item.get("expires_at", 0) > int(time.time()):
            return json.loads(item["response_json"])
    except Exception as exc:
        logger.warning(f"Cache get error: {exc}")
    return None

def _cache_put(book_id: str, chapter_hash: str, response_data: dict, ttl: int = 86400) -> None:
    try:
        _slides_table().put_item(Item={
            "book_id": book_id,
            "chapter_hash": chapter_hash,
            "response_json": json.dumps(response_data),
            "expires_at": int(time.time()) + ttl,
        })
    except Exception as exc:
        logger.warning(f"Cache put error: {exc}")


# ── Response helpers ──────────────────────────────────────────────────────────
def _ok(data: dict) -> dict:
    return {"statusCode": 200, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}

def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


# ── Parse Gemini response ─────────────────────────────────────────────────────
def _parse_response(raw: str, chapter_title: str) -> dict:
    cleaned = raw.strip()
    for prefix in ("```json", "```"):
        if cleaned.startswith(prefix):
            cleaned = cleaned[len(prefix):]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    data = json.loads(cleaned)

    blocks = []
    visual_count = 0
    for b in data.get("blocks", [])[:8]:
        image_hint = b.get("image_hint", False) and visual_count < 2
        if image_hint:
            visual_count += 1
        body_text = b.get("body") or b.get("text") or ""
        blocks.append({
            "type": b.get("type", "insight"),
            "slide_title": b.get("slide_title", b.get("type", "INSIGHT").upper()),
            "headline": b.get("headline", ""),
            "body": body_text,
            "text": body_text,
            "lyric_lines": b.get("lyric_lines") or [],
            "image_hint": image_hint,
            "image_prompt": b.get("image_prompt", "") if image_hint else "",
        })

    return {
        "unit_title": data.get("unit_title") or chapter_title or "Learning Unit",
        "blocks": blocks,
        "visual_slots_used": visual_count,
        "cached": False,
        "notes": {
            "compression_applied": data.get("notes", {}).get("compression_applied", False),
            "long_chapter_handled": data.get("notes", {}).get("long_chapter_handled", False),
            "context_used_only_for_continuity": True,
        },
    }


def _fallback(chapter_title: str, text_preview: str) -> dict:
    return {
        "unit_title": chapter_title or "Chapter Summary",
        "blocks": [
            {"type": "insight", "slide_title": "SUMMARY", "headline": "Chapter overview",
             "body": f"This chapter covers: {text_preview[:300]}...", "text": "",
             "lyric_lines": [], "image_hint": False, "image_prompt": ""},
            {"type": "insight", "slide_title": "NOTE", "headline": "Generation encountered an issue",
             "body": "AI summary generation encountered an issue. Please try again.",
             "text": "", "lyric_lines": [], "image_hint": False, "image_prompt": ""},
        ],
        "visual_slots_used": 0,
        "cached": False,
        "notes": {"compression_applied": False, "long_chapter_handled": False,
                  "context_used_only_for_continuity": True},
    }


# ── Lambda entry point ────────────────────────────────────────────────────────
def lambda_handler(event, context):
    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _err(400, "Invalid JSON body")

    text_chunk: str = body.get("text_chunk", "")
    if len(text_chunk) < 100:
        return _err(400, "text_chunk must be at least 100 characters")

    book_id: str = body.get("book_id") or "default"
    chapter_title: str = body.get("chapter_title") or ""
    mode: str = body.get("mode") or "chapter"
    prev_context: str = body.get("prev_context") or ""
    next_context: str = body.get("next_context") or ""

    # ── Cache check ───────────────────────────────────────────────────────────
    chapter_hash = _cache_key(text_chunk)
    cached = _cache_get(book_id, chapter_hash)
    if cached:
        cached["cached"] = True
        logger.info("Cache hit")
        return _ok(cached)

    # ── Build prompt ──────────────────────────────────────────────────────────
    mode_map = {
        "chapter": "Summarize this chapter as a learning unit.",
        "concept": "Extract and explain the core concept from this text.",
        "law": "Identify and break down the principle/law presented in this text.",
    }
    parts = [f"MODE: {mode_map.get(mode, mode_map['chapter'])}"]
    if prev_context:
        parts.append(f"\n[PREV_CONTEXT - for continuity awareness only, do NOT summarize]:\n{prev_context[:500]}...")
    if next_context:
        parts.append(f"\n[NEXT_CONTEXT - for continuity awareness only, do NOT summarize]:\n{next_context[:500]}...")
    if chapter_title:
        parts.append(f"\nCHAPTER TITLE: {chapter_title}")
    parts.append(f"\n---TARGET CHAPTER TEXT (summarize ONLY this)---\n{text_chunk}\n---END OF TARGET CHAPTER---")
    parts.append("\nGenerate the structured JSON output now:")
    user_prompt = "\n".join(parts)

    # ── Call Gemini ───────────────────────────────────────────────────────────
    try:
        model = _get_model()
        response = model.generate_content(user_prompt)
        if not response.text:
            raise ValueError("Empty response from Gemini")

        result = _parse_response(response.text, chapter_title)
        _cache_put(book_id, chapter_hash, result)
        logger.info(f"Generated {len(result['blocks'])} blocks for book_id={book_id}")
        return _ok(result)

    except Exception as exc:
        logger.error(f"Gemini error: {exc}")
        return _ok(_fallback(chapter_title, text_chunk))
