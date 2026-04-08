import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Biscuits — modern, Apple-ish theme with warm biscuit palette.
///
/// Design principles:
/// - Generous padding and rounded corners (Cupertino-inspired)
/// - 44pt minimum touch targets
/// - Pill-shaped buttons with subtle shadows
/// - Clean typography with SF Pro-like weights
class AppTheme {
  AppTheme._();

  // ─── Shared constants ─────────────────────────────────────────────────────
  static const double _buttonRadius = 22;
  static const double _cardRadius = 16;
  static const double _inputRadius = 12;
  static const double _minButtonHeight = 44;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.toolbarBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimary),
        dividerColor: AppColors.toolbarBorder,
        cardTheme: CardTheme(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(
              color: AppColors.toolbarBorder.withOpacity(0.5),
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(64, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            minimumSize: const Size(64, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            minimumSize: const Size(44, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          minVerticalPadding: 12,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.toolbarBorder,
          overlayColor: AppColors.accent.withOpacity(0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textSecondary,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.toolbarBorder,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.accent.withOpacity(0.15),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          elevation: 8,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        extensions: const [EffectsTheme.light],
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkAccent,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
          error: AppColors.darkError,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          centerTitle: true,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 22,
        ),
        textTheme: _buildTextTheme(AppColors.darkTextPrimary),
        dividerColor: AppColors.darkDivider,
        cardTheme: CardTheme(
          elevation: 0,
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(
              color: AppColors.darkDivider.withOpacity(0.5),
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkAccent,
            foregroundColor: AppColors.darkBackground,
            minimumSize: const Size(64, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkAccent,
            minimumSize: const Size(64, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            side: const BorderSide(color: AppColors.darkAccent, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.darkAccent,
            minimumSize: const Size(44, _minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.darkAccent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          minVerticalPadding: 12,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.darkAccent,
          thumbColor: AppColors.darkAccent,
          inactiveTrackColor: AppColors.darkDivider,
          overlayColor: AppColors.darkAccent.withOpacity(0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.darkBackground
                : AppColors.darkTextSecondary,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.darkAccent
                : AppColors.darkDivider,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurfaceVariant,
          selectedColor: AppColors.darkAccent.withOpacity(0.2),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          elevation: 8,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkTextPrimary,
          contentTextStyle: const TextStyle(
            color: AppColors.darkBackground,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        extensions: const [EffectsTheme.dark],
      );

  static TextTheme _buildTextTheme(Color primary) => TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: primary,
          letterSpacing: -0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyLarge: TextStyle(fontSize: 17, color: primary, height: 1.4),
        bodyMedium: TextStyle(fontSize: 15, color: primary, height: 1.4),
        bodySmall: TextStyle(
          fontSize: 13,
          color: primary.withOpacity(0.7),
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primary.withOpacity(0.7),
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: primary.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      );
}

/// Effect-specific theming extension.
class EffectsTheme extends ThemeExtension<EffectsTheme> {
  const EffectsTheme({
    required this.particleColor,
    required this.glowColor,
    required this.shimmerColor,
  });

  final Color particleColor;
  final Color glowColor;
  final Color shimmerColor;

  static const light = EffectsTheme(
    particleColor: Color(0xFFD4A574),
    glowColor: Color(0xFFFFD700),
    shimmerColor: Color(0xFFFFF3E8),
  );

  static const dark = EffectsTheme(
    particleColor: Color(0xFFDEB887),
    glowColor: Color(0xFFFFE57F),
    shimmerColor: Color(0xFF362E28),
  );

  @override
  EffectsTheme copyWith({
    Color? particleColor,
    Color? glowColor,
    Color? shimmerColor,
  }) =>
      EffectsTheme(
        particleColor: particleColor ?? this.particleColor,
        glowColor: glowColor ?? this.glowColor,
        shimmerColor: shimmerColor ?? this.shimmerColor,
      );

  @override
  EffectsTheme lerp(EffectsTheme? other, double t) {
    if (other == null) return this;
    return EffectsTheme(
      particleColor: Color.lerp(particleColor, other.particleColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      shimmerColor: Color.lerp(shimmerColor, other.shimmerColor, t)!,
    );
  }
}
