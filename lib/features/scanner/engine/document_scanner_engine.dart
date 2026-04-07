import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';
import 'package:y2notes2/features/scanner/domain/models/scanner_options.dart';

/// Engine that handles document image processing:
/// edge detection, perspective correction, colour filters,
/// and basic OCR text extraction.
class DocumentScannerEngine {
  const DocumentScannerEngine();

  // ── Edge detection ──────────────────────────────────────

  /// Detects the four corners of a document in [imageBytes].
  ///
  /// Returns a list of four [ui.Offset] values in the order:
  /// top-left, top-right, bottom-right, bottom-left.
  /// Falls back to the full image rectangle when no clear
  /// document boundary is found.
  List<ui.Offset> detectEdges(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return _defaultCorners(800, 600);
    }

    final w = decoded.width.toDouble();
    final h = decoded.height.toDouble();

    // Convert to greyscale and apply Gaussian blur to
    // reduce noise.
    final grey = img.grayscale(decoded);
    final blurred = img.gaussianBlur(grey, radius: 3);

    // Use Sobel edge detection to find gradient magnitude.
    final sobelH = img.sobel(blurred);

    // Binarise the edge image with an adaptive threshold.
    final threshold = _computeOtsuThreshold(sobelH);
    final binary = img.copyResize(sobelH,
        width: sobelH.width, height: sobelH.height);
    for (var y = 0; y < binary.height; y++) {
      for (var x = 0; x < binary.width; x++) {
        final pixel = binary.getPixel(x, y);
        final lum = img.getLuminance(pixel);
        if (lum > threshold) {
          binary.setPixelRgb(x, y, 255, 255, 255);
        } else {
          binary.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }

    // Find the outermost white pixels in four quadrants.
    final corners = _findDocumentCorners(binary);

    // Validate: corners must form a reasonable quadrilateral.
    if (_isValidQuadrilateral(corners, w, h)) {
      return corners;
    }

    // Fallback: add a small margin inside the full image.
    final margin = math.min(w, h) * 0.05;
    return [
      ui.Offset(margin, margin),
      ui.Offset(w - margin, margin),
      ui.Offset(w - margin, h - margin),
      ui.Offset(margin, h - margin),
    ];
  }

  // ── Perspective correction ──────────────────────────────

  /// Applies perspective correction to [imageBytes] using the
  /// four [corners]. Returns the corrected image as PNG bytes.
  Future<Uint8List> correctPerspective(
    Uint8List imageBytes,
    List<ui.Offset> corners, {
    double? targetWidth,
    double? targetHeight,
  }) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    // Compute the target dimensions from the corner
    // distances.
    final topWidth = _distance(corners[0], corners[1]);
    final bottomWidth = _distance(corners[3], corners[2]);
    final leftHeight = _distance(corners[0], corners[3]);
    final rightHeight = _distance(corners[1], corners[2]);

    final outW = targetWidth ??
        math.max(topWidth, bottomWidth).roundToDouble();
    final outH = targetHeight ??
        math.max(leftHeight, rightHeight).roundToDouble();

    final w = outW.round();
    final h = outH.round();

    // Build inverse mapping: for each output pixel, compute
    // the source coordinate using bilinear interpolation of
    // the quadrilateral.
    final result = img.Image(width: w, height: h);

    for (var py = 0; py < h; py++) {
      final v = py / (h - 1);
      for (var px = 0; px < w; px++) {
        final u = px / (w - 1);

        // Bilinear interpolation inside the quadrilateral.
        final srcX = (1 - u) * (1 - v) * corners[0].dx +
            u * (1 - v) * corners[1].dx +
            u * v * corners[2].dx +
            (1 - u) * v * corners[3].dx;
        final srcY = (1 - u) * (1 - v) * corners[0].dy +
            u * (1 - v) * corners[1].dy +
            u * v * corners[2].dy +
            (1 - u) * v * corners[3].dy;

        final sx = srcX.round().clamp(0, decoded.width - 1);
        final sy = srcY.round().clamp(0, decoded.height - 1);

        result.setPixel(px, py, decoded.getPixel(sx, sy));
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  // ── Filters ─────────────────────────────────────────────

  /// Applies a colour/contrast filter to [imageBytes].
  Future<Uint8List> applyFilter(
    Uint8List imageBytes,
    ScannerFilter filter,
  ) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    final img.Image filtered;

    switch (filter) {
      case ScannerFilter.auto:
        filtered = _applyAutoFilter(decoded);
      case ScannerFilter.document:
        filtered = _applyDocumentFilter(decoded);
      case ScannerFilter.original:
        filtered = decoded;
      case ScannerFilter.greyscale:
        filtered = img.grayscale(decoded);
      case ScannerFilter.highContrast:
        filtered = _applyHighContrastFilter(decoded);
      case ScannerFilter.whiteboard:
        filtered = _applyWhiteboardFilter(decoded);
    }

    return Uint8List.fromList(img.encodePng(filtered));
  }

  // ── OCR (basic character recognition) ───────────────────

  /// Performs basic OCR on [imageBytes].
  ///
  /// This is a stub that returns detected text regions.
  /// In production, this would integrate with an ML-based
  /// OCR service (e.g. Google ML Kit, Tesseract).
  Future<String> performOcr(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return '';

    // Analyse text region density to estimate whether the
    // document contains text.
    final grey = img.grayscale(decoded);
    final threshold = _computeOtsuThreshold(grey);

    var darkPixels = 0;
    final total = grey.width * grey.height;
    for (var y = 0; y < grey.height; y++) {
      for (var x = 0; x < grey.width; x++) {
        if (img.getLuminance(grey.getPixel(x, y)) <
            threshold) {
          darkPixels++;
        }
      }
    }

    final textDensity = darkPixels / total;

    // Return a placeholder indicating OCR readiness.
    // Real implementation would invoke an OCR library here.
    if (textDensity > 0.05 && textDensity < 0.6) {
      return '[OCR ready – text region detected '
          '(density: ${(textDensity * 100).toStringAsFixed(1)}%). '
          'Connect an OCR provider for full extraction.]';
    }
    return '[No significant text regions detected.]';
  }

  // ── Full processing pipeline ────────────────────────────

  /// Runs the complete scan pipeline on [imageBytes]:
  /// 1. Edge detection
  /// 2. Perspective correction
  /// 3. Colour/contrast filter
  /// 4. Optional OCR
  ///
  /// Returns a fully processed [ScannedPage].
  Future<ScannedPage> processImage(
    Uint8List imageBytes, {
    ScannerOptions options = const ScannerOptions(),
    List<ui.Offset>? manualCorners,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);

    // 1. Edge detection
    final corners = manualCorners ??
        (options.autoDetectEdges
            ? detectEdges(imageBytes)
            : null);
    onProgress?.call(0.2);

    // 2. Perspective correction
    Uint8List processed = imageBytes;
    if (corners != null && options.autoPerspectiveCorrection) {
      processed =
          await correctPerspective(imageBytes, corners);
    }
    onProgress?.call(0.5);

    // 3. Apply filter
    processed = await applyFilter(
      processed,
      options.defaultFilter,
    );
    onProgress?.call(0.7);

    // 4. Optional OCR
    String? ocrText;
    if (options.enableOcr) {
      ocrText = await performOcr(processed);
    }
    onProgress?.call(0.9);

    // Convert processed bytes to ui.Image
    final codec = await ui.instantiateImageCodec(processed);
    final frame = await codec.getNextFrame();
    final uiImage = frame.image;
    onProgress?.call(1.0);

    return ScannedPage(
      originalImage: imageBytes,
      processedImage: uiImage,
      width: uiImage.width.toDouble(),
      height: uiImage.height.toDouble(),
      corners: corners,
      ocrText: ocrText,
      filter: options.defaultFilter,
    );
  }

  // ── Private helpers ─────────────────────────────────────

  List<ui.Offset> _defaultCorners(
    double width,
    double height,
  ) =>
      [
        ui.Offset.zero,
        ui.Offset(width, 0),
        ui.Offset(width, height),
        ui.Offset(0, height),
      ];

  double _distance(ui.Offset a, ui.Offset b) =>
      (a - b).distance;

  int _computeOtsuThreshold(img.Image image) {
    // Compute histogram
    final histogram = List<int>.filled(256, 0);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final lum =
            img.getLuminance(image.getPixel(x, y)).round();
        histogram[lum.clamp(0, 255)]++;
      }
    }

    final total = image.width * image.height;
    var sumAll = 0.0;
    for (var i = 0; i < 256; i++) {
      sumAll += i * histogram[i];
    }

    var sumB = 0.0;
    var wB = 0;
    var maxVariance = 0.0;
    var bestThreshold = 0;

    for (var t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];
      final meanB = sumB / wB;
      final meanF = (sumAll - sumB) / wF;
      final variance =
          wB * wF * (meanB - meanF) * (meanB - meanF);
      if (variance > maxVariance) {
        maxVariance = variance;
        bestThreshold = t;
      }
    }

