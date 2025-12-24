/// Book model representing a book in the app.
/// Used for both public domain books and uploaded PDFs.
class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final List<Chapter> chapters;
  final BookSource source;
  final DateTime? addedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    required this.chapters,
    required this.source,
    this.addedAt,
  });

  /// Total number of learning blocks across all chapters
  int get totalBlocks => chapters.fold(0, (sum, ch) => sum + ch.blocks.length);

  /// Create a copy with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? description,
    List<Chapter>? chapters,
    BookSource? source,
    DateTime? addedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      chapters: chapters ?? this.chapters,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'source': source.name,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      chapters:
          (json['chapters'] as List)
              .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList(),
      source: BookSource.values.byName(json['source'] as String),
      addedAt:
          json['addedAt'] != null
              ? DateTime.parse(json['addedAt'] as String)
              : null,
    );
  }
}

/// Chapter within a book
class Chapter {
  final String id;
  final String title;
  final int number;
  final List<LearningBlock> blocks;

  const Chapter({
    required this.id,
    required this.title,
    required this.number,
    required this.blocks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'number': number,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      number: json['number'] as int,
      blocks:
          (json['blocks'] as List)
              .map((b) => LearningBlock.fromJson(b as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// A single learning block (swipeable card in the feed)
class LearningBlock {
  final String id;
  final String? tag;
  final String headline;
  final String content;
  final String? quote;
  final String? takeaway;
  final String? imageUrl;
  final int estimatedReadTime; // in seconds

  const LearningBlock({
    required this.id,
    this.tag,
    required this.headline,
    required this.content,
    this.quote,
    this.takeaway,
    this.imageUrl,
    this.estimatedReadTime = 120,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'headline': headline,
      'content': content,
      'quote': quote,
      'takeaway': takeaway,
      'imageUrl': imageUrl,
      'estimatedReadTime': estimatedReadTime,
    };
  }

  factory LearningBlock.fromJson(Map<String, dynamic> json) {
    return LearningBlock(
      id: json['id'] as String,
      tag: json['tag'] as String?,
      headline: json['headline'] as String,
      content: json['content'] as String,
      quote: json['quote'] as String?,
      takeaway: json['takeaway'] as String?,
      imageUrl: json['imageUrl'] as String?,
      estimatedReadTime: json['estimatedReadTime'] as int? ?? 120,
    );
  }
}

/// Source of the book
enum BookSource { publicDomain, uploadedPdf }
