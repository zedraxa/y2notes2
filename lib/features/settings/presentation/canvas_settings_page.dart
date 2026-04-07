import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Canvas settings: page template, line/grid/dot spacing, and margin toggle.
class CanvasSettingsPage extends StatelessWidget {
  const CanvasSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final bloc = context.read<CanvasBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Canvas')),
      body: BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader('Page Template'),
            _PageTemplateSelector(
              bloc: bloc,
              settings: settings,
              current: state.config.template,
              config: state.config,
            ),
            const Divider(height: 24),
            _SectionHeader('Spacing'),
            _SpacingSlider(
              title: 'Line Spacing',
              value: state.config.lineSpacing,
              onChanged: (v) => bloc.add(CanvasConfigUpdated(
                state.config.copyWith(lineSpacing: v),
              )),
            ),
            _SpacingSlider(
              title: 'Grid Spacing',
              value: state.config.gridSpacing,
              onChanged: (v) => bloc.add(CanvasConfigUpdated(
                state.config.copyWith(gridSpacing: v),
              )),
            ),
            _SpacingSlider(
              title: 'Dot Spacing',
              value: state.config.dotSpacing,
              onChanged: (v) => bloc.add(CanvasConfigUpdated(
                state.config.copyWith(dotSpacing: v),
              )),
            ),
            const Divider(height: 24),
            _SectionHeader('Layout'),
            _MarginToggle(bloc: bloc, showMargin: state.config.showMargin),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────────

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

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _PageTemplateSelector extends StatelessWidget {
  const _PageTemplateSelector({
    required this.bloc,
    required this.settings,
    required this.current,
    required this.config,
  });

  final CanvasBloc bloc;
  final SettingsService settings;
  final PageTemplate current;
  final CanvasConfig config;

  static const _templates = [
    (PageTemplate.blank, 'Blank', Icons.crop_square_outlined),
    (PageTemplate.lined, 'Lined', Icons.format_align_left),
    (PageTemplate.grid, 'Grid', Icons.grid_on),
    (PageTemplate.dotted, 'Dotted', Icons.more_horiz),
    (PageTemplate.chalkboard, 'Chalkboard', Icons.dashboard_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _templates.map((entry) {
          final isSelected = current == entry.$1;
          return ChoiceChip(
            avatar: Icon(entry.$3, size: 18),
            label: Text(entry.$2),
            selected: isSelected,
            onSelected: (_) {
              bloc.add(CanvasConfigUpdated(
                config.copyWith(template: entry.$1),
              ));
              settings.setPageTemplate(entry.$1.name);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SpacingSlider extends StatelessWidget {
  const _SpacingSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        subtitle: Slider(
          value: value,
          min: 16.0,
          max: 64.0,
          divisions: 24,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
        trailing: Text(
          '${value.round()}px',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}

class _MarginToggle extends StatelessWidget {
  const _MarginToggle({required this.bloc, required this.showMargin});

  final CanvasBloc bloc;
  final bool showMargin;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: const Text('Show Margin'),
        subtitle: const Text('Display a vertical margin line on the page'),
        value: showMargin,
        onChanged: (v) {
          final state = bloc.state;
          bloc.add(CanvasConfigUpdated(
            state.config.copyWith(showMargin: v),
          ));
        },
      );
}
