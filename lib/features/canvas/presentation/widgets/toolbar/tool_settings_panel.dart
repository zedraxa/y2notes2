import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_setting_definition.dart';
import 'package:biscuits/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_state.dart';

/// A bottom-sheet panel that exposes the active tool's custom parameters
/// (e.g. watercolor wetness, pastel chalkiness, glow intensity).
class ToolSettingsPanel extends StatelessWidget {
  const ToolSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      builder: (context, state) {
        final tool = state.activeDrawingTool;
        if (tool == null) {
          return const _EmptyPanel();
        }

        final schema = tool.settingsSchema;
        if (schema.isEmpty) {
          return _NoCustomSettingsPanel(toolName: tool.name);
        }

        return _SettingsContent(
          toolName: tool.name,
          schema: schema,
          settings: state.activeToolSettings,
          onSettingsChanged: (settings) =>
              context.read<CanvasBloc>().add(ToolSettingsChanged(settings)),
        );
      },
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No tool selected',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
}

class _NoCustomSettingsPanel extends StatelessWidget {
  const _NoCustomSettingsPanel({required this.toolName});

  final String toolName;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '$toolName has no adjustable settings.',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent({
    required this.toolName,
    required this.schema,
    required this.settings,
    required this.onSettingsChanged,
  });

  final String toolName;
  final List<ToolSettingDefinition> schema;
  final ToolSettings settings;
  final void Function(ToolSettings) onSettingsChanged;

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  late Map<String, dynamic> _custom;

  @override
  void initState() {
    super.initState();
    _custom = Map<String, dynamic>.of(widget.settings.custom);
    // Ensure all schema keys are present, filling missing ones with defaults.
    for (final def in widget.schema) {
      _custom.putIfAbsent(def.key, () => def.defaultValue);
    }
  }

  @override
  void didUpdateWidget(_SettingsContent old) {
    super.didUpdateWidget(old);
    if (old.settings != widget.settings) {
      _custom = Map<String, dynamic>.of(widget.settings.custom);
      for (final def in widget.schema) {
        _custom.putIfAbsent(def.key, () => def.defaultValue);
      }
    }
  }

  void _update(String key, dynamic value) {
    setState(() => _custom[key] = value);
    widget.onSettingsChanged(
      widget.settings.copyWith(custom: Map<String, dynamic>.of(_custom)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              Text(
                '${widget.toolName} Settings',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Settings rows ──────────────────────────────────────────────────
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: widget.schema.length,
          itemBuilder: (context, index) {
            final def = widget.schema[index];
            return _SettingRow(
              definition: def,
              value: _custom[def.key] ?? def.defaultValue,
              onChanged: (v) => _update(def.key, v),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ToolSettingDefinition definition;
  final dynamic value;
  final void Function(dynamic) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: switch (definition.type) {
        ToolSettingType.slider => _SliderRow(
            definition: definition,
            value: (value as num).toDouble(),
            onChanged: onChanged,
          ),
        ToolSettingType.toggle => _ToggleRow(
            definition: definition,
            value: value as bool,
            onChanged: onChanged,
          ),
        ToolSettingType.colorPicker => _ColorRow(
            definition: definition,
            value: value as Color,
            onChanged: onChanged,
          ),
        ToolSettingType.dropdown => _DropdownRow(
            definition: definition,
            value: value as String,
            onChanged: onChanged,
          ),
      },
    );
  }
}

// ── Slider ────────────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ToolSettingDefinition definition;
  final double value;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final min = (definition.min as num?)?.toDouble() ?? 0.0;
    final max = (definition.max as num?)?.toDouble() ?? 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(definition.label,
                style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Toggle ────────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ToolSettingDefinition definition;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(definition.label,
              style: Theme.of(context).textTheme.bodyMedium),
          Switch(value: value, onChanged: onChanged),
        ],
      );
}

// ── Color ─────────────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ToolSettingDefinition definition;
  final Color value;
  final void Function(Color) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(definition.label,
              style: Theme.of(context).textTheme.bodyMedium),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      );

  void _showColorPicker(BuildContext context) {
    // Simple hue-based picker using existing color swatches.
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () {
                onChanged(c);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: c == value
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Dropdown ──────────────────────────────────────────────────────────────────

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ToolSettingDefinition definition;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(definition.label,
              style: Theme.of(context).textTheme.bodyMedium),
          DropdownButton<String>(
            value: value,
            items: (definition.options ?? [])
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      );
}
