import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/engine/stylus/pressure_curve.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';
import 'package:y2notes2/core/engine/stylus/stylus_gesture_handler.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Apple iOS-style stylus settings with grouped rounded sections.
class StylusSettingsPage extends StatelessWidget {
  const StylusSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Stylus')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionHeader('Detected Stylus'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.systemGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.draw_rounded,
                    size: 18, color: AppColors.systemGreen),
              ),
              title: const Text('Connect or use your stylus to detect'),
              subtitle: const Text(
                'Draw on the canvas to auto-detect Apple Pencil, S Pen, or USI pen',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _SectionHeader('Supported Features'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            ..._capabilityRows(context),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Gesture Actions'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _GestureMappingList(settings: settings),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Pressure Curve'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _PressureCurveSelector(settings: settings),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Tilt & Sensitivity'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _TiltSensitivitySlider(settings: settings),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Input Options'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _PalmRejectionToggle(settings: settings),
            _HoverPreviewToggle(settings: settings),
            _LeftHandModeToggle(settings: settings),
          ]),
        ],
      ),
    );
  }

  List<Widget> _capabilityRows(BuildContext context) {
    const rows = [
      (StylusType.applePencilPro, 'Apple Pencil Pro'),
      (StylusType.applePencil2, 'Apple Pencil 2'),
      (StylusType.samsungSPen, 'Samsung S Pen'),
      (StylusType.usiPen, 'USI Pen'),
    ];
    return rows.map((row) {
      final caps = StylusDetector.getCapabilities(row.$1).toList();
      return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        title: Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: caps.map((cap) {
            return Chip(
              label: Text(cap.name, style: const TextStyle(fontSize: 10)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      );
    }).toList();
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

// ─── Gesture mapping ──────────────────────────────────────────────────────────

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                  if (action != null) settings.setGestureMapping(gesture, action);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              ? AppColors.accent
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
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
                                    ? AppColors.accent
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
                              color: isSelected ? AppColors.accent : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Palm Rejection'),
          subtitle: const Text('Ignore accidental palm touches when stylus is active'),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Hover Preview'),
          subtitle: const Text('Show brush size circle when pen hovers above screen'),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Left-hand Mode'),
          subtitle: const Text('Mirror toolbar and cursor offset for left-handed use'),
          value: enabled,
          onChanged: settings.setLeftHandMode,
        ),
      );
}
