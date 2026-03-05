"""
POST /extractText
Accepts multipart/form-data with a PDF file field named "file".
Returns { text, page_count, char_count }.
Note: cgi module was removed in Python 3.13 — using manual multipart parser.
"""
import base64
import io
import json
import logging
import re

import pypdf

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}


def _ok(data: dict) -> dict:
    return {"statusCode": 200, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}


def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


def _parse_multipart(body_bytes: bytes, content_type: str):
    """
    Minimal multipart/form-data parser (replaces removed cgi module).
    Returns dict of {field_name: (filename, bytes)} for file fields.
    """
    # Extract boundary from Content-Type header
    match = re.search(r'boundary=([^\s;]+)', content_type)
    if not match:
        return {}
    boundary = match.group(1).strip('"')
    delimiter = f"--{boundary}".encode()

    files = {}
    parts = body_bytes.split(delimiter)

    for part in parts:
        if not part or part in (b"", b"--\r\n", b"--"):
            continue
        # Strip leading \r\n
        if part.startswith(b"\r\n"):
            part = part[2:]
        # Split headers from body
        if b"\r\n\r\n" not in part:
            continue
        headers_raw, _, file_body = part.partition(b"\r\n\r\n")
        # Strip trailing \r\n
        if file_body.endswith(b"\r\n"):
            file_body = file_body[:-2]

        headers_str = headers_raw.decode("utf-8", errors="replace")

        # Get field name
        name_match = re.search(r'name="([^"]+)"', headers_str)
        if not name_match:
            continue
        field_name = name_match.group(1)

        # Get filename (present for file fields)
        filename_match = re.search(r'filename="([^"]*)"', headers_str)
        filename = filename_match.group(1) if filename_match else None

        files[field_name] = (filename, file_body)

    return files


def lambda_handler(event, context):
    # Preflight
    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    # ── decode body ──────────────────────────────────────────────────────────
    if event.get("isBase64Encoded"):
        body_bytes = base64.b64decode(event["body"])
    else:
        raw = event.get("body") or ""
        body_bytes = raw.encode("latin-1") if isinstance(raw, str) else raw

    headers = event.get("headers") or {}
    content_type = headers.get("Content-Type") or headers.get("content-type", "")

    if "multipart/form-data" not in content_type:
        return _err(400, f"Expected multipart/form-data, got: {content_type}")

    # ── parse multipart ──────────────────────────────────────────────────────
    try:
        fields = _parse_multipart(body_bytes, content_type)
    except Exception as exc:
        logger.error(f"Multipart parse error: {exc}")
        return _err(400, f"Failed to parse multipart data: {str(exc)}")

    if "file" not in fields:
        return _err(400, "Missing 'file' field in multipart form-data")

    filename, pdf_bytes = fields["file"]
    filename = filename or "upload.pdf"

    if not filename.lower().endswith(".pdf"):
        return _err(400, "File must be a PDF")

    # ── extract text via pypdf ───────────────────────────────────────────────
    try:
        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))

        pages_text = []
        for page in reader.pages:
            t = page.extract_text()
            if t:
                pages_text.append(t)

        full_text = "\n\n".join(pages_text)
        logger.info(f"Extracted {len(full_text)} chars from {len(reader.pages)} pages — {filename}")

        return _ok({
            "text": full_text,
            "page_count": len(reader.pages),
            "char_count": len(full_text),
            "filename": filename,
        })

    except Exception as exc:
        logger.error(f"PDF extraction error: {exc}")
        return _err(500, f"Failed to extract text: {str(exc)}")
