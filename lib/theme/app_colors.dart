import 'package:flutter/material.dart';

/// Flashbook dark-first color palette — premium, minimal, scroll-friendly.
class AppColors {
  // ── Backgrounds ──
  static const Color background = Color(0xFF1A1D2E);      // Dark navy
  static const Color surface = Color(0xFF252A3D);          // Card surface
  static const Color surfaceLight = Color(0xFF2D3347);     // Slightly lighter surface
  static const Color surfaceBorder = Color(0xFF3D4460);    // Subtle border

  // ── Primary (use SPARINGLY — CTAs only) ──
  static const Color primary = Color(0xFF6366F1);          // Indigo
  static const Color primaryLight = Color(0xFF818CF8);     // Indigo lighter
  static const Color primaryDark = Color(0xFF4F46E5);      // Indigo darker

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);      // White
  static const Color textSecondary = Color(0xFF9CA3AF);    // Gray 400
  static const Color textTertiary = Color(0xFF6B7280);     // Gray 500
  
  // Legacy compat aliases
  static const Color inkLight = Color(0xFF0F172A);
  static const Color inkDark = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);          // Emerald
  static const Color warning = Color(0xFFF59E0B);          // Amber
  static const Color error = Color(0xFFEF4444);            // Red

  // ── Accent (minimal usage) ──
  static const Color accentSage = Color(0xFF10B981);
  static const Color accentClay = Color(0xFFF97316);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentWarm = Color(0xFFEC4899);
  static const Color accentBlue = Color(0xFF3B82F6);

  // ── Legacy compat ──
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF1A1D2E);
  static const Color surfaceDark = Color(0xFF252A3D);
  static const Color paperLight = Color(0xFFF1F5F9);
  static const Color paperDark = Color(0xFF252A3D);
  static const Color navBarLight = Color(0xFFFFFFFF);
  static const Color navBarDark = Color(0xFF1A1D2E);
  static const Color surfaceColorLight = Color(0xFFFFFFFF);

  // ── NO MORE gradient constants — gradients only on CTAs ──
}
