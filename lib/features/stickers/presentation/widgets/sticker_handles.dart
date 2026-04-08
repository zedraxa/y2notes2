import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/stickers/domain/entities/sticker_element.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_event.dart';
import 'package:biscuits/features/stickers/presentation/bloc/sticker_state.dart';

/// Widget that renders interactive selection handles for the selected sticker.
///
/// Provides drag-to-resize (corner handles) and drag-to-rotate (rotation
/// handle above the top edge) interactions.
class StickerHandlesOverlay extends StatefulWidget {
  const StickerHandlesOverlay({super.key});

  @override
  State<StickerHandlesOverlay> createState() => _StickerHandlesOverlayState();
}

enum _HandleType { topLeft, topRight, bottomLeft, bottomRight, rotate }

class _StickerHandlesOverlayState extends State<StickerHandlesOverlay> {
  _HandleType? _activeHandle;
  double? _initialScale;
  double? _initialRotation;
  Offset? _initialPointer;

  static const double _handleRadius = 8.0;
  static const double _rotationHandleDistance = 32.0;
  static const double _hitSlop = 12.0;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StickerBloc, StickerState>(
        buildWhen: (prev, curr) =>
            prev.selectedStickerId != curr.selectedStickerId ||
            prev.stickers != curr.stickers,
        builder: (context, state) {
          final sticker = state.selectedSticker;
          if (sticker == null) return const SizedBox.shrink();

          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) =>
                  _onPanStart(details, sticker),
              onPanUpdate: (details) =>
                  _onPanUpdate(details, sticker),
              onPanEnd: (_) => _onPanEnd(),
              child: CustomPaint(
                painter: _HandlesPainter(sticker: sticker),
              ),
            ),
          );
        },
      );

  Rect _getWorldBounds(StickerElement sticker) {
    final local = _localBounds(sticker);
    final s = sticker.scale;
    return Rect.fromCenter(
      center: sticker.position,
      width: local.width * s,
      height: local.height * s,
    );
  }

  List<Offset> _cornerPositions(StickerElement sticker) {
    final local = _localBounds(sticker);
    final s = sticker.scale;
    final cos = math.cos(sticker.rotation);
    final sin = math.sin(sticker.rotation);
    final halfW = local.width * s / 2;
    final halfH = local.height * s / 2;
    final center = sticker.position;

    Offset rotated(double dx, double dy) => Offset(
          center.dx + dx * cos - dy * sin,
          center.dy + dx * sin + dy * cos,
        );

    return [
      rotated(-halfW, -halfH), // topLeft
      rotated(halfW, -halfH), // topRight
      rotated(-halfW, halfH), // bottomLeft
      rotated(halfW, halfH), // bottomRight
    ];
  }

  Offset _rotationHandlePosition(StickerElement sticker) {
    final local = _localBounds(sticker);
    final s = sticker.scale;
    final cos = math.cos(sticker.rotation);
    final sin = math.sin(sticker.rotation);
    final halfH = local.height * s / 2;
    final center = sticker.position;
    return Offset(
      center.dx - (halfH + _rotationHandleDistance) * sin,
      center.dy - (halfH + _rotationHandleDistance) * cos,
    );
  }

  _HandleType? _hitTestHandle(Offset point, StickerElement sticker) {
    final corners = _cornerPositions(sticker);
    const types = [
      _HandleType.topLeft,
      _HandleType.topRight,
      _HandleType.bottomLeft,
      _HandleType.bottomRight,
    ];
    for (var i = 0; i < corners.length; i++) {
      if ((point - corners[i]).distance <= _hitSlop) return types[i];
    }
    final rot = _rotationHandlePosition(sticker);
    if ((point - rot).distance <= _hitSlop) return _HandleType.rotate;
    return null;
  }

  void _onPanStart(DragStartDetails details, StickerElement sticker) {
    final handle = _hitTestHandle(details.localPosition, sticker);
    if (handle == null) return;
    _activeHandle = handle;
    _initialScale = sticker.scale;
    _initialRotation = sticker.rotation;
    _initialPointer = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, StickerElement sticker) {
    if (_activeHandle == null || _initialPointer == null) return;
    final bloc = context.read<StickerBloc>();

    if (_activeHandle == _HandleType.rotate) {
      // Compute angle from sticker center to current pointer
      final current = details.localPosition;
      final center = sticker.position;
      final angle =
          math.atan2(current.dx - center.dx, -(current.dy - center.dy));
      bloc.add(StickerRotated(sticker.id, angle));
    } else {
      // Resize: compute scale change based on distance from center
      final center = sticker.position;
      final initialDist = (_initialPointer! - center).distance;
      final currentDist = (details.localPosition - center).distance;
      if (initialDist > 1) {
        final ratio = currentDist / initialDist;
        final newScale = (_initialScale! * ratio).clamp(0.2, 10.0);
        bloc.add(StickerScaled(sticker.id, newScale));
      }
    }
  }

  void _onPanEnd() {
    _activeHandle = null;
    _initialScale = null;
    _initialRotation = null;
    _initialPointer = null;
  }

  static Rect _localBounds(StickerElement sticker) {
    switch (sticker.type) {
      case StickerType.emoji:
      case StickerType.image:
        const half = 28.0;
        return const Rect.fromLTRB(-half, -half, half, half);
      case StickerType.stamp:
        return const Rect.fromLTRB(-52, -52, 52, 52);
      case StickerType.washi:
        final length = sticker.washiLength ?? 200.0;
        final width = sticker.washiWidth ?? 40.0;
        return Rect.fromCenter(
          center: Offset.zero,
          width: length,
          height: width,
        );
    }
  }
}

