import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// State provider for bookmarks and highlights.
/// Manages saving, loading, and organizing user's saved content.
class BookmarkProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;
  String _userId = 'demo_user';

  BookmarkProvider({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  // Getters
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  bool get isLoading => _isLoading;

  /// Get only highlights
  List<Bookmark> get highlights =>
      _bookmarks.where((b) => b.type == BookmarkType.highlight).toList();

  /// Get only position bookmarks
  List<Bookmark> get positions =>
      _bookmarks.where((b) => b.type == BookmarkType.position).toList();

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Load all bookmarks
  Future<void> loadBookmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookmarks = await _storageService.getBookmarks(_userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load bookmarks for a specific book
  Future<void> loadBookmarksForBook(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookmarks = await _storageService.getBookmarksForBook(_userId, bookId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new bookmark
  Future<void> addBookmark({
    required String bookId,
    required String chapterId,
    required String blockId,
    required BookmarkType type,
    String? highlightText,
    String? note,
  }) async {
    final bookmark = Bookmark(
      id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
      bookId: bookId,
      chapterId: chapterId,
      blockId: blockId,
      type: type,
      highlightText: highlightText,
      note: note,
      createdAt: DateTime.now(),
    );

    _bookmarks.add(bookmark);
    notifyListeners();

    await _storageService.addBookmark(_userId, bookmark);
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
    notifyListeners();

    await _storageService.removeBookmark(_userId, bookmarkId);
  }

  /// Toggle bookmark for a block
  Future<void> toggleBookmark({
    required String bookId,
    required String chapterId,
    required String blockId,
  }) async {
    final existingIndex = _bookmarks.indexWhere(
      (b) => b.blockId == blockId && b.type == BookmarkType.position,
    );

    if (existingIndex >= 0) {
      await removeBookmark(_bookmarks[existingIndex].id);
    } else {
      await addBookmark(
        bookId: bookId,
        chapterId: chapterId,
        blockId: blockId,
        type: BookmarkType.position,
      );
    }
  }

  /// Check if a block is bookmarked
  bool isBlockBookmarked(String blockId) {
    return _bookmarks.any((b) => b.blockId == blockId);
  }

  /// Get bookmarks sorted by date (most recent first)
  List<Bookmark> get sortedByDate {
    final sorted = List<Bookmark>.from(_bookmarks);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Get bookmark count
  int get totalCount => _bookmarks.length;
  int get highlightCount => highlights.length;
  int get positionCount => positions.length;
}
