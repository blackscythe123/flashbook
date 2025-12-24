import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// State provider for authentication.
/// Manages user sign-in state and user data.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? MockAuthService();

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String get userId => _user?.id ?? 'anonymous';

  /// Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to get current user or sign in anonymously
      _user = _authService.currentUser;
      if (_user == null) {
        await signInAnonymously();
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in anonymously (for hackathon demo)
  Future<void> signInAnonymously() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInAnonymously();
    } catch (e) {
      _errorMessage = 'Failed to sign in: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(email, password);
      return true;
    } catch (e) {
      _errorMessage = 'Invalid email or password';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create account
  Future<bool> createAccount(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.createAccount(email, password);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create account';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
