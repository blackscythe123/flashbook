"""
/books/* — User book management (upload, list, progress, delete).
DynamoDB table: flashbook-user-books (PK: user_id, SK: book_id)
S3 bucket: flashbook-pdfs-{AccountId}
"""
import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.session import Config
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
}

_dynamo = None
_s3 = None


def _get_dynamo():
    global _dynamo
    if _dynamo is None:
        _dynamo = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _dynamo


def _table():
    return _get_dynamo().Table(os.environ["USER_BOOKS_TABLE"])


def _get_s3():
    global _s3
    if _s3 is None:
        region = os.environ.get("AWS_REGION", "ap-south-1")
        # Use explicit endpoint_url so presigned URLs are regionally pinned
        # and clients don't get a 307 redirect on upload.
        _s3 = boto3.client(
            "s3",
            region_name=region,
            endpoint_url=f"https://s3.{region}.amazonaws.com",
            config=Config(signature_version="s3v4"),
        )
    return _s3


def _ok(data, code: int = 200) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}


def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _get_user_id(event: dict) -> str:
    try:
        return event["requestContext"]["authorizer"]["claims"]["sub"]
    except (KeyError, TypeError):
        return "anonymous"


# ── Handlers ──────────────────────────────────────────────────────────────────

def _upload(user_id: str, body: dict) -> dict:
    """Generate a presigned PUT URL for S3 and create a DynamoDB entry."""
    filename = body.get("filename", "")
    title = body.get("title", "")

    if not filename:
        return _err(400, "filename is required")

    book_id = str(uuid.uuid4())
    s3_key = f"users/{user_id}/books/{book_id}/{filename}"
    bucket = os.environ["PDF_BUCKET"]

    # Generate presigned PUT URL (15 min expiry)
    upload_url = _get_s3().generate_presigned_url(
        "put_object",
        Params={
            "Bucket": bucket,
            "Key": s3_key,
            "ContentType": "application/pdf",
        },
        ExpiresIn=900,
    )

    # Create book record in DynamoDB
    now = _now()
    item = {
        "user_id": user_id,
        "book_id": book_id,
        "title": title or filename.replace(".pdf", "").replace(".txt", ""),
        "filename": filename,
        "s3_key": s3_key,
        "total_pages": 0,
        "pages_extracted": 0,
        "status": "uploading",
        "progress_pct": 0,
        "current_chapter_index": 0,
        "current_block_index": 0,
        "created_at": now,
        "last_read_at": now,
    }
    _table().put_item(Item=item)

    logger.info(f"Created book {book_id} for user {user_id}, s3_key={s3_key}")
    return _ok({"book_id": book_id, "upload_url": upload_url, "s3_key": s3_key}, 201)


def _confirm(user_id: str, book_id: str) -> dict:
    """Read PDF from S3 to count pages, update DynamoDB status to 'ready'."""
    import io
    import pypdf

    # Get book record
    resp = _table().get_item(Key={"user_id": user_id, "book_id": book_id})
    item = resp.get("Item")
    if not item:
        return _err(404, f"Book {book_id} not found")

    s3_key = item["s3_key"]
    bucket = os.environ["PDF_BUCKET"]

    try:
        # Download PDF from S3
        obj = _get_s3().get_object(Bucket=bucket, Key=s3_key)
        pdf_bytes = obj["Body"].read()

        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
        total_pages = len(reader.pages)

        # Update DynamoDB
        _table().update_item(
            Key={"user_id": user_id, "book_id": book_id},
            UpdateExpression="SET total_pages = :tp, #s = :st",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":tp": total_pages, ":st": "ready"},
        )

        logger.info(f"Confirmed book {book_id}: {total_pages} pages")
        return _ok({"book_id": book_id, "total_pages": total_pages, "status": "ready", "s3_key": s3_key})

    except Exception as e:
        logger.error(f"Confirm error for {book_id}: {e}")
        return _err(500, f"Failed to process PDF: {str(e)}")


