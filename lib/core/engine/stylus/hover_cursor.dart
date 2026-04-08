import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:biscuits/core/engine/stylus/ghost_nib_painter.dart';
import 'package:biscuits/core/engine/stylus/stylus_adapter.dart';
import 'package:biscuits/core/engine/stylus/stylus_detector.dart';

/// Renders a hover cursor preview when the stylus is held above the screen.
///
/// Two visual modes are available, controlled by [ghostNib]:
///
/// **Circle mode** (default):
/// - A circle indicating the current brush size at the hover position.
/// - A semi-transparent fill previewing the active colour.
///
/// **Ghost-nib mode** ([ghostNib] = `true`):
/// - A realistic stylus-nib teardrop shape rotated to match the pen's
///   [azimuth] angle and scaled by [tilt] to simulate perspective.
/// - A soft drop-shadow indicating how far the pen is tilted.
///
/// This widget is layered above the canvas and is only visible when
/// [isVisible] is `true`.
class HoverCursor extends StatelessWidget {
  /// Creates a hover cursor at [position] with the given brush attributes.
  const HoverCursor({
    super.key,
    required this.position,
    required this.brushSize,
    required this.color,
    this.isEraser = false,
    this.isVisible = true,
    this.ghostNib = false,
    this.tilt = 0.0,
    this.azimuth = 0.0,
  });

  /// Screen-space position in logical pixels.
  final Offset position;

  /// Diameter of the brush size circle (circle mode) or nib size (ghost-nib mode).
  final double brushSize;

  /// Active colour for the semi-transparent fill preview.
  final Color color;

  /// When `true`, shows an eraser cursor instead of a coloured brush circle.
  final bool isEraser;

  /// Controls visibility — set to `false` when not hovering.
  final bool isVisible;

  /// When `true`, renders the ghost-nib teardrop shape instead of a plain circle.
  final bool ghostNib;

  /// Pen altitude angle from the screen plane [0, π/2].  Used in ghost-nib mode.
  final double tilt;

  /// Pen azimuth angle in the screen plane [0, 2π).  Used in ghost-nib mode.
  final double azimuth;

  // Size of the ghost-nib canvas to give enough room for nib + shadow.
  static const double _nibCanvasSize = 72.0;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    if (ghostNib) {
      return Positioned(
        left: position.dx - _nibCanvasSize / 2,
        top: position.dy - _nibCanvasSize / 2,
        child: IgnorePointer(
          child: CustomPaint(
            size: const Size(_nibCanvasSize, _nibCanvasSize),
            painter: GhostNibPainter(
              color: color,
              brushSize: brushSize,
              tilt: tilt,
              azimuth: azimuth,
              isEraser: isEraser,
            ),
          ),
        ),
      );
    }

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

/// A brief expanding-ring animation shown at the position where a
/// stylus double-tap or barrel-button gesture was received.
///
/// The ring expands from 0 → [maxRadius] over [duration] while fading
/// out, giving the user clear feedback that the gesture was recognised.
class DoubleTapFlash extends StatefulWidget {
  const DoubleTapFlash({
    super.key,
    required this.position,
    required this.color,
    this.maxRadius = 28.0,
    this.duration = const Duration(milliseconds: 420),
    this.onComplete,
  });

  /// Canvas-space position of the gesture.
  final Offset position;

  /// Ring colour — typically the active tool colour.
  final Color color;

  /// Final radius of the expanding ring.
  final double maxRadius;

  /// Total animation duration.
  final Duration duration;

  /// Called when the animation completes so the parent can remove this widget.
  final VoidCallback? onComplete;

  @override
  State<DoubleTapFlash> createState() => _DoubleTapFlashState();
}

class _DoubleTapFlashState extends State<DoubleTapFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _radius;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      })
      ..forward();

    _radius = Tween<double>(begin: 0, end: widget.maxRadius).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.85, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Positioned(
          left: widget.position.dx - _radius.value,
          top: widget.position.dy - _radius.value,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(_radius.value * 2, _radius.value * 2),
              painter: _FlashRingPainter(
                color: widget.color,
                opacity: _opacity.value,
              ),
            ),
          ),
        ),
      );
}

class _FlashRingPainter extends CustomPainter {
  const _FlashRingPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_FlashRingPainter old) =>
      old.color != color || old.opacity != opacity;
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

