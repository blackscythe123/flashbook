/// User model for app state and Firebase authentication.
class AppUser {
  final String id;
  final String? email;
  final bool isAnonymous;
  final bool isPremium;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.isAnonymous = true,
    this.isPremium = false,
    required this.createdAt,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'isAnonymous': isAnonymous,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    bool? isAnonymous,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
