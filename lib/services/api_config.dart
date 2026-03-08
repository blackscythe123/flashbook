import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Manages API configuration including backend URL.
class ApiConfig extends ChangeNotifier {
  static const String _backendUrlKey = 'backend_url';
  static const String prodUrl =
      "https://lnvkdza1u2.execute-api.ap-south-1.amazonaws.com/Prod/";

  String _backendUrl = prodUrl;
  bool _isConnected = false;
  bool _isChecking = false;
  String? _lastError;

  /// Current backend URL (always live)
  String get backendUrl => _backendUrl;

  /// Live API is permanently enabled.
  bool get isDemoMode => false;

  /// Whether backend connection is verified
  bool get isConnected => _isConnected;

  /// Whether currently checking connection
  bool get isChecking => _isChecking;

  /// Last error message
  String? get lastError => _lastError;

  /// Full API base URL
  String get apiBaseUrl =>
      _backendUrl.endsWith('/')
          ? _backendUrl.substring(0, _backendUrl.length - 1)
          : _backendUrl;

  /// Initialize with hardcoded production URL.
  Future<void> initializeWithFallback() async {
    _isChecking = true;
    notifyListeners();

    try {
      debugPrint('ApiConfig: Testing connection to PROD_URL: $prodUrl');
      _backendUrl = prodUrl;
      final baseUrl = apiBaseUrl;

      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('ApiConfig: Connection successful!');
        _isConnected = true;
        _lastError = null;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiConfig: Connection failed ($e).');
      _isConnected = false;
      _lastError = 'Connection failed. Live API is required.';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Load saved backend URL from storage if available, otherwise use prod URL.
  Future<void> loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backendUrl = prefs.getString(_backendUrlKey) ?? prodUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load saved URL: $e');
    }
  }

  /// Set and save backend URL
  Future<void> setBackendUrl(String? url) async {
    _backendUrl = (url ?? prodUrl).replaceAll(RegExp(r'\s+'), '');
    if (_backendUrl.endsWith('.aop')) {
      _backendUrl = _backendUrl.replaceAll('.aop', '.app');
    }

    _isConnected = false;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backendUrlKey, _backendUrl);
    } catch (e) {
      debugPrint('Failed to save URL: $e');
    }

    notifyListeners();
  }

  /// Update connection status
  void setConnectionStatus({required bool connected, String? error}) {
    _isConnected = connected;
    _lastError = error;
    _isChecking = false;
    notifyListeners();
  }

  /// Set checking state
  void setChecking(bool checking) {
    _isChecking = checking;
    notifyListeners();
  }

  /// Reset URL to production API.
  Future<void> clearAndUseDemo() async {
    await setBackendUrl(prodUrl);
    _isConnected = false;
    _lastError = null;
    notifyListeners();
  }
}
