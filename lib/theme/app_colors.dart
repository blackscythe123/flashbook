import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // -- Backgrounds ------------------------
  static const Color background  = Color(0xFF000000); // Pure black
  static const Color surface     = Color(0xFF111111); // Cards, sheets
  static const Color elevated    = Color(0xFF1A1A1A); // Inputs, nav items
  static const Color overlay     = Color(0xFF222222); // Modals, drawers

  // -- Accent -----------------------------
  static const Color accent      = Color(0xFFC41E24); // Primary CTA red
  static const Color accentDim   = Color(0x33C41E24); // 20% red (badges, bg tints)
  static const Color accentHover = Color(0xFFD42028); // Button press state

  // -- Text -------------------------------
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted     = Color(0xFF444444);
  static const Color textDisabled  = Color(0xFF2A2A2A);

  // -- Utility ----------------------------
  static const Color divider  = Color(0xFF1F1F1F);
  static const Color border   = Color(0xFF2A2A2A);
  static const Color success  = Color(0xFF22C55E);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFC41E24);

  // -- Semantic ---------------------------
  static const Color cardBackground   = surface;
  static const Color inputBackground  = elevated;
  static const Color navBackground    = surface;
  static const Color shimmerBase      = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);
}
