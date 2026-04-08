import 'package:flutter/material.dart';

/// Apple-inspired clean, modern color palette following Human Interface
/// Guidelines aesthetics — system-level grays, vibrant accent, generous
/// contrast, and subtle layering.
abstract class AppColors {
  AppColors._();

  // ─── Light Mode ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF2F2F7); // iOS system grouped bg
  static const Color surface = Color(0xFFFFFFFF);
  static const Color toolbarBg = Color(0xFFF9F9F9);
  static const Color toolbarBorder = Color(0xFFE5E5EA); // iOS separator
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93); // iOS secondary label
  static const Color accent = Color(0xFF007AFF); // iOS system blue

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000); // Pure black (OLED)
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS elevated surface
  static const Color darkToolbarBg = Color(0xFF2C2C2E);
  static const Color darkDivider = Color(0xFF38383A); // iOS dark separator
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);

  // ─── System Colors (Apple palette) ────────────────────────────────────────
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemPink = Color(0xFFFF2D55);

  // ─── Grouped Section Background (iOS Settings-style) ──────────────────────
  static const Color groupedBackground = Color(0xFFF2F2F7);
  static const Color groupedSurface = Color(0xFFFFFFFF);
  static const Color darkGroupedBackground = Color(0xFF000000);
  static const Color darkGroupedSurface = Color(0xFF1C1C1E);

  // ─── System Grouped Secondary (iOS search bars, tertiary fills) ───────────
  static const Color systemFill = Color(0xFFE5E5EA);
  static const Color darkSystemFill = Color(0xFF2C2C2E);
  static const Color systemGroupedSecondaryBg = Color(0xFFF2F2F7);

  // ─── Pen Colors ──────────────────────────────────────────────────────────
  static const List<Color> defaultPenColors = [
    Color(0xFF000000), // Black
    Color(0xFF007AFF), // System blue
    Color(0xFFFF3B30), // System red
    Color(0xFF34C759), // System green
    Color(0xFF5856D6), // System indigo
    Color(0xFFFF9500), // System orange
    Color(0xFF5AC8FA), // System teal
    Color(0xFFFF2D55), // System pink
  ];

  // ─── Highlighter Colors ───────────────────────────────────────────────────
  static const List<Color> highlighterColors = [
    Color(0xCCFFCC00), // Yellow
    Color(0xCC5AC8FA), // Teal
    Color(0xCCFF2D55), // Pink
    Color(0xCC34C759), // Green
    Color(0xCCFF9500), // Orange
    Color(0xCC30D158), // Mint
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
  static const Color canvasGrid = Color(0xFFD1D1D6);
  static const Color canvasLine = Color(0xFFC7C7CC);
  static const Color canvasDot = Color(0xFFAEAEB2);
  static const Color canvasDarkBg = Color(0xFF1C1C1E);
  static const Color chalkboardGreen = Color(0xFF1A3A2A);
}
