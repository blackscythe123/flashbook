import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Flashbook is dark-only. Always returns dark.
  ThemeMode get themeMode => ThemeMode.dark;
  bool get isDarkMode => true;
}
