import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_config.dart';

/// Abstract authentication service interface.
abstract class AuthService {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  String? get idToken;
  Future<AppUser?> signInWithEmail(String email, String password);
  Future<AppUser?> createAccount(String email, String password);
  Future<bool> verifyEmail(String email, String code);
  Future<void> signOut();
  Future<bool> tryRestoreSession();
}

/// Cognito-backed auth service calling /auth/* Lambda endpoints.
class CognitoAuthService implements AuthService {
  final ApiConfig _apiConfig;
  AppUser? _currentUser;
  String? _idToken;
  String? _accessToken;
  String? _refreshToken;
  final _authStateController = StreamController<AppUser?>.broadcast();

  static const _keyIdToken = 'auth_id_token';
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyEmail = 'auth_email';

  CognitoAuthService(this._apiConfig);

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  String? get idToken => _idToken;

  String get _baseUrl => _apiConfig.apiBaseUrl;

  /// Try to restore a previous session from stored tokens.
  @override
  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRefresh = prefs.getString(_keyRefreshToken);
      final storedUserId = prefs.getString(_keyUserId);
      final storedEmail = prefs.getString(_keyEmail);

      if (storedRefresh == null || storedUserId == null) return false;

      // Try refreshing the token
      final base = _baseUrl;

      final resp = await http
          .post(
            Uri.parse('$base/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': storedRefresh}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _idToken = data['id_token'] as String?;
        _accessToken = data['access_token'] as String?;
        _refreshToken = storedRefresh; // refresh token stays the same
        _currentUser = AppUser(
          id: storedUserId,
          email: storedEmail,
          isAnonymous: false,
          createdAt: DateTime.now(),
        );
        await _persistTokens(storedEmail ?? '');
        _authStateController.add(_currentUser);
        return true;
      }
    } catch (e) {
      debugPrint('CognitoAuthService: Failed to restore session: $e');
    }
    return false;
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    final base = _baseUrl;

    final resp = await http
        .post(
          Uri.parse('$base/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final error = (data['error'] as String? ?? '').toLowerCase();

    if ((resp.statusCode == 403 || resp.statusCode == 400) &&
        (error.contains('not verified') ||
            error.contains('unconfirmed') ||
            error.contains('verify'))) {
      throw Exception('__unverified__');
    }

    if (resp.statusCode == 200) {
      _idToken = data['id_token'] as String?;
      _accessToken = data['access_token'] as String?;
      _refreshToken = data['refresh_token'] as String?;

      // Decode sub from id_token JWT payload
      final userId = _decodeSubFromJwt(_idToken!);
      _currentUser = AppUser(
        id: userId,
        email: email,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );
      await _persistTokens(email);
      _authStateController.add(_currentUser);
      return _currentUser;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  @override
  Future<AppUser?> createAccount(String email, String password) async {
    final base = _baseUrl;

    final resp = await http
        .post(
          Uri.parse('$base/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final error = data['error'] as String? ?? '';

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // Signup succeeded — user needs to verify email
      return null; // Signal that verification is needed
    } else if (resp.statusCode == 409 ||
        resp.statusCode == 400 ||
        error.contains('UsernameExistsException') ||
        error.toLowerCase().contains('already exists')) {
      throw Exception('An account with this email already exists.');
    } else {
      throw Exception(data['error'] ?? 'Signup failed');
    }
  }

  @override
  Future<bool> verifyEmail(String email, String code) async {
    final base = _baseUrl;

    final resp = await http
        .post(
          Uri.parse('$base/auth/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Verification failed');
    }
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _idToken = null;
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdToken);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    _authStateController.add(null);
  }

  Future<void> _persistTokens(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_idToken != null) await prefs.setString(_keyIdToken, _idToken!);
    if (_accessToken != null) {
      await prefs.setString(_keyAccessToken, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
    if (_currentUser != null) {
      await prefs.setString(_keyUserId, _currentUser!.id);
      await prefs.setString(_keyEmail, email);
    }
  }

  /// Decode the 'sub' claim from a JWT without verification (client-side only).
  String _decodeSubFromJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return 'unknown';
    // Normalize base64
    var payload = parts[1];
    payload = base64.normalize(payload);
    final decoded = utf8.decode(base64.decode(payload));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    return map['sub'] as String? ?? 'unknown';
  }

  void dispose() {
    _authStateController.close();
  }
}
