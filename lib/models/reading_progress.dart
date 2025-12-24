/// Reading progress model to track user's progress through a book.
class ReadingProgress {
  final String bookId;
  final String currentChapterId;
  final String currentBlockId;
  final int currentChapterIndex;
  final int currentBlockIndex;
  final double progressPercentage;
  final int totalBlocksRead;
  final int totalBlocks;
  final DateTime lastReadAt;
  final int readingStreak; // days

  const ReadingProgress({
    required this.bookId,
    required this.currentChapterId,
    required this.currentBlockId,
    required this.currentChapterIndex,
    required this.currentBlockIndex,
    required this.progressPercentage,
    required this.totalBlocksRead,
    required this.totalBlocks,
    required this.lastReadAt,
    this.readingStreak = 0,
  });

  /// Check if reading is complete
  bool get isComplete => progressPercentage >= 100;

  /// Get estimated time remaining (assuming 2 min per block)
  int get estimatedMinutesRemaining =>
      ((totalBlocks - totalBlocksRead) * 2).clamp(0, double.infinity).toInt();

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'currentChapterId': currentChapterId,
      'currentBlockId': currentBlockId,
      'currentChapterIndex': currentChapterIndex,
      'currentBlockIndex': currentBlockIndex,
      'progressPercentage': progressPercentage,
      'totalBlocksRead': totalBlocksRead,
      'totalBlocks': totalBlocks,
      'lastReadAt': lastReadAt.toIso8601String(),
      'readingStreak': readingStreak,
    };
  }

  /// Create from JSON
  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['bookId'] as String,
      currentChapterId: json['currentChapterId'] as String,
      currentBlockId: json['currentBlockId'] as String,
      currentChapterIndex: json['currentChapterIndex'] as int,
      currentBlockIndex: json['currentBlockIndex'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      totalBlocksRead: json['totalBlocksRead'] as int,
      totalBlocks: json['totalBlocks'] as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      readingStreak: json['readingStreak'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  ReadingProgress copyWith({
    String? bookId,
    String? currentChapterId,
    String? currentBlockId,
    int? currentChapterIndex,
    int? currentBlockIndex,
    double? progressPercentage,
    int? totalBlocksRead,
    int? totalBlocks,
    DateTime? lastReadAt,
    int? readingStreak,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      currentBlockId: currentBlockId ?? this.currentBlockId,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentBlockIndex: currentBlockIndex ?? this.currentBlockIndex,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      totalBlocksRead: totalBlocksRead ?? this.totalBlocksRead,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingStreak: readingStreak ?? this.readingStreak,
    );
  }

  /// Create initial progress for a new book
  factory ReadingProgress.initial({
    required String bookId,
    required String firstChapterId,
    required String firstBlockId,
    required int totalBlocks,
  }) {
    return ReadingProgress(
      bookId: bookId,
      currentChapterId: firstChapterId,
      currentBlockId: firstBlockId,
      currentChapterIndex: 0,
      currentBlockIndex: 0,
      progressPercentage: 0,
      totalBlocksRead: 0,
      totalBlocks: totalBlocks,
      lastReadAt: DateTime.now(),
      readingStreak: 1,
    );
  }
}
