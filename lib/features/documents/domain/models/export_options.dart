import 'package:flutter/material.dart';

/// Supported PDF page sizes.
enum PdfPageSize {
  a4,
  letter,
  custom,
}

/// PDF page orientation.
enum PdfOrientation {
  portrait,
  landscape,
}

/// Export quality presets.
enum ExportQuality {
  /// Low quality — 72 DPI. Suitable for on-screen viewing.
  low(0.25),

  /// Medium quality — 150 DPI. Suitable for digital sharing.
  medium(0.5),

  /// High quality — 300 DPI. Suitable for print.
  high(1.0);

  const ExportQuality(this.multiplier);

  /// Scale multiplier relative to the base 300 DPI resolution
  /// (1.0 = full 300 DPI, 0.5 = 150 DPI, 0.25 = 72 DPI).
  final double multiplier;

  /// Effective DPI for this quality preset.
  int get dpi => switch (this) {
        ExportQuality.low => 72,
        ExportQuality.medium => 150,
        ExportQuality.high => 300,
      };

  /// Human-readable display label including DPI.
  String get displayName => switch (this) {
        ExportQuality.low => 'Low (72 DPI)',
        ExportQuality.medium => 'Medium (150 DPI)',
        ExportQuality.high => 'High (300 DPI)',
      };

  /// Alias for [multiplier] — used by export engines.
  double get value => multiplier;
}

/// Configuration for PDF export.
class PdfExportOptions {
  const PdfExportOptions({
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.quality = ExportQuality.high,
    this.includeBackground = true,
    this.margins = EdgeInsets.zero,
  });

  final PdfPageSize pageSize;
  final PdfOrientation orientation;
  final ExportQuality quality;
  final bool includeBackground;
  final EdgeInsets margins;

  PdfExportOptions copyWith({
    PdfPageSize? pageSize,
    PdfOrientation? orientation,
    ExportQuality? quality,
    bool? includeBackground,
    EdgeInsets? margins,
  }) =>
      PdfExportOptions(
        pageSize: pageSize ?? this.pageSize,
        orientation: orientation ?? this.orientation,
        quality: quality ?? this.quality,
        includeBackground: includeBackground ?? this.includeBackground,
        margins: margins ?? this.margins,
      );
}

/// Image format for image export.
enum ImageExportFormat { png, jpeg }

/// Configuration for image export.
class ImageExportOptions {
  const ImageExportOptions({
    this.format = ImageExportFormat.png,
    this.scale = 2.0,
    this.transparentBackground = false,
    this.cropToContent = false,
  });

  final ImageExportFormat format;

  /// Pixel density multiplier (1x, 2x, 3x).
  final double scale;

  /// Only applicable when [format] is [ImageExportFormat.png].
  final bool transparentBackground;

  /// Crop output to the bounding box of drawn content; otherwise exports the
  /// full page.
  final bool cropToContent;

  ImageExportOptions copyWith({
    ImageExportFormat? format,
    double? scale,
    bool? transparentBackground,
    bool? cropToContent,
  }) =>
      ImageExportOptions(
        format: format ?? this.format,
        scale: scale ?? this.scale,
        transparentBackground:
            transparentBackground ?? this.transparentBackground,
        cropToContent: cropToContent ?? this.cropToContent,
      );
}
