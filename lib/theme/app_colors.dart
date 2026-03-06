import 'package:flutter/material.dart';

/// Modern reel-app color palette — vibrant, bold, scroll-friendly.
class AppColors {
  // ── Primary brand ──
  static const Color primary = Color(0xFF6366F1);       // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5);    // Indigo 600

  // ── Secondary ──
  static const Color secondary = Color(0xFF8B5CF6);      // Violet 500
  static const Color secondaryLight = Color(0xFFA78BFA);  // Violet 400

  // ── Background ──
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0F172A);   // Slate 900

  // ── Surface / Card ──
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);      // Slate 800

  // ── Paper (legacy compat) ──
  static const Color paperLight = Color(0xFFF1F5F9);       // Slate 100
  static const Color paperDark = Color(0xFF1E293B);

  // ── Text ──
  static const Color inkLight = Color(0xFF0F172A);          // Slate 900
  static const Color inkDark = Color(0xFFF1F5F9);           // Slate 100
  static const Color textMuted = Color(0xFF64748B);          // Slate 500
  static const Color textMutedDark = Color(0xFF94A3B8);      // Slate 400

  // ── Accent ──
  static const Color accentSage = Color(0xFF10B981);   // Emerald 500
  static const Color accentClay = Color(0xFFF97316);    // Orange 500
  static const Color accentGold = Color(0xFFF59E0B);    // Amber 500
  static const Color accentWarm = Color(0xFFEC4899);     // Pink 500
  static const Color accentBlue = Color(0xFF3B82F6);     // Blue 500

  // ── Functional ──
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Gradients ──
  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientEnd = Color(0xFF8B5CF6);

  // ── Nav / Chrome ──
  static const Color navBarLight = Color(0xFFFFFFFF);
  static const Color navBarDark = Color(0xFF0F172A);
}
