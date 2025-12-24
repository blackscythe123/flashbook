/// Bookmark model for saving reading positions and highlights.
class Bookmark {
  final String id;
  final String bookId;
  final String chapterId;
  final String blockId;
  final BookmarkType type;
  final String? highlightText;
  final String? note;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.blockId,
    required this.type,
    this.highlightText,
    this.note,
    required this.createdAt,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'blockId': blockId,
      'type': type.name,
      'highlightText': highlightText,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterId: json['chapterId'] as String,
      blockId: json['blockId'] as String,
      type: BookmarkType.values.byName(json['type'] as String),
      highlightText: json['highlightText'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Bookmark copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? blockId,
    BookmarkType? type,
    String? highlightText,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      blockId: blockId ?? this.blockId,
      type: type ?? this.type,
      highlightText: highlightText ?? this.highlightText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Type of bookmark
enum BookmarkType {
  /// Position marker - to resume reading
  position,

  /// Highlighted text
  highlight,
}
