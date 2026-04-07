import 'package:flutter/material.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// General settings: appearance, performance, and reset.
class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Appearance'),
          _ThemeToggle(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Performance'),
          _HapticsToggle(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Data'),
          _ResetTile(settings: settings),
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

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.settings});

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
