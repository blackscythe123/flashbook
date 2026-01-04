import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Manages API configuration including backend URL.
/// Supports both demo mode (mock data) and live mode (real backend).
class ApiConfig extends ChangeNotifier {
  static const String _backendUrlKey = 'backend_url';
  // TODO: Replace with your actual Render URL
  static const String PROD_URL = "https://flashbook-fepc.onrender.com";

  String? _backendUrl;
  bool _isConnected = false;
  bool _isChecking = false;
  String? _lastError;

  /// Current backend URL (null = demo mode)
  String? get backendUrl => _backendUrl;

  /// Whether we're in demo mode (no backend URL)
  bool get isDemoMode => _backendUrl == null || _backendUrl!.isEmpty;

  /// Whether backend connection is verified
  bool get isConnected => _isConnected;

  /// Whether currently checking connection
  bool get isChecking => _isChecking;

  /// Last error message
  String? get lastError => _lastError;

  /// Full API base URL
  String? get apiBaseUrl {
    if (_backendUrl == null || _backendUrl!.isEmpty) return null;
    // Ensure URL doesn't have trailing slash
    return _backendUrl!.endsWith('/')
        ? _backendUrl!.substring(0, _backendUrl!.length - 1)
        : _backendUrl;
  }

  /// Initialize with Hardcoded Prod URL, fallback to Demo if fails
  Future<void> initializeWithFallback() async {
    _isChecking = true;
    notifyListeners();

    try {
      debugPrint('ApiConfig: Testing connection to PROD_URL: $PROD_URL');

      // Handle potential trailing slash in PROD_URL
      final baseUrl =
          PROD_URL.endsWith('/')
              ? PROD_URL.substring(0, PROD_URL.length - 1)
              : PROD_URL;

      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('ApiConfig: Connection successful!');
        _backendUrl = PROD_URL;
        _isConnected = true;
        _lastError = null;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
        'ApiConfig: Connection failed ($e). Falling back to Demo Mode.',
      );
      _backendUrl = null; // Demo Mode
      _isConnected = false;
      _lastError = 'Connection failed. Using Demo Mode.';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Load saved backend URL from storage (Legacy - kept for reference or dev override)
  Future<void> loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backendUrl = prefs.getString(_backendUrlKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load saved URL: $e');
    }
  }

  /// Set and save backend URL
  Future<void> setBackendUrl(String? url) async {
    // Aggressively clean URL: remove ALL whitespace
    _backendUrl = url?.replaceAll(RegExp(r'\s+'), '');

    // Auto-fix common typos if possible (optional but helpful)
    if (_backendUrl != null) {
      if (_backendUrl!.endsWith('.aop')) {
        _backendUrl = _backendUrl!.replaceAll('.aop', '.app');
      }
    }

    _isConnected = false;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_backendUrl != null && _backendUrl!.isNotEmpty) {
        await prefs.setString(_backendUrlKey, _backendUrl!);
      } else {
        await prefs.remove(_backendUrlKey);
      }
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

  /// Clear URL and switch to demo mode
  Future<void> clearAndUseDemo() async {
    await setBackendUrl(null);
    _isConnected = false;
    _lastError = null;
    notifyListeners();
  }
}
