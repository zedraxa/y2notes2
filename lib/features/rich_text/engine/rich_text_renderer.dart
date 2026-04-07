import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/entities/rich_text_element.dart';
import '../domain/entities/rich_text_node.dart';

/// Renders a [RichTextElement] onto a [Canvas].
///
/// Used by [EffectsCompositor] when painting the rich text
/// layer on the canvas.
class RichTextRenderer {
  const RichTextRenderer();

  /// Paint [element] onto [canvas].
  void render(Canvas canvas, RichTextElement element) {
    canvas.save();

    canvas.translate(
      element.position.dx,
      element.position.dy,
    );
    if (element.rotation != 0) {
      canvas.rotate(element.rotation);
    }

    // Background
    if (element.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = element.backgroundColor
            .withOpacity(element.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            0,
            element.width,
            element.height ?? 200.0,
          ),
          const Radius.circular(6),
        ),
        bgPaint,
      );
    }

    var yOffset = 8.0;
    const horizontalPadding = 12.0;
    final contentWidth =
        element.width - horizontalPadding * 2;

    for (final node in element.nodes) {
      yOffset = _renderNode(
        canvas,
        node,
        Offset(horizontalPadding, yOffset),
        contentWidth,
        element.opacity,
      );
      yOffset += 8.0; // spacing between nodes
    }

    canvas.restore();
  }

  double _renderNode(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    switch (node.type) {
      case RichTextNodeType.heading:
        return _renderHeading(
          canvas,
          node,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.paragraph:
        return _renderParagraph(
          canvas,
          node.spans,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.codeBlock:
        return _renderCodeBlock(
          canvas,
          node,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.unorderedList:
      case RichTextNodeType.orderedList:
        return _renderList(
          canvas,
          node,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.table:
        return _renderTable(
          canvas,
          node,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.blockquote:
        return _renderBlockquote(
          canvas,
          node,
          origin,
          maxWidth,
          opacity,
        );
      case RichTextNodeType.divider:
        return _renderDivider(
          canvas,
          origin,
          maxWidth,
          opacity,
        );
    }
  }

  // ── Heading ───────────────────────────────────────────────

  double _renderHeading(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    final fontSize = _headingFontSize(node.headingLevel);
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        maxLines: null,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.black.withOpacity(opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ))
      ..addText(node.plainText);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, origin);
    return origin.dy + paragraph.height;
  }

  double _headingFontSize(int level) {
    switch (level) {
      case 1:
        return 28.0;
      case 2:
        return 24.0;
      case 3:
        return 20.0;
      case 4:
        return 18.0;
      case 5:
        return 16.0;
      default:
        return 14.0;
    }
  }

  // ── Paragraph (inline spans) ──────────────────────────────

  double _renderParagraph(
    Canvas canvas,
    List<RichTextSpan> spans,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 14.0, maxLines: null),
    );

    for (final span in spans) {
      builder
        ..pushStyle(_inlineTextStyle(span, opacity))
        ..addText(span.text)
        ..pop();
    }

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, origin);
    return origin.dy + paragraph.height;
  }

  ui.TextStyle _inlineTextStyle(
    RichTextSpan span,
    double opacity,
  ) {
    final isBold =
        span.styles.contains(InlineStyle.bold);
    final isItalic =
        span.styles.contains(InlineStyle.italic);
    final isCode =
        span.styles.contains(InlineStyle.code);
    final isStrike =
        span.styles.contains(InlineStyle.strikethrough);

    return ui.TextStyle(
      color: (span.color ?? Colors.black)
          .withOpacity(opacity),
      fontSize: isCode ? 13.0 : 14.0,
      fontWeight:
          isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic
          ? FontStyle.italic
          : FontStyle.normal,
      decoration: isStrike
          ? TextDecoration.lineThrough
          : (span.link != null
              ? TextDecoration.underline
              : null),
      fontFamily: isCode ? 'monospace' : null,
    );
  }

  // ── Code block ────────────────────────────────────────────

  double _renderCodeBlock(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    const padding = 8.0;
    const radius = Radius.circular(4);

    // Measure code text
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 13.0,
        fontFamily: 'monospace',
        maxLines: null,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: const Color(0xFFD4D4D4).withOpacity(opacity),
        fontSize: 13.0,
        fontFamily: 'monospace',
      ))
      ..addText(node.codeText ?? '');

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(
        width: maxWidth - padding * 2,
      ));

    final blockHeight = paragraph.height + padding * 2;

    // Background
    final bgPaint = Paint()
      ..color =
          const Color(0xFF1E1E1E).withOpacity(opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx,
          origin.dy,
          maxWidth,
          blockHeight,
        ),
        radius,
      ),
      bgPaint,
    );

    // Language label
    if (node.language != null &&
        node.language!.isNotEmpty) {
      final langBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: 10.0,
          textAlign: TextAlign.right,
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: const Color(0xFF858585)
              .withOpacity(opacity),
          fontSize: 10.0,
        ))
        ..addText(node.language!);

      final langParagraph = langBuilder.build()
        ..layout(ui.ParagraphConstraints(
          width: maxWidth - padding * 2,
        ));
      canvas.drawParagraph(
        langParagraph,
        Offset(origin.dx + padding, origin.dy + 2),
      );
    }

    // Code text
    canvas.drawParagraph(
      paragraph,
      Offset(
        origin.dx + padding,
        origin.dy + padding,
      ),
    );

    return origin.dy + blockHeight;
  }

  // ── Lists ─────────────────────────────────────────────────

  double _renderList(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    var y = origin.dy;
    final isOrdered =
        node.type == RichTextNodeType.orderedList;

    for (var i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final indentPx = child.indent * 16.0;
      final marker =
          isOrdered ? '${i + 1}.' : '•';

      // Marker
      final markerBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 14.0),
      )
        ..pushStyle(ui.TextStyle(
          color:
              Colors.black.withOpacity(opacity),
          fontSize: 14.0,
        ))
        ..addText(marker);

      final markerParagraph = markerBuilder.build()
        ..layout(
          const ui.ParagraphConstraints(width: 30),
        );
      canvas.drawParagraph(
        markerParagraph,
        Offset(origin.dx + indentPx, y),
      );

      // Content
      y = _renderParagraph(
        canvas,
        child.spans,
        Offset(origin.dx + indentPx + 20, y),
        maxWidth - indentPx - 20,
        opacity,
      );
      y += 4.0;
    }

    return y;
  }

  // ── Table ─────────────────────────────────────────────────

  double _renderTable(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    final data = node.tableData;
    if (data == null || data.isEmpty) {
      return origin.dy;
    }

    final colCount = data.first.length;
    if (colCount == 0) return origin.dy;
    final colWidth = maxWidth / colCount;
    const rowHeight = 24.0;
    const cellPadding = 4.0;

    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    var y = origin.dy;
    for (var row = 0; row < data.length; row++) {
      for (var col = 0; col < data[row].length; col++) {
        final cellRect = Rect.fromLTWH(
          origin.dx + col * colWidth,
          y,
          colWidth,
          rowHeight,
        );
        canvas.drawRect(cellRect, linePaint);

        final isHeader = row == 0;
        final cellBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 12.0,
            fontWeight: isHeader
                ? FontWeight.bold
                : FontWeight.normal,
            maxLines: 1,
            ellipsis: '…',
          ),
        )
          ..pushStyle(ui.TextStyle(
            color: Colors.black.withOpacity(opacity),
            fontSize: 12.0,
            fontWeight: isHeader
                ? FontWeight.bold
                : FontWeight.normal,
          ))
          ..addText(data[row][col]);

        final cellParagraph = cellBuilder.build()
          ..layout(ui.ParagraphConstraints(
            width: colWidth - cellPadding * 2,
          ));
        canvas.drawParagraph(
          cellParagraph,
          Offset(
            origin.dx + col * colWidth + cellPadding,
            y + cellPadding,
          ),
        );
      }
      y += rowHeight;
    }

    return y;
  }

  // ── Blockquote ────────────────────────────────────────────

  double _renderBlockquote(
    Canvas canvas,
    RichTextNode node,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    const barWidth = 3.0;
    const barGap = 8.0;

    final barPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.fill;

    final textY = _renderParagraph(
      canvas,
      node.spans,
      Offset(origin.dx + barWidth + barGap, origin.dy),
      maxWidth - barWidth - barGap,
      opacity * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx,
          origin.dy,
          barWidth,
          textY - origin.dy,
        ),
        const Radius.circular(1.5),
      ),
      barPaint,
    );

    return textY;
  }

  // ── Divider ───────────────────────────────────────────────

  double _renderDivider(
    Canvas canvas,
    Offset origin,
    double maxWidth,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(opacity * 0.3)
      ..strokeWidth = 1.0;

    const y = 8.0;
    canvas.drawLine(
      Offset(origin.dx, origin.dy + y),
      Offset(origin.dx + maxWidth, origin.dy + y),
      paint,
    );

    return origin.dy + y * 2;
  }
}
