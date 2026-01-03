"""
Service for managing notes.
Handles in-memory storage and operations on notes.
"""

import logging
from datetime import datetime
from typing import List, Optional
from uuid import uuid4

logger = logging.getLogger(__name__)


class Note:
    """In-memory note model."""
    
    def __init__(
        self,
        id: str,
        book_id: str,
        card_index: int,
        card_title: str,
        note_text: str,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None,
    ):
        self.id = id
        self.book_id = book_id
        self.card_index = card_index
        self.card_title = card_title
        self.note_text = note_text
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "book_id": self.book_id,
            "card_index": self.card_index,
            "card_title": self.card_title,
            "note_text": self.note_text,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> "Note":
        """Create from dictionary."""
        created_at = None
        updated_at = None
        
        if isinstance(data.get("created_at"), str):
            created_at = datetime.fromisoformat(data["created_at"])
        
        if isinstance(data.get("updated_at"), str):
            updated_at = datetime.fromisoformat(data["updated_at"])
        
        return cls(
            id=data["id"],
            book_id=data["book_id"],
            card_index=data["card_index"],
            card_title=data["card_title"],
            note_text=data["note_text"],
            created_at=created_at,
            updated_at=updated_at,
        )


class NotesService:
    """Service for managing notes in memory."""
    
    def __init__(self):
        """Initialize notes storage."""
        self._notes: dict[str, Note] = {}
    
    def create_note(
        self,
        book_id: str,
        card_index: int,
        card_title: str,
        note_text: str,
    ) -> Note:
        """Create a new note."""
        note_id = str(uuid4())
        note = Note(
            id=note_id,
            book_id=book_id,
            card_index=card_index,
            card_title=card_title,
            note_text=note_text,
        )
        self._notes[note_id] = note
        logger.info(f"Created note {note_id} for book {book_id}")
        return note
    
    def get_note(self, note_id: str) -> Optional[Note]:
        """Get a note by ID."""
        return self._notes.get(note_id)
    
    def update_note(self, note_id: str, note_text: str) -> Optional[Note]:
        """Update a note's text."""
        note = self._notes.get(note_id)
        if note:
            note.note_text = note_text
            note.updated_at = datetime.utcnow()
            logger.info(f"Updated note {note_id}")
            return note
        return None
    
    def delete_note(self, note_id: str) -> bool:
        """Delete a note."""
        if note_id in self._notes:
            del self._notes[note_id]
            logger.info(f"Deleted note {note_id}")
            return True
        return False
    
    def get_notes_for_book(self, book_id: str) -> List[Note]:
        """Get all notes for a specific book."""
        return [note for note in self._notes.values() if note.book_id == book_id]
    
    def get_note_for_card(
        self,
        book_id: str,
        card_index: int,
    ) -> Optional[Note]:
        """Get note for a specific card (if exists)."""
        for note in self._notes.values():
            if note.book_id == book_id and note.card_index == card_index:
                return note
        return None
    
    def get_all_notes(self) -> List[Note]:
        """Get all notes."""
        return list(self._notes.values())
    
    def clear_notes(self) -> None:
        """Clear all notes (for testing)."""
        self._notes.clear()
        logger.info("Cleared all notes")


# Singleton instance
_notes_service: Optional[NotesService] = None


def get_notes_service() -> NotesService:
    """Get or create the notes service instance."""
    global _notes_service
    if _notes_service is None:
        _notes_service = NotesService()
    return _notes_service
