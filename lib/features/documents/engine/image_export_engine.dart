import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:biscuits/features/canvas/domain/entities/stroke.dart';
import 'package:biscuits/features/canvas/domain/models/canvas_config.dart';
import 'package:biscuits/features/documents/domain/entities/canvas_elements.dart';
import 'package:biscuits/features/documents/domain/models/export_options.dart';
import 'package:biscuits/features/shapes/domain/entities/shape_type.dart';

/// Rasterises canvas content as PNG or JPEG.
class ImageExportEngine {
  const ImageExportEngine();

  // ── Internal rendering ─────────────────────────────────────────────────────

  // Arrow head dimensions in canvas points.
  static const _arrowHeadLength = 10.0;
  static const _arrowHeadWidth = 6.0;

  /// Paints strokes and shapes into an [ui.Image] at the given [scale].
  Future<ui.Image> _rasterise({
    required List<Stroke> strokes,
    List<ShapeElement> shapes = const [],
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

    // Draw shapes.
    for (final shape in shapes) {
      final strokePaint = Paint()
        ..color = shape.strokeColor.withOpacity(shape.opacity)
        ..strokeWidth = shape.strokeWidth
        ..style = PaintingStyle.stroke;

      final fillPaint = shape.isFilled
          ? (Paint()
            ..color = shape.fillColor.withOpacity(shape.opacity)
            ..style = PaintingStyle.fill)
          : null;

      switch (shape.type) {
        case ShapeType.rectangle:
        case ShapeType.square:
          if (fillPaint != null) {
            canvas.drawRect(shape.bounds, fillPaint);
          }
          canvas.drawRect(shape.bounds, strokePaint);
        case ShapeType.circle:
        case ShapeType.ellipse:
          final oval = shape.bounds;
          if (fillPaint != null) {
            canvas.drawOval(oval, fillPaint);
          }
          canvas.drawOval(oval, strokePaint);
        case ShapeType.line:
          canvas.drawLine(
            shape.bounds.topLeft,
            shape.bounds.bottomRight,
            strokePaint,
          );
        case ShapeType.arrow:
          final start = Offset(
            shape.bounds.left,
            shape.bounds.center.dy,
          );
          final end = Offset(
            shape.bounds.right,
            shape.bounds.center.dy,
          );
          canvas.drawLine(start, end, strokePaint);
          // Arrowhead
          canvas.drawLine(
            end,
            Offset(end.dx - _arrowHeadLength, end.dy - _arrowHeadWidth),
            strokePaint,
          );
          canvas.drawLine(
            end,
            Offset(end.dx - _arrowHeadLength, end.dy + _arrowHeadWidth),
            strokePaint,
          );
        default:
          // Polygon shapes (triangle, star, diamond, pentagon, hexagon, freeform)
          if (shape.vertices.isNotEmpty) {
            final path = Path();
            path.moveTo(shape.vertices.first.dx, shape.vertices.first.dy);
            for (var i = 1; i < shape.vertices.length; i++) {
              path.lineTo(shape.vertices[i].dx, shape.vertices[i].dy);
            }
            path.close();
            if (fillPaint != null) {
              canvas.drawPath(path, fillPaint);
            }
            canvas.drawPath(path, strokePaint);
          } else {
            if (fillPaint != null) {
              canvas.drawRect(shape.bounds, fillPaint);
            }
            canvas.drawRect(shape.bounds, strokePaint);
          }
      }
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
      shapes: shapes,
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
      // dart:ui does not support JPEG encoding directly via toByteData().
      // We extract raw RGBA pixels and re-encode them as JPEG using the
      // `image` package, which provides full JPEG compression support.
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
    String fileName = 'biscuits_export',
    ImageExportFormat format = ImageExportFormat.png,
  }) async {
    final ext = format == ImageExportFormat.png ? 'png' : 'jpg';
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.$ext');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
