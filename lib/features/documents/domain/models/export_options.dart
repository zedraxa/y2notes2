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

/// Export quality presets (DPI multiplier).
enum ExportQuality {
  /// 72 DPI — screen quality.
  low(0.25),

  /// 150 DPI — medium quality.
  medium(0.5),

  /// 300 DPI — print quality.
  high(1.0);

  const ExportQuality(this.value);

  /// Normalised quality value used when rasterising (1.0 = full 300 DPI).
  final double value;

  int get dpi => switch (this) {
        ExportQuality.low => 72,
        ExportQuality.medium => 150,
        ExportQuality.high => 300,
      };
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
