import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A single page captured by the document scanner.
class ScannedPage extends Equatable {
  ScannedPage({
    String? id,
    required this.originalImage,
    this.processedImage,
    required this.width,
    required this.height,
    this.corners,
    this.ocrText,
    this.filter = ScannerFilter.auto,
    DateTime? scannedAt,
  })  : id = id ?? const Uuid().v4(),
        scannedAt = scannedAt ?? DateTime.now();

  final String id;

  /// Raw image bytes from the camera.
  final Uint8List originalImage;

  /// Processed image after edge detection, perspective correction,
  /// and filter application.
  final ui.Image? processedImage;

  final double width;
  final double height;

  /// Four corner points detected on the document edges.
  /// Order: top-left, top-right, bottom-right, bottom-left.
  final List<ui.Offset>? corners;

  /// OCR-extracted text, if available.
  final String? ocrText;

  /// Filter applied to the scanned image.
  final ScannerFilter filter;

  final DateTime scannedAt;

  bool get hasCorners =>
      corners != null && corners!.length == 4;

  bool get hasOcrText =>
      ocrText != null && ocrText!.isNotEmpty;

  bool get isProcessed => processedImage != null;

  ScannedPage copyWith({
    Uint8List? originalImage,
    ui.Image? processedImage,
    bool clearProcessedImage = false,
    double? width,
    double? height,
    List<ui.Offset>? corners,
    bool clearCorners = false,
    String? ocrText,
    bool clearOcrText = false,
    ScannerFilter? filter,
  }) =>
      ScannedPage(
        id: id,
        originalImage: originalImage ?? this.originalImage,
        processedImage: clearProcessedImage
            ? null
            : (processedImage ?? this.processedImage),
        width: width ?? this.width,
        height: height ?? this.height,
        corners:
            clearCorners ? null : (corners ?? this.corners),
        ocrText:
            clearOcrText ? null : (ocrText ?? this.ocrText),
        filter: filter ?? this.filter,
        scannedAt: scannedAt,
      );

  @override
  List<Object?> get props => [
        id,
        width,
        height,
        corners,
        ocrText,
        filter,
        scannedAt,
      ];
}

/// Result of a complete scan session (one or more pages).
class ScanResult extends Equatable {
  const ScanResult({
    required this.pages,
    required this.scannedAt,
    this.title,
  });

  final List<ScannedPage> pages;
  final DateTime scannedAt;

  /// Suggested title derived from OCR or user input.
  final String? title;

  int get pageCount => pages.length;
  bool get hasPages => pages.isNotEmpty;

  @override
  List<Object?> get props => [pages, scannedAt, title];
}

/// Available image filters for scanned documents.
enum ScannerFilter {
  /// Automatic optimisation based on content detection.
  auto,

  /// High-contrast black & white for text documents.
  document,

  /// Original colours preserved.
  original,

  /// Greyscale conversion.
  greyscale,

  /// High-contrast with enhanced blacks for readability.
  highContrast,

  /// Whiteboard optimisation — removes glare, enhances lines.
  whiteboard,
}
