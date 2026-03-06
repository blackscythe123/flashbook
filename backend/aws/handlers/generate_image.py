"""
POST /generateImage
Flow: Gemini generates image bytes → uploaded to S3 → return a pre-signed S3 URL.
Flutter can http.get() the URL and save it with Gal.putImageBytes().
"""
import base64
import json
import logging
import os
import re
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}

# ── Lazy singletons ───────────────────────────────────────────────────────────
_genai_client = None
_s3_client = None


def _get_genai():
    global _genai_client
    if _genai_client is None:
        from google import genai
        _genai_client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
        logger.info("Gemini client initialised")
    return _genai_client


def _get_s3():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client("s3", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _s3_client


# ── Helpers ───────────────────────────────────────────────────────────────────

def _ok(data: dict) -> dict:
    return {"statusCode": 200, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}


def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


# ── Core logic ────────────────────────────────────────────────────────────────

def _detect_visual_type(prompt: str, explicit_visual_type: str) -> str:
    if explicit_visual_type in {"scene", "diagram", "concept", "historical", "portrait"}:
        return explicit_visual_type

    p = (prompt or "").lower()
    if re.search(r"diagram|flowchart|labeled|labelled|arrow|process|cycle|equation|schema|infographic", p):
        return "diagram"
    if re.search(r"historical|ancient|empire|battle|king|queen|dynasty|revolution|medieval", p):
        return "historical"
    if re.search(r"portrait|close[- ]?up|face|biography|scientist|author", p):
        return "portrait"
    if re.search(r"concept|symbolic|metaphor|abstract|idea", p):
        return "concept"
    return "scene"


def _rendering_guide(visual_type: str, style: str) -> str:
    if visual_type == "diagram":
        return (
            "Create an educational diagram/infographic style visual with clear structure, "
            "high contrast labels, arrows where needed, and minimal visual clutter."
        )
    if visual_type == "historical":
        return (
            "Create a historically grounded illustrative scene with period-accurate environment, "
            "costume, and objects; painterly realism is preferred over stylized fantasy."
        )
    if visual_type == "portrait":
        return (
            "Create a character-focused portrait with expressive face, readable silhouette, "
            "controlled background depth, and cinematic portrait lighting."
        )
    if visual_type == "concept":
        return (
            "Create conceptual art that visualizes the idea symbolically while staying readable, "
            "with strong composition and color storytelling."
        )
    return f"Create a high quality {style} style narrative scene illustration with cinematic composition."


def _enhance_prompt(prompt: str, visual_type: str, style: str, book_title: str, character_context: str) -> str:
    guide = _rendering_guide(visual_type, style)
    context_bits = []
    if book_title:
        context_bits.append(f"Book context: {book_title}")
    if character_context:
        context_bits.append(f"Character notes: {character_context}")
    context_text = " | ".join(context_bits)

    enhanced = (
        f"{guide} "
        f"Visual type: {visual_type}. "
        "Build a single coherent image prompt including subject, environment, mood, lighting, "
        "camera framing, and visual details. "
        "Avoid vague descriptions. "
        f"Base scene: {prompt}. "
    )
    if context_text:
        enhanced += f"{context_text}. "

    return enhanced[:900]


def _call_gemini(prompt: str, style: str, book_title: str, character_context: str, visual_type: str) -> bytes | None:
    """Call Gemini image model and return raw PNG bytes, or None on failure."""
    # MUST use an image-generation capable model, NOT a text-only one
    model_name = os.environ.get("GEMINI_MODEL_IMAGE", "gemini-2.0-flash-exp-image-generation")

    enhanced = _enhance_prompt(prompt, visual_type, style, book_title, character_context)

    logger.info(f"Calling Gemini '{model_name}': {enhanced[:60]}...")

    from google.genai import types as genai_types
    response = _get_genai().models.generate_content(
        model=model_name,
        contents=enhanced,
        config=genai_types.GenerateContentConfig(
            response_modalities=["IMAGE", "TEXT"],
        ),
    )

    if response.candidates and response.candidates[0].content.parts:
        for part in response.candidates[0].content.parts:
            if hasattr(part, "inline_data") and part.inline_data:
                raw = part.inline_data.data
                # inline_data.data can be bytes or base64 string
                if isinstance(raw, str):
                    return base64.b64decode(raw)
                return raw

    logger.warning("Gemini returned no image data")
    return None


def _upload_to_s3(image_bytes: bytes) -> str:
    """Upload PNG bytes to S3 and return a presigned GET URL (7-day expiry).

    CachedNetworkImage on Flutter caches the actual bytes locally, so the URL
    only needs to work for the initial download.
    """
    bucket = os.environ["IMAGES_BUCKET"]
    key = f"generated/{uuid.uuid4()}.png"

    s3 = _get_s3()
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=image_bytes,
        ContentType="image/png",
    )

    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=604800,  # 7 days
    )
    logger.info(f"Uploaded image to S3, presigned URL generated: {key}")
    return url


# ── Lambda entry point ────────────────────────────────────────────────────────

def lambda_handler(event, context):
    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _err(400, "Invalid JSON body")

    prompt: str             = body.get("prompt", "")
    style: str              = body.get("style", "anime")
    book_title: str         = body.get("book_title", "")
    character_context: str  = body.get("character_context", "")
    visual_type: str        = body.get("visual_type", "")

    # Log exactly what was received so we can see in CloudWatch
    logger.info(f"Received prompt ({len(prompt)} chars): '{prompt[:120]}'")
    logger.info(f"book_title='{book_title}' style='{style}'")

    if len(prompt) < 10:
        logger.warning(f"Prompt too short ({len(prompt)} chars), body keys: {list(body.keys())}")
        return _err(400, "prompt must be at least 10 characters")

    try:
        resolved_visual_type = _detect_visual_type(prompt, visual_type)
        image_bytes = _call_gemini(prompt, style, book_title, character_context, resolved_visual_type)
        if not image_bytes:
            return _err(502, "Gemini returned no image data")

        image_url = _upload_to_s3(image_bytes)
        return _ok({"image_url": image_url, "prompt": prompt, "visual_type": resolved_visual_type})

    except Exception as exc:
        logger.error(f"Image generation failed: {exc}")
        return _err(500, str(exc))