/// Custom painter that draws the interactive handle circles and rotation arm.
class _HandlesPainter extends CustomPainter {
  const _HandlesPainter({required this.sticker});

  final StickerElement sticker;

  static const double _handleRadius = 8.0;
  static const double _rotationHandleDistance = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    final local = _StickerHandlesOverlayState._localBounds(sticker);
    final s = sticker.scale;
    final cos = math.cos(sticker.rotation);
    final sin = math.sin(sticker.rotation);
    final halfW = local.width * s / 2;
    final halfH = local.height * s / 2;
    final center = sticker.position;

    Offset rotated(double dx, double dy) => Offset(
          center.dx + dx * cos - dy * sin,
          center.dy + dx * sin + dy * cos,
        );

    final corners = [
      rotated(-halfW, -halfH),
      rotated(halfW, -halfH),
      rotated(halfW, halfH),
      rotated(-halfW, halfH),
    ];

    // Draw dashed selection rectangle
    final dashPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 4; i++) {
      _drawDashedLine(canvas, corners[i], corners[(i + 1) % 4], dashPaint);
    }

    // Draw corner handles
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final corner in corners) {
      canvas.drawCircle(corner, _handleRadius, fillPaint);
      canvas.drawCircle(corner, _handleRadius, strokePaint);
    }

    // Rotation handle
    final topCenter = Offset(
      (corners[0].dx + corners[1].dx) / 2,
      (corners[0].dy + corners[1].dy) / 2,
    );
    final rotHandle = Offset(
      center.dx - (halfH + _rotationHandleDistance) * sin,
      center.dy - (halfH + _rotationHandleDistance) * cos,
    );

    canvas.drawLine(topCenter, rotHandle, dashPaint);
    canvas.drawCircle(rotHandle, _handleRadius, fillPaint);
    canvas.drawCircle(rotHandle, _handleRadius, strokePaint);

    // Rotation icon indicator (small arc)
    final arcPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: rotHandle, radius: 4),
      -math.pi / 2,
      math.pi * 1.2,
      false,
      arcPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final total = (b - a).distance;
    if (total < 1) return;
    var traveled = 0.0;
    var drawing = true;
    final dir = (b - a) / total;
    while (traveled < total) {
      final segLen = drawing ? dashLen : gapLen;
      final end = (traveled + segLen).clamp(0.0, total);
      if (drawing) {
        canvas.drawLine(a + dir * traveled, a + dir * end, paint);
      }
      traveled = end;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_HandlesPainter old) => old.sticker != sticker;
}
