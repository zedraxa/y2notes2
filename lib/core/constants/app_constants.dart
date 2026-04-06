/// Global application constants.
abstract class AppConstants {
  AppConstants._();

  // ─── Canvas ───────────────────────────────────────────────────────────────
  static const double defaultPageWidth = 1240.0;
  static const double defaultPageHeight = 1754.0; // A4 portrait at 150dpi
  static const double minZoom = 0.3;
  static const double maxZoom = 5.0;
  static const double defaultZoom = 1.0;

  // ─── Stroke ───────────────────────────────────────────────────────────────
  static const double minStrokeWidth = 0.5;
  static const double maxStrokeWidth = 40.0;
  static const double defaultPenWidth = 3.0;
  static const double defaultHighlighterWidth = 20.0;
  static const double defaultEraserWidth = 25.0;
  static const double pressureSimulatedDefault = 0.5;

  // ─── Effects ──────────────────────────────────────────────────────────────
  static const int maxUndoHistory = 100;
  static const double inkDryDuration = 500.0; // milliseconds
  static const double trailParticleRate = 20.0; // particles per second
  static const double trailParticleLifetime = 0.8; // seconds
  static const double shimmerParticleLifetime = 1.2; // seconds
  static const int shimmerParticleCount = 8;
  static const double bloomPressureThreshold = 0.7;
  static const double rainbowDistanceCycle = 200.0; // px per full hue cycle
  static const double fountainDownScale = 1.5;
  static const double fountainUpScale = 0.6;

  // ─── Performance ──────────────────────────────────────────────────────────
  static const int maxParticlesHigh = 1000;
  static const int maxParticlesMedium = 500;
  static const int maxParticlesLow = 200;
  static const double particleDensityHigh = 1.0;
  static const double particleDensityMedium = 0.6;
  static const double particleDensityLow = 0.3;

  // ─── Haptics ──────────────────────────────────────────────────────────────
  static const double hapticSnapThreshold = 8.0; // pixels

  // ─── UI ───────────────────────────────────────────────────────────────────
  static const double toolbarHeight = 56.0;
  static const double toolbarIconSize = 24.0;
  static const double colorSwatchSize = 26.0;
  static const double colorSwatchSpacing = 6.0;
  static const double borderRadius = 12.0;
}
