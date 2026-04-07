import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Overlay that draws the detected document edges and allows
/// the user to drag corner handles to adjust the crop region.
class EdgeDetectionOverlay extends StatefulWidget {
  const EdgeDetectionOverlay({
    required this.corners,
    required this.imageSize,
    required this.onCornersChanged,
    super.key,
  });

  /// Current corner positions in image coordinates.
  final List<ui.Offset> corners;

  /// Dimensions of the source image.
  final Size imageSize;

  /// Callback when the user drags a corner handle.
  final ValueChanged<List<ui.Offset>> onCornersChanged;

  @override
  State<EdgeDetectionOverlay> createState() =>
      _EdgeDetectionOverlayState();
}

class _EdgeDetectionOverlayState
    extends State<EdgeDetectionOverlay> {
  late List<ui.Offset> _corners;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _corners = List.of(widget.corners);
  }

  @override
  void didUpdateWidget(EdgeDetectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corners != widget.corners) {
      _corners = List.of(widget.corners);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final viewSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final scaleX =
              viewSize.width / widget.imageSize.width;
          final scaleY =
              viewSize.height / widget.imageSize.height;

          return GestureDetector(
            onPanStart: (details) {
              _draggingIndex = _findClosestCorner(
                details.localPosition,
                scaleX,
                scaleY,
              );
            },
            onPanUpdate: (details) {
              if (_draggingIndex == null) return;
              setState(() {
                _corners[_draggingIndex!] = ui.Offset(
                  (details.localPosition.dx / scaleX)
                      .clamp(
                          0, widget.imageSize.width),
                  (details.localPosition.dy / scaleY)
                      .clamp(
                          0, widget.imageSize.height),
                );
              });
            },
            onPanEnd: (_) {
              if (_draggingIndex != null) {
                widget.onCornersChanged(
                    List.of(_corners));
                _draggingIndex = null;
              }
            },
            child: CustomPaint(
              size: viewSize,
              painter: _EdgePainter(
                corners: _corners,
                scaleX: scaleX,
                scaleY: scaleY,
                activeIndex: _draggingIndex,
              ),
            ),
          );
        },
      );

  int? _findClosestCorner(
    Offset tapPos,
    double scaleX,
    double scaleY,
  ) {
    const hitRadius = 30.0;
    double? minDist;
    int? closest;

    for (var i = 0; i < _corners.length; i++) {
      final screenPos = Offset(
        _corners[i].dx * scaleX,
        _corners[i].dy * scaleY,
      );
      final dist = (screenPos - tapPos).distance;
      if (dist < hitRadius &&
          (minDist == null || dist < minDist)) {
        minDist = dist;
        closest = i;
      }
    }
    return closest;
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.corners,
    required this.scaleX,
    required this.scaleY,
    this.activeIndex,
  });

  final List<ui.Offset> corners;
  final double scaleX;
  final double scaleY;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final scaled = corners
        .map((c) => Offset(c.dx * scaleX, c.dy * scaleY))
        .toList();

    // Draw semi-transparent overlay outside the selection.
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(
        0, 0, size.width, size.height);
    final quadPath = Path()
      ..moveTo(scaled[0].dx, scaled[0].dy)
      ..lineTo(scaled[1].dx, scaled[1].dy)
      ..lineTo(scaled[2].dx, scaled[2].dy)
      ..lineTo(scaled[3].dx, scaled[3].dy)
      ..close();

    final overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      quadPath,
    );
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw edge lines.
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(quadPath, linePaint);

    // Draw corner handles.
    for (var i = 0; i < scaled.length; i++) {
      final isActive = i == activeIndex;
      final handlePaint = Paint()
        ..color =
            isActive ? Colors.white : Colors.blue
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
          scaled[i], isActive ? 14 : 10, handlePaint);
      canvas.drawCircle(
          scaled[i], isActive ? 14 : 10, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      corners != oldDelegate.corners ||
      activeIndex != oldDelegate.activeIndex;
}
