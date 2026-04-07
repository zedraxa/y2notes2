import 'package:flutter/material.dart';
import 'package:biscuitse/app/theme/colors.dart';

/// GoodNotes-inspired clean, warm, minimal theme.
class AppTheme {
  AppTheme._();

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
          background: AppColors.background,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.toolbarBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        textTheme: _buildTextTheme(AppColors.textPrimary),
        dividerColor: AppColors.toolbarBorder,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.toolbarBorder,
          overlayColor: AppColors.accent.withOpacity(0.1),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.toolbarBorder,
          ),
        ),
        extensions: const [EffectsTheme.light],
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          background: AppColors.darkBackground,
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        textTheme: _buildTextTheme(AppColors.darkTextPrimary),
        dividerColor: AppColors.darkDivider,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.darkDivider,
          overlayColor: AppColors.accent.withOpacity(0.1),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? AppColors.accent
                : AppColors.darkTextSecondary,
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.darkDivider,
          ),
        ),
        extensions: const [EffectsTheme.dark],
      );

  static TextTheme _buildTextTheme(Color primary) => TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: primary),
        bodyMedium: TextStyle(fontSize: 14, color: primary),
        bodySmall: TextStyle(
          fontSize: 12,
          color: primary.withOpacity(0.7),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
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
    particleColor: Color(0xFF4A90D9),
    glowColor: Color(0xFFFFD700),
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
