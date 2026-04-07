import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_bloc.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_event.dart';
import 'package:y2notes2/features/widgets/presentation/bloc/widget_state.dart';

/// Overlays interactive smart widgets on the canvas.
class WidgetInteractionHandler extends StatelessWidget {
  const WidgetInteractionHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WidgetBloc, WidgetState>(
        builder: (context, state) => Stack(
          children: [
            child,
            ...state.widgets.map(
              (w) => _InteractiveWidget(
                key: ValueKey(w.id),
                widget: w,
                isSelected: w.id == state.selectedWidgetId,
              ),
            ),
          ],
        ),
      );
}

class _InteractiveWidget extends StatefulWidget {
  const _InteractiveWidget({
    super.key,
    required this.widget,
    required this.isSelected,
  });

  final SmartWidget widget;
  final bool isSelected;

  @override
  State<_InteractiveWidget> createState() => _InteractiveWidgetState();
}

class _InteractiveWidgetState extends State<_InteractiveWidget> {
  late Offset _position;
  late Size _size;
  Offset? _panStart;
  Offset? _posStart;

  static const double _handleSize = 24;

  @override
  void initState() {
    super.initState();
    _position = widget.widget.position;
    _size = widget.widget.size;
  }

  @override
  void didUpdateWidget(_InteractiveWidget old) {
    super.didUpdateWidget(old);
    if (old.widget.position != widget.widget.position) {
      _position = widget.widget.position;
    }
    if (old.widget.size != widget.widget.size) {
      _size = widget.widget.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      width: _size.width,
      height: _size.height,
      child: GestureDetector(
        onTap: () {
          context.read<WidgetBloc>().add(WidgetTapped(widget.widget.id));
        },
        onLongPress: () {
          context
              .read<WidgetBloc>()
              .add(WidgetLongPressed(widget.widget.id));
        },
        onPanStart: (d) {
          _panStart = d.globalPosition;
          _posStart = _position;
        },
        onPanUpdate: (d) {
          if (_panStart == null || _posStart == null) return;
          final delta = d.globalPosition - _panStart!;
          setState(() => _position = _posStart! + delta);
        },
        onPanEnd: (_) {
          context.read<WidgetBloc>().add(
                WidgetMoved(widget.widget.id, _position),
              );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Widget content
            Positioned.fill(
              child: widget.widget.buildInteractiveOverlay(
                context,
                onStateChanged: (newState) {
                  context.read<WidgetBloc>().add(
                        WidgetStateChanged(widget.widget.id, newState),
                      );
                },
              ),
            ),
            // Selection border
            if (widget.isSelected) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // Resize handle (bottom-right)
              Positioned(
                right: -_handleSize / 2,
                bottom: -_handleSize / 2,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _size = Size(
                        (_size.width + d.delta.dx).clamp(80, 600),
                        (_size.height + d.delta.dy).clamp(60, 600),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    context.read<WidgetBloc>().add(
                          WidgetResized(widget.widget.id, _size),
                        );
                  },
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.open_in_full,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
              // Delete handle (top-right)
              Positioned(
                right: -_handleSize / 2,
                top: -_handleSize / 2,
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<WidgetBloc>()
                        .add(WidgetRemoved(widget.widget.id));
                  },
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
