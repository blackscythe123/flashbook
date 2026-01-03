"""
HTTP handlers for note endpoints.
Provides CRUD operations for user notes.
"""

import logging
from fastapi import APIRouter, HTTPException, status

from ..core.schemas import (
    NoteCreateRequest,
    NoteUpdateRequest,
    NoteResponse,
    NotesListResponse,
)
from ..services.notes_service import get_notes_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notes", tags=["notes"])


@router.post(
    "/create",
    response_model=NoteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new note",
    description="Create a note for a specific learning card",
)
async def create_note(request: NoteCreateRequest) -> NoteResponse:
    """Create a new note."""
    try:
        service = get_notes_service()
        note = service.create_note(
            book_id=request.book_id,
            card_index=request.card_index,
            card_title=request.card_title,
            note_text=request.note_text,
        )
        
        return NoteResponse(
            id=note.id,
            book_id=note.book_id,
            card_index=note.card_index,
            card_title=note.card_title,
            note_text=note.note_text,
            created_at=note.created_at.isoformat(),
            updated_at=note.updated_at.isoformat(),
        )
    except Exception as e:
        logger.error(f"Error creating note: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create note",
        )


@router.get(
    "/{note_id}",
    response_model=NoteResponse,
    summary="Get a note",
    description="Retrieve a specific note by ID",
)
async def get_note(note_id: str) -> NoteResponse:
    """Get a note by ID."""
    service = get_notes_service()
    note = service.get_note(note_id)
    
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Note {note_id} not found",
        )
    
    return NoteResponse(
        id=note.id,
        book_id=note.book_id,
        card_index=note.card_index,
        card_title=note.card_title,
        note_text=note.note_text,
        created_at=note.created_at.isoformat(),
        updated_at=note.updated_at.isoformat(),
    )


@router.put(
    "/{note_id}",
    response_model=NoteResponse,
    summary="Update a note",
    description="Update a note's content",
)
async def update_note(note_id: str, request: NoteUpdateRequest) -> NoteResponse:
    """Update a note."""
    try:
        service = get_notes_service()
        note = service.update_note(note_id, request.note_text)
        
        if not note:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Note {note_id} not found",
            )
        
        return NoteResponse(
            id=note.id,
            book_id=note.book_id,
            card_index=note.card_index,
            card_title=note.card_title,
            note_text=note.note_text,
            created_at=note.created_at.isoformat(),
            updated_at=note.updated_at.isoformat(),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating note: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update note",
        )


@router.delete(
    "/{note_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a note",
    description="Delete a note by ID",
)
async def delete_note(note_id: str) -> None:
    """Delete a note."""
    service = get_notes_service()
    deleted = service.delete_note(note_id)
    
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Note {note_id} not found",
        )


@router.get(
    "/book/{book_id}",
    response_model=NotesListResponse,
    summary="List notes for a book",
    description="Get all notes for a specific book",
)
async def list_notes_for_book(book_id: str) -> NotesListResponse:
    """Get all notes for a book."""
    service = get_notes_service()
    notes = service.get_notes_for_book(book_id)
    
    return NotesListResponse(
        notes=[
            NoteResponse(
                id=note.id,
                book_id=note.book_id,
                card_index=note.card_index,
                card_title=note.card_title,
                note_text=note.note_text,
                created_at=note.created_at.isoformat(),
                updated_at=note.updated_at.isoformat(),
            )
            for note in notes
        ],
        total=len(notes),
    )


@router.get(
    "/",
    response_model=NotesListResponse,
    summary="List all notes",
    description="Get all notes",
)
async def list_all_notes() -> NotesListResponse:
    """Get all notes."""
    service = get_notes_service()
    notes = service.get_all_notes()
    
    return NotesListResponse(
        notes=[
            NoteResponse(
                id=note.id,
                book_id=note.book_id,
                card_index=note.card_index,
                card_title=note.card_title,
                note_text=note.note_text,
                created_at=note.created_at.isoformat(),
                updated_at=note.updated_at.isoformat(),
            )
            for note in notes
        ],
        total=len(notes),
    )