    return bestThreshold;
  }

  List<ui.Offset> _findDocumentCorners(img.Image binary) {
    final w = binary.width.toDouble();
    final h = binary.height.toDouble();
    final midX = w / 2;
    final midY = h / 2;

    // Search for the most extreme white pixels in each
    // quadrant.
    var topLeft = ui.Offset(w * 0.1, h * 0.1);
    var topRight = ui.Offset(w * 0.9, h * 0.1);
    var bottomRight = ui.Offset(w * 0.9, h * 0.9);
    var bottomLeft = ui.Offset(w * 0.1, h * 0.9);

    var tlScore = double.infinity;
    var trScore = double.infinity;
    var brScore = double.infinity;
    var blScore = double.infinity;

    for (var y = 0; y < binary.height; y++) {
      for (var x = 0; x < binary.width; x++) {
        final lum =
            img.getLuminance(binary.getPixel(x, y));
        if (lum < 128) continue; // Not an edge pixel.

        final dx = x.toDouble();
        final dy = y.toDouble();

        // Top-left: minimise distance to (0,0).
        if (dx < midX && dy < midY) {
          final score = dx * dx + dy * dy;
          if (score < tlScore) {
            tlScore = score;
            topLeft = ui.Offset(dx, dy);
          }
        }
        // Top-right: minimise distance to (w,0).
        if (dx >= midX && dy < midY) {
          final score =
              (w - dx) * (w - dx) + dy * dy;
          if (score < trScore) {
            trScore = score;
            topRight = ui.Offset(dx, dy);
          }
        }
        // Bottom-right: minimise distance to (w,h).
        if (dx >= midX && dy >= midY) {
          final score = (w - dx) * (w - dx) +
              (h - dy) * (h - dy);
          if (score < brScore) {
            brScore = score;
            bottomRight = ui.Offset(dx, dy);
          }
        }
        // Bottom-left: minimise distance to (0,h).
        if (dx < midX && dy >= midY) {
          final score =
              dx * dx + (h - dy) * (h - dy);
          if (score < blScore) {
            blScore = score;
            bottomLeft = ui.Offset(dx, dy);
          }
        }
      }
    }

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  bool _isValidQuadrilateral(
    List<ui.Offset> corners,
    double imgW,
    double imgH,
  ) {
    if (corners.length != 4) return false;

    // Check that the quadrilateral covers at least 10% of
    // the image area.
    final area = _quadArea(corners);
    final imgArea = imgW * imgH;
    if (area < imgArea * 0.1) return false;

    // Check that no corner is too close to another.
    for (var i = 0; i < 4; i++) {
      for (var j = i + 1; j < 4; j++) {
        if (_distance(corners[i], corners[j]) <
            math.min(imgW, imgH) * 0.05) {
          return false;
        }
      }
    }

    return true;
  }

  double _quadArea(List<ui.Offset> c) {
    // Shoelace formula for a quadrilateral.
    var area = 0.0;
    for (var i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      area += c[i].dx * c[j].dy;
      area -= c[j].dx * c[i].dy;
    }
    return area.abs() / 2;
  }

  img.Image _applyAutoFilter(img.Image src) {
    // Auto: adaptive contrast + slight sharpen.
    var result = img.adjustColor(
      src,
      contrast: 1.3,
      brightness: 1.05,
    );
    result = img.convolution(result, filter: [
      0, -0.5, 0, //
      -0.5, 3, -0.5,
      0, -0.5, 0,
    ]);
    return result;
  }

  img.Image _applyDocumentFilter(img.Image src) {
    // Document: greyscale + high contrast + threshold.
    var grey = img.grayscale(src);
    grey = img.adjustColor(grey, contrast: 1.8);
    final threshold = _computeOtsuThreshold(grey);
    for (var y = 0; y < grey.height; y++) {
      for (var x = 0; x < grey.width; x++) {
        final lum =
            img.getLuminance(grey.getPixel(x, y));
        if (lum > threshold) {
          grey.setPixelRgb(x, y, 255, 255, 255);
        } else {
          grey.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    return grey;
  }

  img.Image _applyHighContrastFilter(img.Image src) {
    var result = img.grayscale(src);
    result = img.adjustColor(result, contrast: 2.0);
    return result;
  }

  img.Image _applyWhiteboardFilter(img.Image src) {
    // Whiteboard: lighten background, enhance dark lines.
    var result = img.adjustColor(
      src,
      brightness: 1.15,
      contrast: 1.5,
      saturation: 0.8,
    );
    return result;
  }
}
