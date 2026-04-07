import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/canvas_elements.dart';
import 'package:y2notes2/features/documents/domain/models/export_options.dart';

/// Rasterises canvas content as PNG or JPEG.
class ImageExportEngine {
  const ImageExportEngine();

  // ── Internal rendering ─────────────────────────────────────────────────────

  /// Paints strokes into an [ui.Image] at the given [scale].
  Future<ui.Image> _rasterise({
    required List<Stroke> strokes,
    required CanvasConfig config,
    required double scale,
    required bool transparentBackground,
    required bool cropToContent,
  }) async {
    final canvasWidth = (config.width * scale).ceil();
    final canvasHeight = (config.height * scale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    // Background.
    if (!transparentBackground) {
      final bgColor = config.template == PageTemplate.chalkboard
          ? const Color(0xFF1C1C1E)
          : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, config.width, config.height),
        Paint()..color = bgColor,
      );
    }

    // Draw strokes.
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.baseWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.x, first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    return picture.toImage(canvasWidth, canvasHeight);
  }

  // ── Bounding box helpers ────────────────────────────────────────────────────

  Rect? _contentBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return null;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    const padding = 16.0;
    return Rect.fromLTRB(
      (minX - padding).clamp(0, double.infinity),
      (minY - padding).clamp(0, double.infinity),
      maxX + padding,
      maxY + padding,
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Exports the canvas as image bytes.
  /// Note: [shapes] and [stickers] are accepted for API compatibility with
  /// future PRs but are not yet rendered.
  Future<Uint8List> exportToImage({
    required List<Stroke> strokes,
    List<ShapeElement> shapes = const [],
    List<StickerElement> stickers = const [],
    required CanvasConfig config,
    ImageExportOptions options = const ImageExportOptions(),
    void Function(double)? onProgress,
  }) async {
    onProgress?.call(0.0);

    final image = await _rasterise(
      strokes: strokes,
      config: config,
      scale: options.scale,
      transparentBackground:
          options.transparentBackground && options.format == ImageExportFormat.png,
      cropToContent: options.cropToContent,
    );

    onProgress?.call(0.7);

    ui.Image finalImage = image;

    if (options.cropToContent) {
      final bounds = _contentBounds(strokes);
      if (bounds != null) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final src = Rect.fromLTWH(
          bounds.left * options.scale,
          bounds.top * options.scale,
          bounds.width * options.scale,
          bounds.height * options.scale,
        );
        final dst = Rect.fromLTWH(
          0,
          0,
          src.width,
          src.height,
        );
        canvas.drawImageRect(image, src, dst, Paint());
        final picture = recorder.endRecording();
        finalImage = await picture.toImage(src.width.ceil(), src.height.ceil());
        image.dispose();
      }
    }

    Uint8List outputBytes;

    if (options.format == ImageExportFormat.png) {
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      outputBytes = byteData!.buffer.asUint8List();
    } else {
      // For JPEG, get raw RGBA bytes and re-encode using the image package.
      final rawData =
          await finalImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rawBytes = rawData!.buffer.asUint8List();
      final imgFrame = img.Image.fromBytes(
        width: finalImage.width,
        height: finalImage.height,
        bytes: rawBytes.buffer,
        numChannels: 4,
      );
      outputBytes = Uint8List.fromList(img.encodeJpg(imgFrame, quality: 90));
    }

    if (finalImage != image) finalImage.dispose();
    onProgress?.call(1.0);
    return outputBytes;
  }

  /// Saves exported image bytes to the application documents directory.
  Future<String> saveToFile({
    required Uint8List bytes,
    String fileName = 'y2notes_export',
    ImageExportFormat format = ImageExportFormat.png,
  }) async {
    final ext = format == ImageExportFormat.png ? 'png' : 'jpg';
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.$ext');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
