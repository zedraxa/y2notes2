import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// General settings: Apple iOS Settings-style with grouped rounded sections.
class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _DarkModeToggle(settings: settings),
            ],
          ),
          const SizedBox(height: 24),
          // ── Feedback ────────────────────────────────────────────────────
          _SectionHeader('Feedback'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _HapticsToggle(settings: settings),
            ],
          ),
          const SizedBox(height: 24),
          // ── Defaults ────────────────────────────────────────────────────
          _SectionHeader('Defaults'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _DefaultToolSizeSlider(settings: settings),
              _AutoSaveIntervalSlider(settings: settings),
            ],
          ),
          const SizedBox(height: 24),
          // ── Navigation ──────────────────────────────────────────────────
          _SectionHeader('Navigation'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _PageGesturesToggle(settings: settings),
            ],
          ),
          const SizedBox(height: 24),
          // ── Data ────────────────────────────────────────────────────────
          _SectionHeader('Data'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _ResetTile(settings: settings),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── iOS-style grouped section container ────────────────────────────────────

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

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.darkModeNotifier,
        builder: (context, isDark, _) => SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.hapticsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Vibration feedback for tool interactions'),
          value: enabled,
          onChanged: settings.setHapticsEnabled,
        ),
      );
}

class _DefaultToolSizeSlider extends StatelessWidget {
  const _DefaultToolSizeSlider({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: settings.defaultToolSizeNotifier,
        builder: (context, value, _) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Default Pen Size'),
          subtitle: Slider(
            value: value,
            min: 0.5,
            max: 20.0,
            divisions: 39,
            label: value.toStringAsFixed(1),
            onChanged: settings.setDefaultToolSize,
          ),
          trailing: Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
}

class _AutoSaveIntervalSlider extends StatelessWidget {
  const _AutoSaveIntervalSlider({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: settings.autoSaveIntervalNotifier,
        builder: (context, seconds, _) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Auto-save Interval'),
          subtitle: Slider(
            value: seconds.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: _formatInterval(seconds),
            onChanged: (v) => settings.setAutoSaveInterval(v.round()),
          ),
          trailing: Text(
            _formatInterval(seconds),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );

  String _formatInterval(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (remaining == 0) return '${minutes}m';
    return '${minutes}m ${remaining}s';
  }
}

class _PageGesturesToggle extends StatelessWidget {
  const _PageGesturesToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.pageGesturesEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Page Gestures'),
          subtitle: const Text(
            'Swipe with two fingers or from the screen edge to change pages',
          ),
          value: enabled,
          onChanged: settings.setPageGesturesEnabled,
        ),
      );
}

class _ResetTile extends StatelessWidget {
  const _ResetTile({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          'Reset All Settings',
          style: TextStyle(color: AppColors.systemRed),
        ),
        subtitle: const Text('Restore every setting to its default value'),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reset All Settings?'),
              content: const Text(
                'This will restore every setting to its default value. '
                'Your notebooks and drawings will not be affected.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.systemRed,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reset'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await settings.resetAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Settings restored to defaults')),
              );
            }
          }
        },
      );
}
