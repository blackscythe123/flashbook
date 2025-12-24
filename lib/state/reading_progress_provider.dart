import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// State provider for reading progress.
/// Tracks current position, progress percentage, and reading stats.
class ReadingProgressProvider extends ChangeNotifier {
  final StorageService _storageService;

  ReadingProgress? _currentProgress;
  bool _isLoading = false;
  String _userId = 'demo_user';

  ReadingProgressProvider({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  // Getters
  ReadingProgress? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  double get progressPercentage => _currentProgress?.progressPercentage ?? 0;
  int get currentBlockIndex => _currentProgress?.currentBlockIndex ?? 0;
  int get totalBlocksRead => _currentProgress?.totalBlocksRead ?? 0;
  int get readingStreak => _currentProgress?.readingStreak ?? 0;

  /// Set user ID for storage operations
  void setUserId(String userId) {
    _userId = userId;
    _storageService.initializeDemoData(userId);
  }

  /// Load progress for a specific book
  Future<void> loadProgress(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentProgress = await _storageService.getProgress(_userId, bookId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize progress for a new book
  void initializeProgress(Book book) {
    if (book.chapters.isEmpty || book.chapters.first.blocks.isEmpty) return;

    _currentProgress = ReadingProgress.initial(
      bookId: book.id,
      firstChapterId: book.chapters.first.id,
      firstBlockId: book.chapters.first.blocks.first.id,
      totalBlocks: book.totalBlocks,
    );
    notifyListeners();
    _saveProgress();
  }

  /// Update progress when user moves to a new block
  Future<void> updateProgress({
    required Book book,
    required int chapterIndex,
    required int blockIndex,
  }) async {
    if (_currentProgress == null) {
      initializeProgress(book);
      return;
    }

    final chapter = book.chapters[chapterIndex];
    final block = chapter.blocks[blockIndex];

    // Calculate total blocks read
    int totalRead = 0;
    for (int i = 0; i < chapterIndex; i++) {
      totalRead += book.chapters[i].blocks.length;
    }
    totalRead += blockIndex + 1;

    // Calculate progress percentage
    final percentage = (totalRead / book.totalBlocks * 100).clamp(0.0, 100.0);

    _currentProgress = _currentProgress!.copyWith(
      currentChapterId: chapter.id,
      currentBlockId: block.id,
      currentChapterIndex: chapterIndex,
      currentBlockIndex: blockIndex,
      progressPercentage: percentage,
      totalBlocksRead: totalRead,
      lastReadAt: DateTime.now(),
    );

    notifyListeners();
    await _saveProgress();
  }

  /// Save current progress to storage
  Future<void> _saveProgress() async {
    if (_currentProgress == null) return;
    await _storageService.saveProgress(_userId, _currentProgress!);
  }

  /// Get global block index from chapter/block indices
  int getGlobalBlockIndex(Book book, int chapterIndex, int blockIndex) {
    int index = 0;
    for (int i = 0; i < chapterIndex; i++) {
      index += book.chapters[i].blocks.length;
    }
    return index + blockIndex;
  }

  /// Get chapter and block indices from global block index
  ({int chapterIndex, int blockIndex}) getLocalIndices(
    Book book,
    int globalIndex,
  ) {
    int remaining = globalIndex;
    for (int i = 0; i < book.chapters.length; i++) {
      if (remaining < book.chapters[i].blocks.length) {
        return (chapterIndex: i, blockIndex: remaining);
      }
      remaining -= book.chapters[i].blocks.length;
    }
    // Return last block if index is out of bounds
    final lastChapter = book.chapters.length - 1;
    return (
      chapterIndex: lastChapter,
      blockIndex: book.chapters[lastChapter].blocks.length - 1,
    );
  }

  /// Reset progress
  void reset() {
    _currentProgress = null;
    notifyListeners();
  }
}
