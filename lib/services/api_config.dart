import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages API configuration including backend URL.
/// Supports both demo mode (mock data) and live mode (real backend).
class ApiConfig extends ChangeNotifier {
  static const String _backendUrlKey = 'backend_url';

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

  /// Load saved backend URL from storage
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
