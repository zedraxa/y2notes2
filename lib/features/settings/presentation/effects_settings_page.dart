import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/effects/engine/effect_registry.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Effects settings with Apple iOS-style grouped rounded sections.
class EffectsSettingsPage extends StatelessWidget {
  const EffectsSettingsPage({super.key, this.showEffectsOnly = false});

  final bool showEffectsOnly;

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final bloc = context.read<CanvasBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Effects')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionHeader('Performance'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _MasterEffectsSwitch(bloc: bloc),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Writing Effects'),
          const SizedBox(height: 6),
          _EffectsList(settings: settings, bloc: bloc, isDark: isDark),
          const SizedBox(height: 24),
          _SectionHeader('Interaction Effects'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _InteractionEffectsMasterSwitch(settings: settings),
          ]),
          const SizedBox(height: 12),
          _InteractionEffectsList(settings: settings, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Shared components ────────────────────────────────────────────────────────

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

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({required this.isDark, required this.children});
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
                height: 0.5, thickness: 0.5, indent: 20,
                color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MasterEffectsSwitch extends StatelessWidget {
  const _MasterEffectsSwitch({required this.bloc});
  final CanvasBloc bloc;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasBloc, CanvasState>(
        bloc: bloc,
        builder: (context, state) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Writing Effects'),
          subtitle: const Text(
            'Master switch — disables all effects for maximum performance',
          ),
          value: state.effectsEnabled,
          onChanged: (v) => bloc.add(EffectsToggled(enabled: v)),
        ),
      );
}

class _EffectsList extends StatelessWidget {
  const _EffectsList({required this.settings, required this.bloc, required this.isDark});
  final SettingsService settings;
  final CanvasBloc bloc;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final effects = EffectRegistry.instance.all;
    if (effects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No effects registered yet.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return _GroupedSection(
      isDark: isDark,
      children: effects.map((effect) {
        return ValueListenableBuilder<bool>(
          valueListenable: settings.effectToggles[effect.id] ??
              ValueNotifier(effect.isEnabled),
          builder: (context, enabled, _) => Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Text(effect.name),
                subtitle: Text(effect.description),
                value: enabled,
                onChanged: (v) {
                  effect.isEnabled = v;
                  settings.setEffectEnabled(effect.id, v);
                },
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ValueListenableBuilder<double>(
                    valueListenable: settings.effectIntensities[effect.id] ??
                        ValueNotifier(effect.intensity),
                    builder: (context, intensity, _) => Row(
                      children: [
                        Text('Intensity',
                            style: Theme.of(context).textTheme.bodySmall),
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

// ─── Interaction effects ──────────────────────────────────────────────────────

const _kInteractionEffectMeta = {
  'touch_ripple': (name: 'Touch Ripple', desc: 'Expanding ripple where you touch the canvas.'),
  'snap_glow': (name: 'Snap Glow', desc: 'Neon glow when shapes snap to alignment guides.'),
  'selection_pulse': (name: 'Selection Pulse', desc: 'Pulsing animated border on selected elements.'),
  'delete_animation': (name: 'Delete Animation', desc: 'Fragment/dissolve animation when deleting elements.'),
  'drag_shadow': (name: 'Drag Shadow', desc: 'Elevated shadow and ghost while dragging elements.'),
  'pinch_zoom': (name: 'Pinch Zoom', desc: 'Zoom level indicator and vignette during pinch-zoom.'),
  'page_turn': (name: 'Page Turn', desc: '3D page curl animation when switching pages.'),
  'undo_redo': (name: 'Undo/Redo Flash', desc: 'Colour flash when undoing or redoing actions.'),
  'tool_switch': (name: 'Tool Switch Sparkle', desc: 'Particle sparkle when switching drawing tools.'),
  'edge_bounce': (name: 'Edge Bounce', desc: 'Gradient glow when panning hits the canvas boundary.'),
};

class _InteractionEffectsMasterSwitch extends StatelessWidget {
  const _InteractionEffectsMasterSwitch({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.interactionEffectsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Interaction Effects'),
          subtitle: const Text('Master switch — disables all interaction effects'),
          value: enabled,
          onChanged: settings.setInteractionEffectsEnabled,
        ),
      );
}

class _InteractionEffectsList extends StatelessWidget {
  const _InteractionEffectsList({required this.settings, required this.isDark});
  final SettingsService settings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: settings.interactionEffectsEnabledNotifier,
      builder: (context, masterEnabled, _) => _GroupedSection(
        isDark: isDark,
        children: SettingsService.interactionEffectNames.map((id) {
          final meta = _kInteractionEffectMeta[id];
          final label = meta?.name ?? id;
          final desc = meta?.desc ?? '';
          return ValueListenableBuilder<bool>(
            valueListenable:
                settings.interactionEffectToggles[id] ?? ValueNotifier(true),
            builder: (context, enabled, _) => Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: Text(label),
                  subtitle: Text(desc),
                  value: enabled && masterEnabled,
                  onChanged: masterEnabled
                      ? (v) => settings.setInteractionEffectEnabled(id, v)
                      : null,
                ),
                if (enabled && masterEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ValueListenableBuilder<double>(
                      valueListenable:
                          settings.interactionEffectIntensities[id] ??
                              ValueNotifier(1.0),
                      builder: (context, intensity, _) => Row(
                        children: [
                          Text('Intensity',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: intensity,
                              min: 0.0,
                              max: 2.0,
                              divisions: 20,
                              label: intensity.toStringAsFixed(1),
                              onChanged: (v) =>
                                  settings.setInteractionEffectIntensity(id, v),
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
      ),
    );
  }
}
