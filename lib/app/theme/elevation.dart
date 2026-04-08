import 'package:flutter/material.dart';

/// Apple-style elevation and shadow system.
///
/// iOS and macOS use subtle shadows to create depth hierarchy.
/// This class provides elevation levels that match Apple's design language:
/// - Lighter, softer shadows than Material Design
/// - Multiple shadow layers for realism
/// - Consistent blur and spread ratios
class AppleElevation {
  AppleElevation._();

  // ─── Elevation Levels ────────────────────────────────────────────────────

  /// No shadow — for flat elements.
  static const double level0 = 0;

  /// Minimal elevation — for subtle lift (e.g., hovered buttons).
  static const double level1 = 1;

  /// Low elevation — for floating elements (e.g., cards, chips).
  static const double level2 = 2;

  /// Medium elevation — for panels, toolbars.
  static const double level3 = 4;

  /// High elevation — for sheets, popovers.
  static const double level4 = 8;

  /// Very high elevation — for modals, dialogs.
  static const double level5 = 16;

  /// Maximum elevation — for the highest priority overlays.
  static const double level6 = 24;

  // ─── Shadow Styles ───────────────────────────────────────────────────────

  /// Returns Apple-style shadow for the given elevation level.
  ///
  /// Apple uses dual-layer shadows:
  /// - Upper shadow: soft, large blur
  /// - Lower shadow: tighter, closer to element
  static List<BoxShadow> shadowFor(double elevation,
      {Color? color, bool isDark = false}) {
    if (elevation == 0) return [];

    final shadowColor = color ??
        (isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.black.withOpacity(0.15));

    final ambientColor = shadowColor.withOpacity(
      (isDark ? 0.3 : 0.1) * (elevation / level6),
    );

    final directionalColor = shadowColor.withOpacity(
      (isDark ? 0.5 : 0.15) * (elevation / level6),
    );

    return [
      // Ambient shadow (soft, diffused)
      BoxShadow(
        color: ambientColor,
        blurRadius: elevation * 2,
        spreadRadius: 0,
        offset: Offset(0, elevation * 0.5),
      ),
      // Directional shadow (sharper, defines depth)
      BoxShadow(
        color: directionalColor,
        blurRadius: elevation,
        spreadRadius: -elevation * 0.2,
        offset: Offset(0, elevation * 0.8),
      ),
    ];
  }

  // ─── Preset Shadow Styles ────────────────────────────────────────────────

  /// Subtle shadow for cards and buttons.
  static List<BoxShadow> get card => shadowFor(level2);

  /// Shadow for floating action buttons.
  static List<BoxShadow> get fab => shadowFor(level3);

  /// Shadow for toolbars and app bars.
  static List<BoxShadow> get toolbar => shadowFor(level1);

  /// Shadow for bottom sheets.
  static List<BoxShadow> get bottomSheet => shadowFor(level5);

  /// Shadow for modal dialogs.
  static List<BoxShadow> get dialog => shadowFor(level5);

  /// Shadow for dropdown menus and popovers.
  static List<BoxShadow> get menu => shadowFor(level4);

  /// Shadow for tooltips.
  static List<BoxShadow> get tooltip => shadowFor(level3);

  // ─── Dark Mode Variants ──────────────────────────────────────────────────

  /// Card shadow for dark mode.
  static List<BoxShadow> get cardDark => shadowFor(level2, isDark: true);

  /// FAB shadow for dark mode.
  static List<BoxShadow> get fabDark => shadowFor(level3, isDark: true);

  /// Bottom sheet shadow for dark mode.
  static List<BoxShadow> get bottomSheetDark =>
      shadowFor(level5, isDark: true);

  /// Dialog shadow for dark mode.
  static List<BoxShadow> get dialogDark => shadowFor(level5, isDark: true);

  /// Menu shadow for dark mode.
  static List<BoxShadow> get menuDark => shadowFor(level4, isDark: true);
}

/// Spacing scale based on 8pt grid system (Apple standard).
///
/// Apple uses consistent 8pt increments for most spacing,
/// with occasional 4pt adjustments for fine-tuning.
class AppleSpacing {
  AppleSpacing._();

  // ─── Base Units ──────────────────────────────────────────────────────────

  /// 4pt — for tight spacing, fine adjustments
  static const double xs = 4.0;

  /// 8pt — minimum touch target spacing
  static const double sm = 8.0;

  /// 12pt — compact spacing
  static const double md = 12.0;

  /// 16pt — standard spacing (most common)
  static const double lg = 16.0;

  /// 20pt — comfortable spacing
  static const double xl = 20.0;

  /// 24pt — generous spacing
  static const double xxl = 24.0;

  /// 32pt — section spacing
  static const double xxxl = 32.0;

  /// 40pt — major section breaks
  static const double huge = 40.0;

  /// 48pt — page-level spacing
  static const double massive = 48.0;

  // ─── Common Patterns ─────────────────────────────────────────────────────

  /// Horizontal padding for list items (iOS standard)
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Padding for cards
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Padding for bottom sheets
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(
    lg,
    md,
    lg,
    xl,
  );

  /// Padding for dialogs
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  /// Safe area insets (for content that needs to avoid system UI)
  static const EdgeInsets safeAreaInsets = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Page margins for main content
  static const EdgeInsets pageMargins = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xxl,
  );
}

/// Corner radius values matching iOS design patterns.
class AppleRadius {
  AppleRadius._();

  /// Subtle rounding — 4pt
  static const double xs = 4.0;

  /// Small rounding — 8pt (e.g., chips, small buttons)
  static const double sm = 8.0;

  /// Medium rounding — 12pt (e.g., text fields, small cards)
  static const double md = 12.0;

  /// Standard rounding — 16pt (e.g., cards, most UI elements)
  static const double lg = 16.0;

  /// Large rounding — 20pt (e.g., bottom sheets, large cards)
  static const double xl = 20.0;

  /// Extra large rounding — 24pt (e.g., modals)
  static const double xxl = 24.0;

  /// Pill-shaped — 999pt (fully rounded ends)
  static const double pill = 999.0;

  // ─── Common BorderRadius ─────────────────────────────────────────────────

  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);

  /// Top-only rounding for bottom sheets
  static BorderRadius get bottomSheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(xl));

  /// Top-only rounding for modals
  static BorderRadius get modalRadius =>
      const BorderRadius.vertical(top: Radius.circular(xxl));
}
