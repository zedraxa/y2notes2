import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:biscuits/features/collaboration/domain/entities/participant.dart';

/// Renders all remote users' cursors as an overlay on the canvas.
///
/// Positions are assumed to be in canvas (local) coordinate space.
/// Smooth interpolation is applied via [AnimatedCursorDot] so that cursors
/// glide at 60 fps even though presence updates arrive at ~20 fps.
class RemoteCursors extends StatelessWidget {
  const RemoteCursors({
    super.key,
    required this.participants,
  });

  final Map<String, Participant> participants;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final participant in participants.values)
          if (participant.cursorPosition != null &&
              participant.status != PresenceStatus.disconnected)
            AnimatedCursorDot(
              key: ValueKey(participant.userId),
              participant: participant,
            ),
      ],
    );
  }
}

/// A single animated cursor for one remote participant.
///
/// Position changes are smoothed using an implicit animation.
class AnimatedCursorDot extends StatelessWidget {
  const AnimatedCursorDot({
    super.key,
    required this.participant,
  });

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final pos = participant.cursorPosition!;
    final isIdle = participant.status == PresenceStatus.idle;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      left: pos.dx,
      top: pos.dy,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isIdle ? 0.35 : 1.0,
        child: _CursorWidget(participant: participant),
      ),
    );
  }
}

/// The cursor shape + name label for one remote participant.
class _CursorWidget extends StatelessWidget {
  const _CursorWidget({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cursor arrow
        CustomPaint(
          painter: _ArrowPainter(color: participant.cursorColor),
          size: const Size(20, 22),
        ),
        const SizedBox(height: 2),
        // Name label
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: participant.cursorColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            participant.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a simple arrow-cursor shape filled with [color].
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.7)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.88)
      ..lineTo(size.width * 0.5, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.45)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

// ─── Initials avatar ──────────────────────────────────────────────────────────

/// Small circular avatar showing the participant's initials.
class ParticipantAvatar extends StatelessWidget {
  const ParticipantAvatar({
    super.key,
    required this.participant,
    this.radius = 16,
  });

  final Participant participant;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(participant.displayName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: participant.cursorColor,
      backgroundImage: participant.avatarUrl != null
          ? NetworkImage(participant.avatarUrl!)
          : null,
      child: participant.avatarUrl == null
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
