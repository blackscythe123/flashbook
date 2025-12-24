import 'dart:async';
import '../models/models.dart';

/// Abstract authentication service interface.
/// For hackathon demo, we use MockAuthService.
abstract class AuthService {
  /// Stream of authentication state changes
  Stream<AppUser?> get authStateChanges;

  /// Get current user
  AppUser? get currentUser;

  /// Sign in anonymously (for quick demo access)
  Future<AppUser?> signInAnonymously();

  /// Sign in with email and password
  Future<AppUser?> signInWithEmail(String email, String password);

  /// Create account with email and password
  Future<AppUser?> createAccount(String email, String password);

  /// Sign out
  Future<void> signOut();
}

/// Mock auth service for hackathon demo.
/// No Firebase dependency - works fully offline.
class MockAuthService implements AuthService {
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser?> signInAnonymously() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = AppUser(
      id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      isPremium: false,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // For demo, any email/password works
    _currentUser = AppUser(
      id: 'user_${email.hashCode}',
      email: email,
      isAnonymous: false,
      isPremium: email.contains('premium'),
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser?> createAccount(String email, String password) async {
    // Same as sign in for demo
    return signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStateController.add(null);
  }

  /// Dispose the stream controller
  void dispose() {
    _authStateController.close();
  }
}
