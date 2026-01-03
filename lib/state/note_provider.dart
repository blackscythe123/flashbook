import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

/// State provider for managing user notes.
/// Handles CRUD operations and persistence.
class NoteProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  NoteProvider() {
    _initialize();
  }

  /// Initialize by loading notes from storage
  Future<void> _initialize() async {
    await loadNotes();
  }

  /// Load all notes from storage
  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await _storageService.getNotes();
    } catch (e) {
      _errorMessage = 'Failed to load notes: $e';
      print('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new note
  Future<void> addNote({
    required String id,
    required String bookId,
    required int cardIndex,
    required String cardTitle,
    required String noteText,
  }) async {
    try {
      final note = Note(
        id: id,
        bookId: bookId,
        cardIndex: cardIndex,
        cardTitle: cardTitle,
        noteText: noteText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _notes.add(note);
      await _storageService.saveNotes(_notes);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add note: $e';
      print('Error adding note: $e');
    }
  }

  /// Update an existing note
  Future<void> updateNote(String noteId, String newText) async {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(
          noteText: newText,
          updatedAt: DateTime.now(),
        );
        await _storageService.saveNotes(_notes);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update note: $e';
      print('Error updating note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      _notes.removeWhere((note) => note.id == noteId);
      await _storageService.saveNotes(_notes);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete note: $e';
      print('Error deleting note: $e');
    }
  }

  /// Get notes for a specific book
  List<Note> getNotesForBook(String bookId) {
    return _notes.where((note) => note.bookId == bookId).toList();
  }

  /// Get note for specific card (if exists)
  Note? getNoteForCard(String bookId, int cardIndex) {
    try {
      return _notes.firstWhere(
        (note) => note.bookId == bookId && note.cardIndex == cardIndex,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a card has a note
  bool hasNoteForCard(String bookId, int cardIndex) {
    return _notes.any((note) => note.bookId == bookId && note.cardIndex == cardIndex);
  }
}
