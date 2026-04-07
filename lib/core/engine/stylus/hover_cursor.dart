import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y2notes2/core/engine/stylus/stylus_adapter.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';

/// Renders a hover cursor preview when the stylus is held above the screen.
///
/// Shows:
/// - A circle indicating the current brush size at the hover position.
/// - A small tool-icon indicator in the top-right of the circle.
/// - A semi-transparent fill previewing the active color.
///
/// This widget is layered above the canvas and is only visible when the
/// [StylusInput.isHovering] flag is true.
class HoverCursor extends StatelessWidget {
  /// Creates a hover cursor at [position] with the given brush attributes.
  const HoverCursor({
    super.key,
    required this.position,
    required this.brushSize,
    required this.color,
    this.isEraser = false,
    this.isVisible = true,
  });

  /// Screen-space position in logical pixels.
  final Offset position;

  /// Diameter of the brush size circle.
  final double brushSize;

  /// Active color for the semi-transparent fill preview.
  final Color color;

  /// When `true`, shows an eraser cursor instead of a colored brush circle.
  final bool isEraser;

  /// Controls visibility — set to `false` when not hovering.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      left: position.dx - brushSize / 2,
      top: position.dy - brushSize / 2,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(brushSize, brushSize),
          painter: _HoverCursorPainter(
            brushSize: brushSize,
            color: color,
            isEraser: isEraser,
          ),
        ),
      ),
    );
  }
}

class _HoverCursorPainter extends CustomPainter {
  const _HoverCursorPainter({
    required this.brushSize,
    required this.color,
    required this.isEraser,
  });

  final double brushSize;
  final Color color;
  final bool isEraser;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    if (isEraser) {
      // Eraser: white fill with dashed border
      final fillPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 1, fillPaint);

      final borderPaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - 1, borderPaint);
    } else {
      // Colored brush preview
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 1, fillPaint);

      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - 1, borderPaint);

      // Crosshair center dot
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_HoverCursorPainter old) =>
      old.brushSize != brushSize ||
      old.color != color ||
      old.isEraser != isEraser;
}

/// Controller that tracks whether the stylus is currently hovering and at
/// what position.
///
/// Used by the canvas layer to show / hide [HoverCursor].
class HoverCursorController extends ChangeNotifier {
  /// Whether the pen is currently hovering above the screen.
  bool get isHovering => _isHovering;
  bool _isHovering = false;

  /// The current hover position in logical pixels.
  Offset get hoverPosition => _position;
  Offset _position = Offset.zero;

  /// Updates hover state from a [StylusInput].
  ///
  /// Notifies listeners when the hovering state or position changes.
  void update(StylusInput input) {
    final wasHovering = _isHovering;
    final prevPosition = _position;

    _isHovering = input.isHovering &&
        StylusDetector.hasCapability(input.stylusType, StylusCapability.hover);
    _position = input.position;

    if (_isHovering != wasHovering || _position != prevPosition) {
      notifyListeners();
    }
  }

  /// Clears hover state (pen lifted or moved out of range).
  void clear() {
    if (_isHovering) {
      _isHovering = false;
      notifyListeners();
    }
  }
}
