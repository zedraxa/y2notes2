import 'package:flutter/material.dart';

/// Effect-specific theming values accessible from BuildContext.
class EffectsThemeData {
  const EffectsThemeData({
    required this.particleBaseColor,
    required this.glowBaseColor,
    required this.shimmerBaseColor,
    required this.trailOpacity,
    required this.bloomOpacity,
    required this.glowLayers,
  });

  final Color particleBaseColor;
  final Color glowBaseColor;
  final Color shimmerBaseColor;
  final double trailOpacity;
  final double bloomOpacity;
  final int glowLayers;

  static const light = EffectsThemeData(
    particleBaseColor: Color(0xFF4A90D9),
    glowBaseColor: Color(0xFFFFD700),
    shimmerBaseColor: Color(0xFFE8F4FD),
    trailOpacity: 0.65,
    bloomOpacity: 0.20,
    glowLayers: 3,
  );

  static const dark = EffectsThemeData(
    particleBaseColor: Color(0xFF64B5F6),
    glowBaseColor: Color(0xFFFFE57F),
    shimmerBaseColor: Color(0xFF1A3A5C),
    trailOpacity: 0.75,
    bloomOpacity: 0.25,
    glowLayers: 3,
  );
}
