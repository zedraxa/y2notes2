import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/entities/canvas_elements.dart';
import 'package:y2notes2/features/documents/domain/models/export_options.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_type.dart';

/// Converts canvas content (strokes, shapes, stickers) into a PDF document.
class PdfExportEngine {
  const PdfExportEngine();

  // ── Dimensions ─────────────────────────────────────────────────────────────

  static PdfPageFormat _pageFormat(
    PdfExportOptions options,
    CanvasConfig config,
  ) {
    final isLandscape = options.orientation == PdfOrientation.landscape;
    switch (options.pageSize) {
      case PdfPageSize.a4:
        return isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
      case PdfPageSize.letter:
        return isLandscape
            ? PdfPageFormat.letter.landscape
            : PdfPageFormat.letter;
      case PdfPageSize.custom:
        // Use canvas dimensions as PDF points (1pt ≈ 1px at screen resolution).
        final w = config.width;
        final h = config.height;
        return PdfPageFormat(
          isLandscape ? h : w,
          isLandscape ? w : h,
        );
    }
  }

  // ── Background rendering ───────────────────────────────────────────────────

  void _drawBackground(
    pw.Context ctx,
    PdfPageFormat format,
    CanvasConfig config,
    PdfExportOptions options,
  ) {
    if (!options.includeBackground) return;

    final PdfGraphics g = ctx.canvas;
    final double w = format.availableWidth;
    final double h = format.availableHeight;

    // Page background colour.
    final bgColor = config.template == PageTemplate.chalkboard
        ? PdfColors.grey900
        : PdfColors.white;
    g.setFillColor(bgColor);
    g.drawRect(0, 0, w, h);
    g.fillPath();

    // Grid / rule lines.
    final lineColor = config.template == PageTemplate.chalkboard
        ? PdfColors.grey600
        : PdfColors.grey300;
    g.setStrokeColor(lineColor);
    g.setLineWidth(0.3);

    switch (config.template) {
      case PageTemplate.blank:
      case PageTemplate.chalkboard:
        break;
      case PageTemplate.lined:
        final spacing = config.lineSpacing;
        for (double y = h - spacing; y > 0; y -= spacing) {
          g.moveTo(0, y);
          g.lineTo(w, y);
          g.strokePath();
        }
        // Margin line.
        if (config.showMargin) {
          g.setStrokeColor(PdfColors.red200);
          g.moveTo(60, 0);
          g.lineTo(60, h);
          g.strokePath();
        }
      case PageTemplate.grid:
        final spacing = config.gridSpacing;
        for (double y = h - spacing; y > 0; y -= spacing) {
          g.moveTo(0, y);
          g.lineTo(w, y);
          g.strokePath();
        }
        for (double x = spacing; x < w; x += spacing) {
          g.moveTo(x, 0);
          g.lineTo(x, h);
          g.strokePath();
        }
      case PageTemplate.dotted:
        final spacing = config.dotSpacing;
        const r = 0.6;
        for (double y = h - spacing; y > 0; y -= spacing) {
          for (double x = spacing; x < w; x += spacing) {
            g.drawEllipse(x, y, r, r);
            g.fillPath();
          }
        }
    }
  }

  // ── Stroke rendering ───────────────────────────────────────────────────────

