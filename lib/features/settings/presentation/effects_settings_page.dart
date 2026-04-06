import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/effects/engine/effect_registry.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Settings page: toggle effects, adjust intensity, theme, background.
class EffectsSettingsPage extends StatelessWidget {
  const EffectsSettingsPage({super.key, this.showEffectsOnly = false});

  /// When true, only show the effects section (deep-linked from /settings/effects).
  final bool showEffectsOnly;

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final bloc = context.read<CanvasBloc>();

    return Scaffold(
      appBar: AppBar(
        title: Text(showEffectsOnly ? 'Writing Effects' : 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (!showEffectsOnly) ...[
            _SectionHeader('Appearance'),
            _ThemeToggle(settings: settings),
            _PageTemplateSelector(bloc: bloc, settings: settings),
            const Divider(height: 24),
            _SectionHeader('Performance'),
            _MasterEffectsSwitch(bloc: bloc),
            _HapticsToggle(settings: settings),
            const Divider(height: 24),
          ],
          _SectionHeader('Writing Effects'),
          _EffectsList(settings: settings, bloc: bloc),
        ],
      ),
    );
  }
}

// ─── Section components ──────────────────────────────────────────────────────

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

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.darkModeNotifier,
        builder: (context, isDark, _) => SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch between light and dark theme'),
          value: isDark,
          onChanged: settings.setDarkMode,
        ),
      );
}

class _HapticsToggle extends StatelessWidget {
  const _HapticsToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.hapticsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Vibration feedback for tool interactions'),
          value: enabled,
          onChanged: settings.setHapticsEnabled,
        ),
      );
}

class _MasterEffectsSwitch extends StatelessWidget {
  const _MasterEffectsSwitch({required this.bloc});

  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => SwitchListTile(
          title: const Text('Writing Effects'),
          subtitle: const Text(
            'Master switch — disables all effects for maximum performance',
          ),
          value: state.effectsEnabled,
          onChanged: (v) => bloc.add(EffectsToggled(enabled: v)),
        ),
      );
}

class _PageTemplateSelector extends StatelessWidget {
  const _PageTemplateSelector({
    required this.bloc,
    required this.settings,
  });

  final CanvasBloc bloc;
  final SettingsService settings;

  static const _templates = [
    (PageTemplate.blank, 'Blank'),
    (PageTemplate.lined, 'Lined'),
    (PageTemplate.grid, 'Grid'),
    (PageTemplate.dotted, 'Dotted'),
    (PageTemplate.chalkboard, 'Chalkboard'),
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => ListTile(
          title: const Text('Page Template'),
          subtitle: Text(_labelFor(state.config.template)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPicker(context, state, bloc),
        ),
      );

  String _labelFor(PageTemplate t) =>
      _templates.firstWhere((e) => e.$1 == t).$2;

  void _showPicker(
    BuildContext context,
    CanvasState state,
    CanvasBloc bloc,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _templates
            .map(
              (entry) => ListTile(
                title: Text(entry.$2),
                leading: state.config.template == entry.$1
                    ? const Icon(Icons.check, color: Color(0xFF4A90D9))
                    : const SizedBox(width: 24),
                onTap: () {
                  bloc.add(CanvasConfigUpdated(
                    state.config.copyWith(template: entry.$1),
                  ));
                  settings.setPageTemplate(entry.$1.name);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EffectsList extends StatelessWidget {
  const _EffectsList({required this.settings, required this.bloc});

  final SettingsService settings;
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) {
    final effects = EffectRegistry.instance.all;
    if (effects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No effects registered yet.'),
      );
    }
    return Column(
      children: effects.map((effect) {
        return ValueListenableBuilder<bool>(
          valueListenable: settings.effectToggles[effect.id] ??
              ValueNotifier(effect.isEnabled),
          builder: (context, enabled, _) => Column(
            children: [
              SwitchListTile(
                title: Text(effect.name),
                subtitle: Text(effect.description),
                value: enabled,
                onChanged: (v) {
                  effect.isEnabled = v;
                  settings.setEffectEnabled(effect.id, v);
                },
              ),
              // Intensity slider
              if (enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ValueListenableBuilder<double>(
                    valueListenable: settings.effectIntensities[effect.id] ??
                        ValueNotifier(effect.intensity),
                    builder: (context, intensity, _) => Row(
                      children: [
                        const Text('Intensity', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: intensity,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            label: intensity.toStringAsFixed(1),
                            onChanged: (v) {
                              effect.intensity = v;
                              settings.setEffectIntensity(effect.id, v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
