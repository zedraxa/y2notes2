import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';

/// Configuration options for the document scanner.
class ScannerOptions extends Equatable {
  const ScannerOptions({
    this.autoDetectEdges = true,
    this.autoPerspectiveCorrection = true,
    this.defaultFilter = ScannerFilter.auto,
    this.enableOcr = true,
    this.maxImageDimension = 2048.0,
    this.jpegQuality = 90,
  });

  /// Whether to automatically detect document edges.
  final bool autoDetectEdges;

  /// Whether to automatically correct perspective distortion.
  final bool autoPerspectiveCorrection;

  /// Default filter to apply to scanned images.
  final ScannerFilter defaultFilter;

  /// Whether to run OCR on scanned pages.
  final bool enableOcr;

  /// Maximum dimension (width or height) for the processed
  /// image.
  final double maxImageDimension;

  /// JPEG quality (0–100) for saving scanned images.
  final int jpegQuality;

  ScannerOptions copyWith({
    bool? autoDetectEdges,
    bool? autoPerspectiveCorrection,
    ScannerFilter? defaultFilter,
    bool? enableOcr,
    double? maxImageDimension,
    int? jpegQuality,
  }) =>
      ScannerOptions(
        autoDetectEdges:
            autoDetectEdges ?? this.autoDetectEdges,
        autoPerspectiveCorrection: autoPerspectiveCorrection ??
            this.autoPerspectiveCorrection,
        defaultFilter: defaultFilter ?? this.defaultFilter,
        enableOcr: enableOcr ?? this.enableOcr,
        maxImageDimension:
            maxImageDimension ?? this.maxImageDimension,
        jpegQuality: jpegQuality ?? this.jpegQuality,
      );

  @override
  List<Object?> get props => [
        autoDetectEdges,
        autoPerspectiveCorrection,
        defaultFilter,
        enableOcr,
        maxImageDimension,
        jpegQuality,
      ];
}
