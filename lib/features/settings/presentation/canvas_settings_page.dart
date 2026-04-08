import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Canvas settings with Apple iOS-style grouped rounded sections.
class CanvasSettingsPage extends StatelessWidget {
  const CanvasSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final bloc = context.read<CanvasBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Canvas')),
      body: BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _SectionHeader('Page Template'),
            const SizedBox(height: 6),
            _GroupedSection(
              isDark: isDark,
              children: [
                _PageTemplateSelector(
                  bloc: bloc,
                  settings: settings,
                  current: state.config.template,
                  config: state.config,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Spacing'),
            const SizedBox(height: 6),
            _GroupedSection(
              isDark: isDark,
              children: [
                _SpacingSlider(
                  title: 'Line Spacing',
                  value: state.config.lineSpacing,
                  onChanged: (v) {
                    bloc.add(CanvasConfigUpdated(
                      state.config.copyWith(lineSpacing: v),
                    ));
                    settings.setLineSpacing(v);
                  },
                ),
                _SpacingSlider(
                  title: 'Grid Spacing',
                  value: state.config.gridSpacing,
                  onChanged: (v) {
                    bloc.add(CanvasConfigUpdated(
                      state.config.copyWith(gridSpacing: v),
                    ));
                    settings.setGridSpacing(v);
                  },
                ),
                _SpacingSlider(
                  title: 'Dot Spacing',
                  value: state.config.dotSpacing,
                  onChanged: (v) {
                    bloc.add(CanvasConfigUpdated(
                      state.config.copyWith(dotSpacing: v),
                    ));
                    settings.setDotSpacing(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Layout'),
            const SizedBox(height: 6),
            _GroupedSection(
              isDark: isDark,
              children: [
                _MarginToggle(
                  bloc: bloc,
                  settings: settings,
                  showMargin: state.config.showMargin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grouped section ────────────────────────────────────────────────────────

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({
    required this.isDark,
    required this.children,
  });

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 20,
                color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
              ),
            children[i],
          ],
        ],
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
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
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
    (PageTemplate.blank, 'Blank', Icons.crop_square_rounded),
    (PageTemplate.lined, 'Lined', Icons.format_align_left_rounded),
    (PageTemplate.grid, 'Grid', Icons.grid_on_rounded),
    (PageTemplate.dotted, 'Dotted', Icons.more_horiz_rounded),
    (PageTemplate.chalkboard, 'Chalkboard', Icons.dashboard_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _templates.map((entry) {
          final isSelected = current == entry.$1;
          return ChoiceChip(
            avatar: Icon(entry.$3, size: 16),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
  const _MarginToggle({
    required this.bloc,
    required this.settings,
    required this.showMargin,
  });

  final CanvasBloc bloc;
  final SettingsService settings;
  final bool showMargin;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: const Text('Show Margin'),
        subtitle: const Text('Display a vertical margin line on the page'),
        value: showMargin,
        onChanged: (v) {
          final state = bloc.state;
          bloc.add(CanvasConfigUpdated(
            state.config.copyWith(showMargin: v),
          ));
          settings.setShowMargin(v);
        },
      );
}
