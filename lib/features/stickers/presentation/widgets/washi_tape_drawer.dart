import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/stickers/data/sticker_packs.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';
import 'package:y2notes2/features/stickers/domain/models/washi_pattern.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_event.dart';

/// GestureDetector widget for drag-drawing washi tape.
/// Shows a live preview during drag; creates a StickerElement on drag end.
class WashiTapeDrawer extends StatefulWidget {
  const WashiTapeDrawer({
    super.key,
    required this.patternId,
    required this.child,
  });

  final String patternId;
  final Widget child;

  @override
  State<WashiTapeDrawer> createState() => _WashiTapeDrawerState();
}

class _WashiTapeDrawerState extends State<WashiTapeDrawer> {
  Offset? _start;
  Offset? _end;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onPanStart: (d) => setState(() {
          _start = d.localPosition;
          _end = d.localPosition;
        }),
        onPanUpdate: (d) => setState(() => _end = d.localPosition),
        onPanEnd: (_) => _finalize(context),
        child: CustomPaint(
          foregroundPainter: _WashiPreviewPainter(
            start: _start,
            end: _end,
            patternId: widget.patternId,
          ),
          child: widget.child,
        ),
      );

  void _finalize(BuildContext context) {
    if (_start == null || _end == null) return;
    final start = _start!;
    final end = _end!;
    setState(() {
      _start = null;
      _end = null;
    });

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 10) return;

    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final rotation = math.atan2(dy, dx);

    final sticker = StickerElement(
      type: StickerType.washi,
      assetKey: widget.patternId,
      position: center,
      rotation: rotation,
      washiLength: length,
      washiWidth: 40.0,
    );
    context.read<StickerBloc>().add(StickerPlaced(sticker));
  }
}

class _WashiPreviewPainter extends CustomPainter {
  const _WashiPreviewPainter({
    required this.start,
    required this.end,
    required this.patternId,
  });

  final Offset? start;
  final Offset? end;
  final String patternId;

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;
    final s = start!;
    final e = end!;

    final dx = e.dx - s.dx;
    final dy = e.dy - s.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 2) return;

    final pattern = StickerPacks.washiPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => StickerPacks.washiPatterns.first,
    );

    final paint = Paint()
      ..color = pattern.color.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final center = Offset((s.dx + e.dx) / 2, (s.dy + e.dy) / 2);
    final angle = math.atan2(dy, dx);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: length, height: 40),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WashiPreviewPainter old) =>
      old.start != start || old.end != end;
}
