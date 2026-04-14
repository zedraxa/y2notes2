import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:biscuits/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:biscuits/features/effects/engine/effect_registry.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

/// Settings page: toggle effects, adjust intensity.
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Effects'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Performance'),
          _MasterEffectsSwitch(bloc: bloc),
          const Divider(height: 24),
          _SectionHeader('Writing Effects'),
          _EffectsList(settings: settings, bloc: bloc),
          const Divider(height: 24),
          _SectionHeader('Interaction Effects'),
          _InteractionEffectsMasterSwitch(settings: settings),
          _InteractionEffectsList(settings: settings),
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

// ─── Interaction effects UI ───────────────────────────────────────────────────

/// Human-readable labels for each interaction effect ID.
const _kInteractionEffectMeta = {
  'touch_ripple': (
    name: 'Touch Ripple',
    desc: 'Expanding ripple where you touch the canvas.',
  ),
  'snap_glow': (
    name: 'Snap Glow',
    desc: 'Neon glow when shapes snap to alignment guides.',
  ),
  'selection_pulse': (
    name: 'Selection Pulse',
    desc: 'Pulsing animated border on selected elements.',
  ),
  'delete_animation': (
    name: 'Delete Animation',
    desc: 'Fragment/dissolve animation when deleting elements.',
  ),
  'drag_shadow': (
    name: 'Drag Shadow',
    desc: 'Elevated shadow and ghost while dragging elements.',
  ),
  'pinch_zoom': (
    name: 'Pinch Zoom',
    desc: 'Zoom level indicator and vignette during pinch-zoom.',
  ),
  'page_turn': (
    name: 'Page Turn',
    desc: '3D page curl animation when switching pages.',
  ),
  'undo_redo': (
    name: 'Undo/Redo Flash',
    desc: 'Colour flash when undoing or redoing actions.',
  ),
  'tool_switch': (
    name: 'Tool Switch Sparkle',
    desc: 'Particle sparkle when switching drawing tools.',
  ),
  'edge_bounce': (
    name: 'Edge Bounce',
    desc: 'Gradient glow when panning hits the canvas boundary.',
  ),
};

class _InteractionEffectsMasterSwitch extends StatelessWidget {
  const _InteractionEffectsMasterSwitch({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.interactionEffectsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Interaction Effects'),
          subtitle: const Text(
            'Master switch — disables all interaction effects',
          ),
          value: enabled,
          onChanged: settings.setInteractionEffectsEnabled,
        ),
      );
}

class _InteractionEffectsList extends StatelessWidget {
  const _InteractionEffectsList({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: settings.interactionEffectsEnabledNotifier,
      builder: (context, masterEnabled, _) => Column(
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
                          const Text(
                            'Intensity',
                            style: TextStyle(fontSize: 12),
                          ),
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
