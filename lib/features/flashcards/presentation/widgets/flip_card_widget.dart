import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An interactive card that flips between front and back when tapped.
///
/// Uses a 3D rotation animation for a realistic flip effect.
class FlipCardWidget extends StatefulWidget {
  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
  });

  final String front;
  final String back;

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.addListener(() {
      if (_controller.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_controller.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset flip state when card changes.
    if (oldWidget.front != widget.front || oldWidget.back != widget.back) {
      _controller.reset();
      _showFront = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: _showFront
                ? _CardFace(
                    text: widget.front,
                    label: 'QUESTION',
                    color: Theme.of(context).colorScheme.primaryContainer,
                    textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardFace(
                      text: widget.back,
                      label: 'ANSWER',
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String text;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.59),
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Tap to flip',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.39),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