def _list_books(user_id: str) -> dict:
    """List all books for a user."""
    resp = _table().query(
        KeyConditionExpression=Key("user_id").eq(user_id),
    )
    books = resp.get("Items", [])
    # Convert Decimal types to int/float for JSON serialization
    for book in books:
        for k, v in book.items():
            if hasattr(v, "__int__") and not isinstance(v, (int, float, str, bool)):
                book[k] = int(v) if v == int(v) else float(v)

    books.sort(key=lambda b: b.get("last_read_at", ""), reverse=True)
    return _ok({"books": books, "total": len(books)})


def _update_progress(user_id: str, book_id: str, body: dict) -> dict:
    """Update reading progress for a book."""
    chapter_idx = body.get("current_chapter_index", 0)
    block_idx = body.get("current_block_index", 0)
    progress_pct = body.get("progress_pct", 0)
    pages_extracted = body.get("pages_extracted")
    status = body.get("status")
    # image_urls: dict of { blockId: presignedUrl } for cross-device image caching
    image_urls = body.get("image_urls")

    update_expr = "SET current_chapter_index = :ci, current_block_index = :bi, progress_pct = :pp, last_read_at = :lr"
    expr_values = {
        ":ci": chapter_idx,
        ":bi": block_idx,
        ":pp": int(progress_pct) if progress_pct == int(progress_pct) else progress_pct,
        ":lr": _now(),
    }
    expr_names = {}

    if pages_extracted is not None:
        update_expr += ", pages_extracted = :pe"
        expr_values[":pe"] = pages_extracted

    if image_urls is not None and isinstance(image_urls, dict):
        update_expr += ", image_urls = :iu"
        expr_values[":iu"] = image_urls

    if status is not None:
        update_expr += ", #s = :st"
        expr_names["#s"] = "status"
        expr_values[":st"] = status

    kwargs = dict(
        Key={"user_id": user_id, "book_id": book_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values,
        ReturnValues="ALL_NEW",
    )
    if expr_names:
        kwargs["ExpressionAttributeNames"] = expr_names

    resp = _table().update_item(**kwargs)

    logger.info(f"Updated progress for {book_id}: {progress_pct}%")
    return _ok(resp.get("Attributes", {}))


def _delete_book(user_id: str, book_id: str) -> dict:
    """Delete a book and its S3 objects."""
    # Get book to find S3 key
    resp = _table().get_item(Key={"user_id": user_id, "book_id": book_id})
    item = resp.get("Item")

    if item:
        bucket = os.environ["PDF_BUCKET"]
        s3_key = item.get("s3_key", "")
        if s3_key:
            try:
                _get_s3().delete_object(Bucket=bucket, Key=s3_key)
            except Exception as e:
                logger.warning(f"Failed to delete S3 object {s3_key}: {e}")

    # Delete DynamoDB record
    _table().delete_item(Key={"user_id": user_id, "book_id": book_id})
    logger.info(f"Deleted book {book_id} for user {user_id}")
    return {"statusCode": 204, "headers": CORS, "body": ""}


# ── Router ────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    method = event.get("httpMethod", "GET")
    path: str = event.get("path", "")
    path_params: dict = event.get("pathParameters") or {}

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    user_id = _get_user_id(event)

    try:
        body = json.loads(event.get("body") or "{}") if method in ("POST", "PUT") else {}
    except json.JSONDecodeError:
        return _err(400, "Invalid JSON body")

    # POST /books/upload
    if method == "POST" and path.rstrip("/").endswith("/upload"):
        return _upload(user_id, body)

    # POST /books/{book_id}/confirm
    if method == "POST" and "book_id" in path_params and path.rstrip("/").endswith("/confirm"):
        return _confirm(user_id, path_params["book_id"])

    # GET /books
    if method == "GET" and "book_id" not in path_params:
        return _list_books(user_id)

    # PUT /books/{book_id}/progress
    if method == "PUT" and "book_id" in path_params:
        return _update_progress(user_id, path_params["book_id"], body)

    # DELETE /books/{book_id}
    if method == "DELETE" and "book_id" in path_params:
        return _delete_book(user_id, path_params["book_id"])

    return _err(404, "Route not found")