  void _drawStrokes(
    pw.Context ctx,
    PdfPageFormat format,
    List<Stroke> strokes,
    CanvasConfig config,
    PdfExportOptions options,
  ) {
    final PdfGraphics g = ctx.canvas;
    final double pageH = format.availableHeight;
    final double scaleX = format.availableWidth / config.width;
    final double scaleY = pageH / config.height;
    final double mLeft = options.margins.left;
    final double mBottom = options.margins.bottom;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final c = stroke.color;
      g.setStrokeColor(
        PdfColor.fromInt(c.value),
      );
      g.setFillColor(PdfColor.fromInt(c.value));

      final lineWidth = stroke.baseWidth * ((scaleX + scaleY) / 2);
      g.setLineWidth(lineWidth.clamp(0.3, 20.0));
      g.setLineCap(PdfLineCap.round);
      g.setLineJoin(PdfLineJoin.round);

      // Replay the stroke path.
      final first = stroke.points.first;
      // PDF coordinate system: origin at bottom-left → flip y axis.
      g.moveTo(
        first.x * scaleX + mLeft,
        pageH - first.y * scaleY - mBottom,
      );
      for (int i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        g.lineTo(
          p.x * scaleX + mLeft,
          pageH - p.y * scaleY - mBottom,
        );
      }
      g.strokePath();
    }
  }

  // ── Shape rendering ─────────────────────────────────────────────────────────

  // Arrow head dimensions (in canvas points before scaling).
  static const _arrowHeadLength = 10.0;
  static const _arrowHeadWidth = 6.0;

  void _drawShapes(
    pw.Context ctx,
    PdfPageFormat format,
    List<ShapeElement> shapes,
    CanvasConfig config,
    PdfExportOptions options,
  ) {
    if (shapes.isEmpty) return;
    final PdfGraphics g = ctx.canvas;
    final double pageH = format.availableHeight;
    final double scaleX = format.availableWidth / config.width;
    final double scaleY = pageH / config.height;
    final double mLeft = options.margins.left;
    final double mBottom = options.margins.bottom;

    for (final shape in shapes) {
      final c = shape.strokeColor;
      g.setStrokeColor(PdfColor.fromInt(c.value));
      g.setLineWidth(
          (shape.strokeWidth * ((scaleX + scaleY) / 2)).clamp(0.3, 10.0));

      if (shape.isFilled) {
        final fc = shape.fillColor;
        g.setFillColor(PdfColor.fromInt(fc.value));
      }

      final left = shape.bounds.left * scaleX + mLeft;
      final top = shape.bounds.top * scaleY;
      final w = shape.bounds.width * scaleX;
      final h = shape.bounds.height * scaleY;
      // PDF y is from bottom.
      final bottom = pageH - top - h - mBottom;

      switch (shape.type) {
        case ShapeType.rectangle:
        case ShapeType.square:
          g.drawRect(left, bottom, w, h);
        case ShapeType.circle:
        case ShapeType.ellipse:
          g.drawEllipse(left + w / 2, bottom + h / 2, w / 2, h / 2);
        case ShapeType.line:
          g.moveTo(left, bottom + h);
          g.lineTo(left + w, bottom);
        case ShapeType.arrow:
          g.moveTo(left, bottom + h / 2);
          g.lineTo(left + w, bottom + h / 2);
          // Arrow head
          final aLen = _arrowHeadLength * scaleX;
          final aWid = _arrowHeadWidth * scaleY;
          g.moveTo(left + w - aLen, bottom + h / 2 + aWid);
          g.lineTo(left + w, bottom + h / 2);
          g.moveTo(left + w - aLen, bottom + h / 2 - aWid);
          g.lineTo(left + w, bottom + h / 2);
        default:
          // For polygon types (triangle, star, diamond, pentagon, hexagon, freeform)
          if (shape.vertices.isNotEmpty) {
            final first = shape.vertices.first;
            g.moveTo(
              first.dx * scaleX + mLeft,
              pageH - first.dy * scaleY - mBottom,
            );
            for (var i = 1; i < shape.vertices.length; i++) {
              final v = shape.vertices[i];
              g.lineTo(
                v.dx * scaleX + mLeft,
                pageH - v.dy * scaleY - mBottom,
              );
            }
            g.closePath();
          } else {
            // Fallback: draw bounding rectangle.
            g.drawRect(left, bottom, w, h);
          }
      }

      if (shape.isFilled) {
        g.fillAndStrokePath();
      } else {
        g.strokePath();
      }
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Converts canvas content into raw PDF bytes.
  ///
  /// [onProgress] reports a value from 0.0 to 1.0.
  Future<Uint8List> exportToPdf({
    required List<Stroke> strokes,
    List<ShapeElement> shapes = const [],
    List<StickerElement> stickers = const [],
    required CanvasConfig config,
    PdfExportOptions options = const PdfExportOptions(),
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);

    final format = _pageFormat(options, config);
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        // No margins at the pw.Page level; we handle margins in the draw calls.
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          _drawBackground(ctx, format, config, options);
          onProgress?.call(0.3);
          _drawStrokes(ctx, format, strokes, config, options);
          onProgress?.call(0.6);
          _drawShapes(ctx, format, shapes, config, options);
          onProgress?.call(0.9);
          return pw.SizedBox();
        },
      ),
    );

    final bytes = await doc.save();
    onProgress?.call(1.0);
    return bytes;
  }

  /// Exports multiple pages to a single PDF.
  Future<Uint8List> exportMultiPageToPdf({
    required List<({
      List<Stroke> strokes,
      List<ShapeElement> shapes,
      List<StickerElement> stickers,
      CanvasConfig config,
    })> pages,
    PdfExportOptions options = const PdfExportOptions(),
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.0);
    final doc = pw.Document();
    final total = pages.length;

    for (int i = 0; i < total; i++) {
      final page = pages[i];
      final format = _pageFormat(options, page.config);

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (ctx) {
            _drawBackground(ctx, format, page.config, options);
            _drawStrokes(ctx, format, page.strokes, page.config, options);
            _drawShapes(ctx, format, page.shapes, page.config, options);
            return pw.SizedBox();
          },
        ),
      );
      onProgress?.call((i + 1) / total);
    }

    final bytes = await doc.save();
    onProgress?.call(1.0);
    return bytes;
  }

  /// Saves a PDF to the device's documents directory and returns the file path.
  Future<String> saveToFile({
    required Uint8List pdfBytes,
    String fileName = 'y2notes_export.pdf',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Opens the system share sheet so the user can share / print the PDF.
  Future<void> shareAsPdf({
    required Uint8List pdfBytes,
    String name = 'Y2Notes Export',
    String subject = 'Notes export',
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$name.pdf',
      subject: subject,
    );
  }

  /// Opens the system print dialog.
  Future<void> printPdf({
    required Uint8List pdfBytes,
    String name = 'Y2Notes',
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: name,
    );
  }
}
