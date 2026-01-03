/// Note model representing a user's note on a learning card.
/// Notes are tied to specific cards in books and stored locally.
class Note {
  final String id;
  final String bookId;
  final int cardIndex; // Position of card in the feed
  final String cardTitle; // The card's headline
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.bookId,
    required this.cardIndex,
    required this.cardTitle,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  Note copyWith({
    String? id,
    String? bookId,
    int? cardIndex,
    String? cardTitle,
    String? noteText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cardIndex: cardIndex ?? this.cardIndex,
      cardTitle: cardTitle ?? this.cardTitle,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'cardIndex': cardIndex,
      'cardTitle': cardTitle,
      'noteText': noteText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      cardIndex: json['cardIndex'] as int,
      cardTitle: json['cardTitle'] as String,
      noteText: json['noteText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() => 'Note(id: $id, bookId: $bookId, cardIndex: $cardIndex)';
}
