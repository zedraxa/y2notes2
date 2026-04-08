import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';

/// Apple-inspired modern, minimal theme with clean typography, generous
/// spacing, and layered surfaces.
class AppTheme {
  AppTheme._();

  // ─── Corner radii ─────────────────────────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
          surface: AppColors.surface,
          primary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.accent,
          size: 22,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimary),
        dividerColor: AppColors.toolbarBorder,
        dividerTheme: const DividerThemeData(
          color: AppColors.toolbarBorder,
          thickness: 0.5,
          space: 0.5,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          highlightElevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          minLeadingWidth: 28,
          visualDensity: VisualDensity.standard,
        ),
        dialogTheme: DialogThemeData(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXL),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          dragHandleColor: AppColors.textSecondary.withOpacity(0.3),
          showDragHandle: true,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.accent.withOpacity(0.15),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          side: const BorderSide(color: AppColors.toolbarBorder, width: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 15,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.systemGreen
                : AppColors.toolbarBorder,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: Colors.white,
          inactiveTrackColor: AppColors.toolbarBorder,
          overlayColor: AppColors.accent.withOpacity(0.08),
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 14,
            elevation: 2,
          ),
          trackHeight: 4,
        ),
        popupMenuTheme: PopupMenuThemeData(
          elevation: 4,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.accent,
          linearTrackColor: AppColors.toolbarBorder,
        ),
        extensions: const [EffectsTheme.light],
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
          primary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.accent,
          size: 22,
        ),
        textTheme: _buildTextTheme(AppColors.darkTextPrimary),
        dividerColor: AppColors.darkDivider,
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 0.5,
          space: 0.5,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          highlightElevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          minLeadingWidth: 28,
          visualDensity: VisualDensity.standard,
        ),
        dialogTheme: DialogThemeData(
          elevation: 0,
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXL),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          dragHandleColor: AppColors.darkTextSecondary.withOpacity(0.3),
          showDragHandle: true,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedColor: AppColors.accent.withOpacity(0.2),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          side: const BorderSide(color: AppColors.darkDivider, width: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          hintStyle: TextStyle(
            color: AppColors.darkTextSecondary.withOpacity(0.6),
            fontSize: 15,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.systemGreen
                : AppColors.darkDivider,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: Colors.white,
          inactiveTrackColor: AppColors.darkDivider,
          overlayColor: AppColors.accent.withOpacity(0.08),
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 14,
            elevation: 2,
          ),
          trackHeight: 4,
        ),
        popupMenuTheme: PopupMenuThemeData(
          elevation: 4,
          color: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          backgroundColor: const Color(0xFF2C2C2E),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.accent,
          linearTrackColor: AppColors.darkDivider,
        ),
        extensions: const [EffectsTheme.dark],
      );

  /// Apple-style typography with negative letter-spacing and SF-Pro-like
  /// weights.
  static TextTheme _buildTextTheme(Color primary) => TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.7,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.4,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: -0.4,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: primary,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: primary.withOpacity(0.6),
          letterSpacing: -0.1,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primary.withOpacity(0.7),
          letterSpacing: -0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: primary.withOpacity(0.5),
          letterSpacing: 0.1,
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
    particleColor: Color(0xFF007AFF),
    glowColor: Color(0xFFFFCC00),
    shimmerColor: Color(0xFFE8F4FD),
  );

  static const dark = EffectsTheme(
    particleColor: Color(0xFF64B5F6),
    glowColor: Color(0xFFFFE57F),
    shimmerColor: Color(0xFF1A3A5C),
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
