import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main settings hub with navigation tiles to each settings category.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  static const _categories = [
    _SettingsCategory(
      icon: Icons.palette_outlined,
      title: 'General',
      subtitle: 'Appearance, haptics, and defaults',
      route: '/settings/general',
    ),
    _SettingsCategory(
      icon: Icons.note_alt_outlined,
      title: 'Canvas',
      subtitle: 'Page template, spacing, and margins',
      route: '/settings/canvas',
    ),
    _SettingsCategory(
      icon: Icons.auto_awesome_outlined,
      title: 'Writing Effects',
      subtitle: 'Ink effects and interaction animations',
      route: '/settings/effects',
    ),
    _SettingsCategory(
      icon: Icons.draw_outlined,
      title: 'Stylus',
      subtitle: 'Pressure, tilt, gestures, and palm rejection',
      route: '/settings/stylus',
    ),
    _SettingsCategory(
      icon: Icons.text_fields_outlined,
      title: 'Recognition',
      subtitle: 'Handwriting language, mode, and engine',
      route: '/settings/recognition',
    ),
    _SettingsCategory(
      icon: Icons.backup_outlined,
      title: 'Backup & Data',
      subtitle: 'Auto-save, export defaults, and storage',
      route: '/settings/backup',
    ),
    _SettingsCategory(
      icon: Icons.cloud_sync_outlined,
      title: 'Cloud Sync',
      subtitle: 'iCloud, Google Drive, OneDrive, Dropbox',
      route: '/settings/cloud-sync',
    ),
    _SettingsCategory(
      icon: Icons.info_outline,
      title: 'About',
      subtitle: 'Version, licenses, and credits',
      route: '/settings/about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return ListTile(
            leading: Icon(cat.icon, size: 28),
            title: Text(cat.title),
            subtitle: Text(
              cat.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => context.push(cat.route),
          );
        },
      ),
    );
  }
}

class _SettingsCategory {
  const _SettingsCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
