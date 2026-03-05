"""
/notes/* CRUD
Dispatches based on httpMethod + path to handle all notes operations.
DynamoDB table: flashbook-notes (PK: note_id, GSI: book_id-index)
"""
import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
}

_dynamo = None

def _table():
    global _dynamo
    if _dynamo is None:
        _dynamo = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION", "ap-south-1"))
    return _dynamo.Table(os.environ["NOTES_TABLE"])


def _ok(data, code: int = 200) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps(data)}

def _err(code: int, msg: str) -> dict:
    return {"statusCode": code, "headers": {**CORS, "Content-Type": "application/json"}, "body": json.dumps({"error": msg})}

def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── Handlers ───────────────────────────────────────────────────────────────────

def create_note(body: dict) -> dict:
    book_id = body.get("book_id", "")
    note_text = body.get("note_text", "")
    card_index = body.get("card_index", 0)
    card_title = body.get("card_title", "")

    if not book_id or not note_text:
        return _err(400, "book_id and note_text are required")

    note_id = str(uuid.uuid4())
    now = _now()
    item = {
        "note_id": note_id,
        "book_id": book_id,
        "card_index": card_index,
        "card_title": card_title,
        "note_text": note_text,
        "created_at": now,
        "updated_at": now,
    }
    _table().put_item(Item=item)
    logger.info(f"Created note {note_id} for book {book_id}")
    return _ok(item, 201)


def get_note(note_id: str) -> dict:
    resp = _table().get_item(Key={"note_id": note_id})
    item = resp.get("Item")
    if not item:
        return _err(404, f"Note {note_id} not found")
    return _ok(item)


def update_note(note_id: str, body: dict) -> dict:
    note_text = body.get("note_text")
    if not note_text:
        return _err(400, "note_text is required")

    try:
        resp = _table().update_item(
            Key={"note_id": note_id},
            UpdateExpression="SET note_text = :t, updated_at = :u",
            ExpressionAttributeValues={":t": note_text, ":u": _now()},
            ConditionExpression="attribute_exists(note_id)",
            ReturnValues="ALL_NEW",
        )
        return _ok(resp["Attributes"])
    except _table().meta.client.exceptions.ConditionalCheckFailedException:
        return _err(404, f"Note {note_id} not found")


def delete_note(note_id: str) -> dict:
    try:
        _table().delete_item(
            Key={"note_id": note_id},
            ConditionExpression="attribute_exists(note_id)",
        )
        return {"statusCode": 204, "headers": CORS, "body": ""}
    except _table().meta.client.exceptions.ConditionalCheckFailedException:
        return _err(404, f"Note {note_id} not found")


def list_notes_for_book(book_id: str) -> dict:
    resp = _table().query(
        IndexName="book_id-index",
        KeyConditionExpression=Key("book_id").eq(book_id),
    )
    notes = sorted(resp.get("Items", []), key=lambda n: n.get("created_at", ""))
    return _ok({"notes": notes, "total": len(notes)})


def list_all_notes() -> dict:
    resp = _table().scan()
    notes = resp.get("Items", [])
    return _ok({"notes": notes, "total": len(notes)})


# ── Router ─────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    method = event.get("httpMethod", "GET")
    path: str = event.get("path", "/notes/")
    path_params: dict = event.get("pathParameters") or {}

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS, "body": ""}

    try:
        body = json.loads(event.get("body") or "{}") if method in ("POST", "PUT") else {}
    except json.JSONDecodeError:
        return _err(400, "Invalid JSON body")

    # POST /notes/create
    if method == "POST" and path.rstrip("/").endswith("/create"):
        return create_note(body)

    # GET /notes/book/{book_id}
    if method == "GET" and "book_id" in path_params:
        return list_notes_for_book(path_params["book_id"])

    # GET/PUT/DELETE /notes/{note_id}
    if "note_id" in path_params:
        note_id = path_params["note_id"]
        if method == "GET":
            return get_note(note_id)
        if method == "PUT":
            return update_note(note_id, body)
        if method == "DELETE":
            return delete_note(note_id)

    # GET /notes/
    if method == "GET":
        return list_all_notes()

    return _err(404, "Route not found")
