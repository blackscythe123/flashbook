import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Authentication states
enum AuthState { initial, unauthenticated, authenticated, needsVerification }

/// State provider for authentication.
/// Uses CognitoAuthService for real AWS Cognito login.
class AuthProvider extends ChangeNotifier {
  CognitoAuthService? _authService;

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  AuthState _authState = AuthState.initial;
  String? _pendingVerificationEmail;

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  String? get errorMessage => _errorMessage;
  String get userId => _user?.id ?? 'anonymous';
  AuthState get authState => _authState;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get idToken => _authService?.idToken;

  /// Inject the API config so we can create the auth service
  void setApiConfig(ApiConfig apiConfig) {
    _authService = CognitoAuthService(apiConfig);
  }

  /// Initialize — try to restore previous session
  Future<void> initialize() async {
    if (_authService == null) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final restored = await _authService!.tryRestoreSession();
      if (restored) {
        _user = _authService!.currentUser;
        _authState = AuthState.authenticated;
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      debugPrint('AuthProvider: init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email/password via Cognito
  Future<bool> signInWithEmail(String email, String password) async {
    if (_authService == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService!.signInWithEmail(email, password);
      _authState = AuthState.authenticated;
      _pendingVerificationEmail = null;
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == '__unverified__') {
        _authState = AuthState.needsVerification;
        _pendingVerificationEmail = email;
        _errorMessage = null;
      } else {
        _authState = AuthState.unauthenticated;
        _errorMessage = msg;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create account via Cognito (triggers verification email)
  Future<bool> createAccount(String email, String password) async {
    if (_authService == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService!.createAccount(email, password);
      _pendingVerificationEmail = email;
      _authState = AuthState.needsVerification;
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('already exists') ||
          msg.contains('UsernameExistsException') ||
          msg.contains('409')) {
        _authState = AuthState.unauthenticated;
        _pendingVerificationEmail = null;
        _errorMessage = 'An account with this email already exists.';
      } else {
        _authState = AuthState.unauthenticated;
        _errorMessage = msg;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify email with code
  Future<bool> verifyEmail(String code) async {
    if (_authService == null || _pendingVerificationEmail == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService!.verifyEmail(_pendingVerificationEmail!, code);
      _authState = AuthState.unauthenticated; // Go to login after verify
      _pendingVerificationEmail = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      await _authService?.signOut();
      _user = null;
      _authState = AuthState.unauthenticated;
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

  /// Reset state back to login (from verification screen)
  void resetToLogin() {
    _authState = AuthState.unauthenticated;
    _pendingVerificationEmail = null;
    _errorMessage = null;
    notifyListeners();
  }
}
