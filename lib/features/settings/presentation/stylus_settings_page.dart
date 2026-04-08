import 'package:flutter/material.dart';
import 'package:biscuits/core/engine/stylus/pressure_curve.dart';
import 'package:biscuits/core/engine/stylus/stylus_detector.dart';
import 'package:biscuits/core/engine/stylus/stylus_gesture_handler.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

/// Full-featured stylus settings page.
///
/// Displays:
/// - Detected stylus type and capability badges
/// - Double-tap, squeeze, and barrel button action pickers
/// - Pressure curve selector with visual preview
/// - Tilt sensitivity slider
/// - Palm rejection, hover preview, and left-hand mode toggles
class StylusSettingsPage extends StatelessWidget {
  /// Creates the stylus settings page.
  const StylusSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Stylus Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _StylusStatusSection(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Gesture Actions'),
          _GestureMappingList(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Pressure Curve'),
          _PressureCurveSelector(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Tilt & Sensitivity'),
          _TiltSensitivitySlider(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Input Options'),
          _PalmRejectionToggle(settings: settings),
          _HoverPreviewToggle(settings: settings),
          _LeftHandModeToggle(settings: settings),
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

// ─── Stylus status ────────────────────────────────────────────────────────────

/// Shows the last detected stylus type with capability badges.
///
/// The detected type is stored in [SettingsService] so the settings page can
/// display it without requiring a live [CanvasBloc] in the widget tree.
class _StylusStatusSection extends StatelessWidget {
  const _StylusStatusSection({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    // The detected type is stored in pressureCurvePresetNotifier as a proxy;
    // for now we show a static "connect your stylus and draw to detect" hint.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Detected Stylus'),
        ListTile(
          leading: Icon(
            Icons.draw_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Connect or use your stylus to detect'),
          subtitle: const Text(
            'Draw on the canvas to auto-detect Apple Pencil, S Pen, or USI pen',
          ),
          trailing: const Icon(Icons.info_outline),
        ),
        _SectionHeader('Supported Features'),
        const _CapabilityLegend(),
      ],
    );
  }
}

/// Shows a legend of stylus capabilities grouped by device.
class _CapabilityLegend extends StatelessWidget {
  const _CapabilityLegend();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (StylusType.applePencilPro, 'Apple Pencil Pro'),
      (StylusType.applePencil2, 'Apple Pencil 2'),
      (StylusType.samsungSPen, 'Samsung S Pen'),
      (StylusType.usiPen, 'USI Pen'),
    ];
    return Column(
      children: rows.map((row) {
        final caps = StylusDetector.getCapabilities(row.$1).toList();
        return ListTile(
          dense: true,
          title: Text(row.$2,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: caps.map((cap) {
              return Chip(
                label: Text(cap.name, style: const TextStyle(fontSize: 10)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gesture mapping list ─────────────────────────────────────────────────────

class _GestureMappingList extends StatelessWidget {
  const _GestureMappingList({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: StylusGesture.values.map((gesture) {
        final notifier = settings.gestureMappings[gesture.name];
        if (notifier == null) return const SizedBox.shrink();
        return ValueListenableBuilder<String>(
          valueListenable: notifier,
          builder: (context, actionName, _) {
            final currentAction = StylusGestureAction.values.firstWhere(
              (a) => a.name == actionName,
              orElse: () => StylusGestureAction.none,
            );
            return ListTile(
              title: Text(StylusGestureHandler.gestureLabel(gesture)),
              trailing: DropdownButton<StylusGestureAction>(
                value: currentAction,
                underline: const SizedBox.shrink(),
                items: StylusGestureAction.values.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(
                      StylusGestureHandler.actionLabel(action),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (action) {
                  if (action != null) {
                    settings.setGestureMapping(gesture, action);
                  }
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

// ─── Pressure curve ───────────────────────────────────────────────────────────

class _PressureCurveSelector extends StatelessWidget {
  const _PressureCurveSelector({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: settings.pressureCurvePresetNotifier,
      builder: (context, presetName, _) {
        final current = PressureCurvePreset.values.firstWhere(
          (p) => p.name == presetName,
          orElse: () => PressureCurvePreset.soft,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Pressure Curve: ${PressureCurve.fromPreset(current).displayName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: PressureCurvePreset.values
                    .where((p) => p != PressureCurvePreset.custom)
                    .length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final preset = PressureCurvePreset.values
                      .where((p) => p != PressureCurvePreset.custom)
                      .elementAt(index);
                  final curve = PressureCurve.fromPreset(preset);
                  final isSelected = preset == current;
                  return GestureDetector(
                    onTap: () => settings.setPressureCurvePreset(preset),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 40,
                            child: CustomPaint(
                              painter: _CurvePreviewPainter(
                                curve: curve,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                            ),
                          ),
                          Text(
                            curve.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CurvePreviewPainter extends CustomPainter {
  const _CurvePreviewPainter({required this.curve, required this.color});

  final PressureCurve curve;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    curve.paintPreview(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      curvePaint: Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_CurvePreviewPainter old) =>
      old.curve != curve || old.color != color;
}

// ─── Tilt sensitivity ─────────────────────────────────────────────────────────

class _TiltSensitivitySlider extends StatelessWidget {
  const _TiltSensitivitySlider({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<double>(
        valueListenable: settings.tiltSensitivityNotifier,
        builder: (context, value, _) => ListTile(
          title: const Text('Tilt Sensitivity'),
          subtitle: Slider(
            value: value,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: value.toStringAsFixed(1),
            onChanged: settings.setTiltSensitivity,
          ),
          trailing: Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
}

// ─── Input option toggles ─────────────────────────────────────────────────────

class _PalmRejectionToggle extends StatelessWidget {
  const _PalmRejectionToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.palmRejectionEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Palm Rejection'),
          subtitle: const Text(
            'Ignore accidental palm touches when stylus is active',
          ),
          value: enabled,
          onChanged: settings.setPalmRejectionEnabled,
        ),
      );
}

class _HoverPreviewToggle extends StatelessWidget {
  const _HoverPreviewToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.hoverPreviewEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Hover Preview'),
          subtitle: const Text(
            'Show brush size circle when pen hovers above screen',
          ),
          value: enabled,
          onChanged: settings.setHoverPreviewEnabled,
        ),
      );
}

class _LeftHandModeToggle extends StatelessWidget {
  const _LeftHandModeToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
        valueListenable: settings.leftHandModeNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Left-hand Mode'),
          subtitle: const Text(
            'Mirror toolbar and cursor offset for left-handed use',
          ),
          value: enabled,
          onChanged: settings.setLeftHandMode,
        ),
      );
}
