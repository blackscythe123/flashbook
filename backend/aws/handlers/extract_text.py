"""
POST /extractText
Two modes:
  1. multipart/form-data  — legacy full-PDF upload (extracts all pages)
  2. application/json     — batch extraction from S3
     Body: { s3_key, start_page (0-based), page_count (default 50) }
     Returns: { text, start_page, end_page, total_pages, has_more, char_count }
Note: cgi module was removed in Python 3.13 — using manual multipart parser.
"""
import base64
import io
import json
import logging
import os
import re

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_s3 = None


def _get_s3():
    global _s3
    if _s3 is None:
        _s3 = boto3.client("s3", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _s3

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


def _extract_batch(body: dict) -> dict:
    """Download PDF from S3, extract only the requested page range."""
    s3_key = body.get("s3_key", "")
    start_page = int(body.get("start_page", 0))
    page_count = int(body.get("page_count", 50))

    if not s3_key:
        return _err(400, "s3_key is required")

    bucket = os.environ.get("PDF_BUCKET", "")
    if not bucket:
        return _err(500, "PDF_BUCKET not configured")

    try:
        obj = _get_s3().get_object(Bucket=bucket, Key=s3_key)
        pdf_bytes = obj["Body"].read()
    except Exception as exc:
        logger.error(f"S3 download error for {s3_key}: {exc}")
        return _err(404, f"PDF not found in S3: {s3_key}")

    try:
        import pypdf
        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
        total_pages = len(reader.pages)

        end_page = min(start_page + page_count, total_pages)
        if start_page >= total_pages:
            return _ok({
                "text": "",
                "start_page": start_page,
                "end_page": start_page,
                "total_pages": total_pages,
                "has_more": False,
                "char_count": 0,
            })

        pages_text = []
        for i in range(start_page, end_page):
            t = reader.pages[i].extract_text()
            if t:
                pages_text.append(t)

        text = "\n\n".join(pages_text)
        has_more = end_page < total_pages

        logger.info(f"Batch extract pages {start_page}-{end_page} of {total_pages} from {s3_key}: {len(text)} chars")
        return _ok({
            "text": text,
            "start_page": start_page,
            "end_page": end_page,
            "total_pages": total_pages,
            "has_more": has_more,
            "char_count": len(text),
        })

    except Exception as exc:
        logger.error(f"Batch extraction error: {exc}")
        return _err(500, f"Failed to extract text: {str(exc)}")


def lambda_handler(event, context):
    # Preflight
    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    headers = event.get("headers") or {}
    content_type = headers.get("Content-Type") or headers.get("content-type", "")

    # ── JSON mode → batch extraction from S3 ─────────────────────────────────
    if "application/json" in content_type:
        try:
            body = json.loads(event.get("body") or "{}")
        except json.JSONDecodeError:
            return _err(400, "Invalid JSON body")
        return _extract_batch(body)

    # ── Multipart mode → legacy full-PDF upload ──────────────────────────────
    if event.get("isBase64Encoded"):
        body_bytes = base64.b64decode(event["body"])
    else:
        raw = event.get("body") or ""
        body_bytes = raw.encode("latin-1") if isinstance(raw, str) else raw

    if "multipart/form-data" not in content_type:
        return _err(400, f"Expected multipart/form-data or application/json, got: {content_type}")

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

    try:
        import pypdf
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
