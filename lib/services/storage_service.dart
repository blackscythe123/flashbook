import '../models/models.dart';

/// Storage service for user progress and bookmarks.
/// Uses mock data for hackathon demo (would use Firestore in production).
class StorageService {
  // In-memory storage for demo
  final Map<String, ReadingProgress> _progressMap = {};
  final List<Bookmark> _bookmarks = [];

  // ============================================
  // READING PROGRESS
  // ============================================

  /// Get reading progress for a book
  Future<ReadingProgress?> getProgress(String userId, String bookId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _progressMap['${userId}_$bookId'];
  }

  /// Save reading progress
  Future<void> saveProgress(String userId, ReadingProgress progress) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _progressMap['${userId}_${progress.bookId}'] = progress;
  }

  /// Get all reading progress for a user
  Future<List<ReadingProgress>> getAllProgress(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _progressMap.entries
        .where((e) => e.key.startsWith('${userId}_'))
        .map((e) => e.value)
        .toList();
  }

  // ============================================
  // BOOKMARKS
  // ============================================

  /// Get all bookmarks for a user
  Future<List<Bookmark>> getBookmarks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_bookmarks);
  }

  /// Get bookmarks for a specific book
  Future<List<Bookmark>> getBookmarksForBook(
    String userId,
    String bookId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookmarks.where((b) => b.bookId == bookId).toList();
  }

  /// Add a bookmark
  Future<void> addBookmark(String userId, Bookmark bookmark) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _bookmarks.add(bookmark);
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String userId, String bookmarkId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
  }

  /// Check if a block is bookmarked
  Future<bool> isBookmarked(String userId, String blockId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _bookmarks.any((b) => b.blockId == blockId);
  }

  // ============================================
  // DEMO DATA INITIALIZATION
  // ============================================

  /// Initialize with demo data for hackathon
  void initializeDemoData(String userId) {
    // Add some sample bookmarks
    _bookmarks.addAll([
      Bookmark(
        id: 'bm_1',
        bookId: 'atomic_habits_001',
        chapterId: 'ch_1',
        blockId: 'block_1_3',
        type: BookmarkType.highlight,
        highlightText:
            'You do not rise to the level of your goals. You fall to the level of your systems.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Bookmark(
        id: 'bm_2',
        bookId: 'sapiens_001',
        chapterId: 'sapiens_ch_1',
        blockId: 'sapiens_block_1_1',
        type: BookmarkType.position,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Bookmark(
        id: 'bm_3',
        bookId: 'psychology_money_001',
        chapterId: 'money_ch_1',
        blockId: 'money_block_1_1',
        type: BookmarkType.highlight,
        highlightText:
            'Spending money to show people how much money you have is the fastest way to have less money.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);

    // Add sample progress
    _progressMap['${userId}_atomic_habits_001'] = ReadingProgress(
      bookId: 'atomic_habits_001',
      currentChapterId: 'ch_2',
      currentBlockId: 'block_2_2',
      currentChapterIndex: 1,
      currentBlockIndex: 1,
      progressPercentage: 35,
      totalBlocksRead: 4,
      totalBlocks: 10,
      lastReadAt: DateTime.now().subtract(const Duration(hours: 2)),
      readingStreak: 4,
    );
  }
}
