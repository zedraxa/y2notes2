import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Canvas settings: page template, spacing, margins.
class CanvasSettingsPage extends StatelessWidget {
  const CanvasSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final bloc = context.read<CanvasBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Canvas')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Page Template'),
          _PageTemplateSelector(bloc: bloc, settings: settings),
          const Divider(height: 24),
          _SectionHeader('Spacing'),
          _SpacingSlider(
            label: 'Line Spacing',
            notifier: settings.lineSpacingNotifier,
            onChanged: (v) {
              settings.setLineSpacing(v);
              final state = bloc.state;
              bloc.add(CanvasConfigUpdated(
                state.config.copyWith(lineSpacing: v),
              ));
            },
          ),
          _SpacingSlider(
            label: 'Grid Spacing',
            notifier: settings.gridSpacingNotifier,
            onChanged: (v) {
              settings.setGridSpacing(v);
              final state = bloc.state;
              bloc.add(CanvasConfigUpdated(
                state.config.copyWith(gridSpacing: v),
              ));
            },
          ),
          _SpacingSlider(
            label: 'Dot Spacing',
            notifier: settings.dotSpacingNotifier,
            onChanged: (v) {
              settings.setDotSpacing(v);
              final state = bloc.state;
              bloc.add(CanvasConfigUpdated(
                state.config.copyWith(dotSpacing: v),
              ));
            },
          ),
          const Divider(height: 24),
          _SectionHeader('Layout'),
          _MarginToggle(settings: settings, bloc: bloc),
        ],
      ),
    );
  }
}

// ─── Shared section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}

// ─── Page template ────────────────────────────────────────────────────────────

class _PageTemplateSelector extends StatelessWidget {
  const _PageTemplateSelector({
    required this.bloc,
    required this.settings,
  });

  final CanvasBloc bloc;
  final SettingsService settings;

  static const _templates = [
    (PageTemplate.blank, 'Blank', Icons.crop_square),
    (PageTemplate.lined, 'Lined', Icons.format_line_spacing),
    (PageTemplate.grid, 'Grid', Icons.grid_on),
    (PageTemplate.dotted, 'Dotted', Icons.grain),
    (PageTemplate.chalkboard, 'Chalkboard', Icons.school),
  ];

  @override
  Widget build(BuildContext context) => BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _templates.map((entry) {
              final isSelected = state.config.template == entry.$1;
              return ChoiceChip(
                avatar: Icon(entry.$3, size: 18),
                label: Text(entry.$2),
                selected: isSelected,
                onSelected: (_) {
                  bloc.add(CanvasConfigUpdated(
                    state.config.copyWith(template: entry.$1),
                  ));
                  settings.setPageTemplate(entry.$1.name);
                },
              );
            }).toList(),
          ),
        ),
      );
}

// ─── Spacing sliders ──────────────────────────────────────────────────────────

class _SpacingSlider extends StatelessWidget {
  const _SpacingSlider({
    required this.label,
    required this.notifier,
    required this.onChanged,
  });

  final String label;
  final ValueNotifier<double> notifier;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: notifier,
        builder: (context, value, _) => ListTile(
          title: Text(label),
          subtitle: Slider(
            value: value,
            min: 16.0,
            max: 64.0,
            divisions: 24,
            label: '${value.round()} px',
            onChanged: onChanged,
          ),
          trailing: Text(
            '${value.round()} px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
}

// ─── Margin toggle ────────────────────────────────────────────────────────────

class _MarginToggle extends StatelessWidget {
  const _MarginToggle({required this.settings, required this.bloc});

  final SettingsService settings;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.showMarginNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Show Margin'),
          subtitle: const Text('Draw a margin line on lined templates'),
          value: enabled,
          onChanged: (v) {
            settings.setShowMargin(v);
            final state = bloc.state;
            bloc.add(CanvasConfigUpdated(
              state.config.copyWith(showMargin: v),
            ));
          },
        ),
      );
}
