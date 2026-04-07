import 'dart:async';

import 'package:flutter/material.dart';

/// Brief overlay toast shown when the CRDT engine resolves a concurrent edit.
///
/// Auto-dismisses after [_displayDuration]. Typically triggered by the
/// [CollaborationBloc] when [CrdtEngine.shouldApply] processes an operation
/// that was concurrent with a local one.
class ConflictIndicator extends StatefulWidget {
  const ConflictIndicator({
    super.key,
    required this.message,
    this.onDismissed,
  });

  final String message;
  final VoidCallback? onDismissed;

  @override
  State<ConflictIndicator> createState() => _ConflictIndicatorState();
}

class _ConflictIndicatorState extends State<ConflictIndicator>
    with SingleTickerProviderStateMixin {
  static const Duration _displayDuration = Duration(seconds: 3);
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _dismissTimer = Timer(_displayDuration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().whenComplete(() {
      if (mounted) widget.onDismissed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.merge_type_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper that queues and shows [ConflictIndicator] toasts above the canvas.
///
/// Place this widget in the canvas stack via [ConflictIndicatorHost] and call
/// [ConflictIndicatorHostState.showConflict] to display a toast.
class ConflictIndicatorHost extends StatefulWidget {
  const ConflictIndicatorHost({super.key, required this.child});

  final Widget child;

  @override
  State<ConflictIndicatorHost> createState() => ConflictIndicatorHostState();
}

class ConflictIndicatorHostState extends State<ConflictIndicatorHost> {
  final List<String> _queue = [];
  String? _current;

  /// Show a conflict resolution toast with [message].
  void showConflict(String message) {
    if (_current == null) {
      setState(() => _current = message);
    } else {
      _queue.add(message);
    }
  }

  void _onDismissed() {
    setState(() {
      _current = _queue.isNotEmpty ? _queue.removeAt(0) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ConflictIndicator(
                key: ValueKey(_current),
                message: _current!,
                onDismissed: _onDismissed,
              ),
            ),
          ),
      ],
    );
  }
}
