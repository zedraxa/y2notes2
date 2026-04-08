import 'package:flutter/material.dart';

/// Biscuits — warm, approachable color palette with a biscuit/cookie motif.
///
/// Light mode: cream/warm backgrounds, golden accent, rich brown text.
/// Dark mode: deep cocoa backgrounds, warm charcoal surfaces, cream text.
abstract class AppColors {
  AppColors._();

  // ─── Light Mode ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF3E8);
  static const Color toolbarBg = Color(0xFFFFFBF6);
  static const Color toolbarBorder = Color(0xFFEDE3D8);
  static const Color textPrimary = Color(0xFF3D2B1F);
  static const Color textSecondary = Color(0xFF8C7B6B);
  static const Color accent = Color(0xFFD4A574);
  static const Color accentDark = Color(0xFFB8864E);
  static const Color success = Color(0xFF6B9E78);
  static const Color error = Color(0xFFCC6B5A);

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1210);
  static const Color darkSurface = Color(0xFF2C2420);
  static const Color darkSurfaceVariant = Color(0xFF362E28);
  static const Color darkToolbarBg = Color(0xFF3A302A);
  static const Color darkDivider = Color(0xFF4A3F38);
  static const Color darkTextPrimary = Color(0xFFF5E6D3);
  static const Color darkTextSecondary = Color(0xFFA89888);
  static const Color darkAccent = Color(0xFFDEB887);
  static const Color darkSuccess = Color(0xFF7DB88A);
  static const Color darkError = Color(0xFFE08070);

  // ─── Pen Colors ──────────────────────────────────────────────────────────
  static const List<Color> defaultPenColors = [
    Color(0xFF2D2D2D), // Near-black
    Color(0xFF1A56A0), // Classic blue
    Color(0xFFB22222), // Deep red
    Color(0xFF2E7D32), // Forest green
    Color(0xFF6A1B9A), // Deep purple
    Color(0xFFE65100), // Dark orange
    Color(0xFF00838F), // Teal
    Color(0xFFAD1457), // Deep pink
  ];

  // ─── Highlighter Colors ───────────────────────────────────────────────────
  static const List<Color> highlighterColors = [
    Color(0xCCFFEB3B), // Yellow
    Color(0xCC80DEEA), // Cyan
    Color(0xCCF48FB1), // Pink
    Color(0xCC80CBC4), // Green
    Color(0xCFFFCC80), // Orange
    Color(0xCCA5D6A7), // Sage
  ];

  // ─── Effect-specific Colors ───────────────────────────────────────────────
  static const Color neonBlue = Color(0xFF00BFFF);
  static const Color neonPink = Color(0xFFFF69B4);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonPurple = Color(0xFFBF5FFF);
  static const Color goldShimmer = Color(0xFFFFD700);
  static const Color silverShimmer = Color(0xFFC0C0C0);

  // ─── Canvas Background Colors ─────────────────────────────────────────────
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color canvasWarm = Color(0xFFFFFBF5);
  static const Color canvasGrid = Color(0xFFD0D0D0);
  static const Color canvasLine = Color(0xFFCFD8DC);
  static const Color canvasDot = Color(0xFFB0BEC5);
  static const Color canvasDarkBg = Color(0xFF1A1A2E);
  static const Color chalkboardGreen = Color(0xFF1A3A2A);
}
