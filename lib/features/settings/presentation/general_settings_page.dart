import 'package:flutter/material.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

/// General settings: appearance (dark mode), haptic feedback, and default
/// tool size.
class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('General'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Appearance'),
          _DarkModeToggle(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Feedback'),
          _HapticsToggle(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Defaults'),
          _DefaultToolSizeSlider(settings: settings),
          _AutoSaveIntervalSlider(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Navigation'),
          _PageGesturesToggle(settings: settings),
          _PageGestureHapticsToggle(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Data'),
          _ResetTile(settings: settings),
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

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
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
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.hapticsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
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
          title: const Text('Page Gestures'),
          subtitle: const Text(
            'Swipe with two fingers or from the screen edge to change pages',
          ),
          value: enabled,
          onChanged: settings.setPageGesturesEnabled,
        ),
      );
}

class _PageGestureHapticsToggle extends StatelessWidget {
  const _PageGestureHapticsToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.pageGestureHapticsEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          title: const Text('Page Turn Haptics'),
          subtitle: const Text('Haptic pulse when a page-turn gesture commits'),
          value: enabled,
          onChanged: settings.setPageGestureHapticsEnabled,
        ),
      );
}

class _ResetTile extends StatelessWidget {
  const _ResetTile({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ListTile(
        leading:
            Icon(Icons.restore, color: Theme.of(context).colorScheme.error),
        title: const Text('Reset All Settings'),
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
                TextButton(
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
                const SnackBar(content: Text('Settings restored to defaults')),
              );
            }
          }
        },
      );
}
