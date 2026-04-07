import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub page for all settings, organized into categories.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.tune,
            title: 'General',
            subtitle: 'Appearance, haptics, reset',
            onTap: () => context.go('/settings/general'),
          ),
          _SettingsTile(
            icon: Icons.grid_on,
            title: 'Canvas',
            subtitle: 'Page template, spacing, margins',
            onTap: () => context.go('/settings/canvas'),
          ),
          _SettingsTile(
            icon: Icons.auto_awesome,
            title: 'Effects',
            subtitle: 'Writing effects, interaction effects',
            onTap: () => context.go('/settings/effects'),
          ),
          _SettingsTile(
            icon: Icons.draw_outlined,
            title: 'Stylus',
            subtitle: 'Pressure, tilt, gestures, palm rejection',
            onTap: () => context.go('/settings/stylus'),
          ),
          _SettingsTile(
            icon: Icons.text_fields,
            title: 'Recognition',
            subtitle: 'Language, mode, confidence',
            onTap: () => context.go('/settings/recognition'),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version, licenses',
            onTap: () => context.go('/settings/about'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
