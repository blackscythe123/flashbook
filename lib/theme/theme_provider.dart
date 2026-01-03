import 'package:flutter/material.dart';

/// Provider for managing theme mode (light/dark/system).
/// Extends [ChangeNotifier] to notify listeners when theme changes.
class ThemeProvider extends ChangeNotifier {
  /// Private theme mode variable, defaulting to system theme.
  ThemeMode _themeMode = ThemeMode.system;

  /// Getter for the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Check if dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggle between light and dark theme modes.
  ///
  /// [isDark] - If true, switches to dark mode; if false, switches to light mode.
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Set theme mode to a specific value.
  ///
  /// [mode] - The [ThemeMode] to set (light, dark, or system).
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
