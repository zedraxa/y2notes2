import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../engine/infinite_canvas_engine.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';

/// Floating zoom controls pill shown on the infinite canvas.
///
/// Displays current zoom percentage and +/−/fit/reset buttons.
class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

  static const _presets = [0.10, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0, 4.0];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfiniteCanvasBloc, InfiniteCanvasState>(
      builder: (context, state) {
        final pct = (state.zoomLevel * 100).round();
        final bloc = context.read<InfiniteCanvasBloc>();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom-out.
              _IconBtn(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onTap: () => bloc.add(const ZoomViewport(factor: 1 / 1.2)),
              ),
              // Percentage pill — tap for presets.
              _ZoomPill(
                pct: pct,
                onPreset: (level) => bloc.add(SetZoom(level)),
                presets: _presets,
              ),
              // Zoom-in.
              _IconBtn(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onTap: () => bloc.add(const ZoomViewport(factor: 1.2)),
              ),
              const SizedBox(width: 4),
              // Fit to content.
              _IconBtn(
                icon: Icons.fit_screen,
                tooltip: 'Fit to Content',
                onTap: () => bloc.add(const ZoomToFit()),
              ),
              // Reset to 100%.
              _IconBtn(
                icon: Icons.center_focus_strong,
                tooltip: 'Reset Zoom (100 %)',
                onTap: () => bloc.add(const ResetZoom()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomPill extends StatelessWidget {
  const _ZoomPill({
    required this.pct,
    required this.onPreset,
    required this.presets,
  });

  final int pct;
  final void Function(double) onPreset;
  final List<double> presets;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      onSelected: onPreset,
      tooltip: 'Zoom presets',
      itemBuilder: (_) => presets
          .map(
            (p) => PopupMenuItem<double>(
              value: p,
              child: Text('${(p * 100).round()} %'),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '$pct %',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
