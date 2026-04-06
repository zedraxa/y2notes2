import 'package:flutter/material.dart';

/// GoodNotes-inspired warm, muted color palette.
abstract class AppColors {
  AppColors._();

  // ─── Light Mode ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F0EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color toolbarBg = Color(0xFFF8F6F3);
  static const Color toolbarBorder = Color(0xFFE8E4DF);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF8A8580);
  static const Color accent = Color(0xFF4A90D9);

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkToolbarBg = Color(0xFF3A3A3C);
  static const Color darkDivider = Color(0xFF48484A);
  static const Color darkTextPrimary = Color(0xFFF2F2F7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);

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
