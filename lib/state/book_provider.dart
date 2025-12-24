import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// State provider for the current book being read.
/// Manages book selection, loading, and current reading state.
class BookProvider extends ChangeNotifier {
  Book? _currentBook;
  List<Book> _availableBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Book? get currentBook => _currentBook;
  List<Book> get availableBooks => _availableBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCurrentBook => _currentBook != null;

  /// Load available books from the mock service
  Future<void> loadAvailableBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _availableBooks = MockBookService.getPublicDomainBooks();
    } catch (e) {
      _errorMessage = 'Failed to load books: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a book to read
  void selectBook(Book book) {
    _currentBook = book;
    notifyListeners();
  }

  /// Process a book (simulates Gemini API call)
  Future<void> processBook(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBook = await MockBookService.processBook(bookId);
    } catch (e) {
      _errorMessage = 'Failed to process book: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process an uploaded PDF
  Future<void> processUploadedPdf(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBook = await MockBookService.processUploadedPdf(filePath);
    } catch (e) {
      _errorMessage = 'Failed to process PDF: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear current book selection
  void clearCurrentBook() {
    _currentBook = null;
    notifyListeners();
  }

  /// Get all blocks from current book flattened
  List<LearningBlock> get allBlocks {
    if (_currentBook == null) return [];
    return _currentBook!.chapters.expand((chapter) => chapter.blocks).toList();
  }

  /// Get chapter for a specific block
  Chapter? getChapterForBlock(String blockId) {
    if (_currentBook == null) return null;
    for (final chapter in _currentBook!.chapters) {
      if (chapter.blocks.any((b) => b.id == blockId)) {
        return chapter;
      }
    }
    return null;
  }
}
