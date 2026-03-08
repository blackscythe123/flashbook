/// Bookmark model for saving reading positions and highlights.
class Bookmark {
  final String id;
  final String bookId;
  final String bookTitle;
  final String chapterId;
  final String cardId;
  final String blockId;
  final String cardTitle;
  final String cardHeadline;
  final String cardType;
  final int cardIndex;
  final BookmarkType type;
  final String? highlightText;
  final String? note;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.chapterId,
    required this.cardId,
    required this.blockId,
    required this.cardTitle,
    required this.cardHeadline,
    required this.cardType,
    required this.cardIndex,
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
      'bookTitle': bookTitle,
      'chapterId': chapterId,
      'cardId': cardId,
      'blockId': blockId,
      'cardTitle': cardTitle,
      'cardHeadline': cardHeadline,
      'cardType': cardType,
      'cardIndex': cardIndex,
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
      bookTitle: (json['bookTitle'] as String?) ?? '',
      chapterId: (json['chapterId'] as String?) ?? '',
      cardId: (json['cardId'] as String?) ?? (json['blockId'] as String? ?? ''),
      blockId:
          (json['blockId'] as String?) ?? (json['cardId'] as String? ?? ''),
      cardTitle: (json['cardTitle'] as String?) ?? 'Saved card',
      cardHeadline: (json['cardHeadline'] as String?) ?? 'Saved card',
      cardType: (json['cardType'] as String?) ?? 'CARD',
      cardIndex: (json['cardIndex'] as int?) ?? 0,
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
    String? bookTitle,
    String? chapterId,
    String? cardId,
    String? blockId,
    String? cardTitle,
    String? cardHeadline,
    String? cardType,
    int? cardIndex,
    BookmarkType? type,
    String? highlightText,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      chapterId: chapterId ?? this.chapterId,
      cardId: cardId ?? this.cardId,
      blockId: blockId ?? this.blockId,
      cardTitle: cardTitle ?? this.cardTitle,
      cardHeadline: cardHeadline ?? this.cardHeadline,
      cardType: cardType ?? this.cardType,
      cardIndex: cardIndex ?? this.cardIndex,
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
