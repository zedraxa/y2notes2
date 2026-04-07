import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/core/extensions/iterable_extensions.dart';
import 'package:biscuitse/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuitse/features/canvas/presentation/bloc/canvas_state.dart';
import '../../domain/entities/shape_element.dart';
import '../../domain/entities/shape_type.dart';
import '../bloc/shape_bloc.dart';
import '../bloc/shape_event.dart';
import '../bloc/shape_state.dart';

/// Bottom-sheet panel that appears when a shape is selected.
///
/// Provides controls for fill, stroke, opacity, corner radius, fill pattern,
/// and shape type switching.
class ShapePropertiesPanel extends StatelessWidget {
  const ShapePropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShapeBloc, ShapeState>(
      builder: (context, shapeState) {
        final selectedId = shapeState.selectedShapeId;
        if (selectedId == null) return const SizedBox.shrink();
        return BlocBuilder<CanvasBloc, CanvasState>(
          buildWhen: (p, c) => p.shapes != c.shapes,
          builder: (context, canvasState) {
            final shape = canvasState.shapes
                .where((s) => s.id == selectedId)
                .firstOrNull;
            if (shape == null) return const SizedBox.shrink();
            return _PanelContent(shape: shape);
          },
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.shape});

  final ShapeElement shape;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ShapeBloc>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            _shapeLabel(shape.type),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // ── Stroke colour ────────────────────────────────────────────────
          _SectionLabel('Stroke colour'),
          _ColorRow(
            colors: _palette,
            selected: shape.strokeColor,
            onSelected: (c) =>
                bloc.add(ShapeStyleUpdated(strokeColor: c)),
          ),

          // ── Fill toggle + colour ─────────────────────────────────────────
          Row(
            children: [
              const _SectionLabel('Fill'),
              const Spacer(),
              Switch(
                value: shape.isFilled,
                onChanged: (v) =>
                    bloc.add(ShapeStyleUpdated(isFilled: v)),
              ),
            ],
          ),
          if (shape.isFilled) ...[
            _ColorRow(
              colors: _fillPalette,
              selected: shape.fillColor,
              onSelected: (c) =>
                  bloc.add(ShapeStyleUpdated(fillColor: c)),
            ),
            const SizedBox(height: 8),
            _SectionLabel('Fill pattern'),
            _FillPatternRow(
              selected: shape.fillPattern,
              onSelected: (p) =>
                  bloc.add(ShapeStyleUpdated(fillPattern: p)),
            ),
          ],

          // ── Stroke width ─────────────────────────────────────────────────
          _LabeledSlider(
            label: 'Stroke width',
            value: shape.strokeWidth,
            min: 0.5,
            max: 16.0,
            onChanged: (v) =>
                bloc.add(ShapeStyleUpdated(strokeWidth: v)),
          ),

          // ── Corner radius (rectangles only) ──────────────────────────────
          if (shape.type == ShapeType.rectangle ||
              shape.type == ShapeType.square)
            _LabeledSlider(
              label: 'Corner radius',
              value: shape.cornerRadius,
              min: 0.0,
              max: 60.0,
              onChanged: (v) =>
                  bloc.add(ShapeStyleUpdated(cornerRadius: v)),
            ),

          // ── Opacity ──────────────────────────────────────────────────────
          _LabeledSlider(
            label: 'Opacity',
            value: shape.opacity,
            min: 0.1,
            max: 1.0,
            onChanged: (v) =>
                bloc.add(ShapeStyleUpdated(opacity: v)),
          ),

          // ── Shape type switcher ──────────────────────────────────────────
          const SizedBox(height: 8),
          _SectionLabel('Shape type'),
          const SizedBox(height: 6),
          _ShapeTypeSwitcher(
            current: shape.type,
            onSelected: (t) => bloc.add(ShapeTypeChanged(t)),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const _palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  static const _fillPalette = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF9C4),
    Color(0xFFB3E5FC),
    Color(0xFFC8E6C9),
    Color(0xFFFFCCBC),
    Color(0xFFE1BEE7),
    Color(0xFFCFD8DC),
    Color(0xFFFFE0B2),
  ];
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.grey.shade600)),
      );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: colors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = colors[i];
            final isSelected = c.value == selected.value;
            return GestureDetector(
              onTap: () => onSelected(c),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _FillPatternRow extends StatelessWidget {
  const _FillPatternRow(
      {required this.selected, required this.onSelected});

  final ShapeFillPattern selected;
  final ValueChanged<ShapeFillPattern> onSelected;

  @override
  Widget build(BuildContext context) {
    const patterns = ShapeFillPattern.values;
    return Row(
      children: patterns.map((p) {
        final isSelected = p == selected;
        return GestureDetector(
          onTap: () => onSelected(p),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              _patternLabel(p),
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _patternLabel(ShapeFillPattern p) {
    switch (p) {
      case ShapeFillPattern.solid:
        return 'Solid';
      case ShapeFillPattern.hatched:
        return 'Hatched';
      case ShapeFillPattern.dotted:
        return 'Dotted';
      case ShapeFillPattern.crosshatch:
        return 'Cross';
      case ShapeFillPattern.none:
        return 'None';
    }
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
}

class _ShapeTypeSwitcher extends StatelessWidget {
  const _ShapeTypeSwitcher(
      {required this.current, required this.onSelected});

  final ShapeType current;
  final ValueChanged<ShapeType> onSelected;

  static const _types = [
    ShapeType.rectangle,
    ShapeType.square,
    ShapeType.circle,
    ShapeType.ellipse,
    ShapeType.triangle,
    ShapeType.line,
    ShapeType.arrow,
    ShapeType.star,
    ShapeType.diamond,
    ShapeType.pentagon,
    ShapeType.hexagon,
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _types.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final t = _types[i];
            final isSelected = t == current;
            return GestureDetector(
              onTap: () => onSelected(t),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    _shapeLabel(t),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

String _shapeLabel(ShapeType t) {
  switch (t) {
    case ShapeType.rectangle:
      return 'Rect';
    case ShapeType.square:
      return 'Square';
    case ShapeType.circle:
      return 'Circle';
    case ShapeType.ellipse:
      return 'Ellipse';
    case ShapeType.triangle:
      return 'Triangle';
    case ShapeType.line:
      return 'Line';
    case ShapeType.arrow:
      return 'Arrow';
    case ShapeType.star:
      return 'Star';
    case ShapeType.diamond:
      return 'Diamond';
    case ShapeType.pentagon:
      return 'Pentagon';
    case ShapeType.hexagon:
      return 'Hexagon';
    case ShapeType.freeform:
      return 'Free';
  }
}
