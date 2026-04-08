import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:y2notes2/app/theme/colors.dart';

/// Apple Settings-style home page with grouped rounded sections and
/// icon-tinted leading circles.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  static const _categories = [
    _SettingsCategory(
      icon: Icons.paintbrush_rounded,
      iconColor: AppColors.systemOrange,
      title: 'General',
      subtitle: 'Appearance, haptics, and defaults',
      route: '/settings/general',
    ),
    _SettingsCategory(
      icon: Icons.note_alt_rounded,
      iconColor: AppColors.accent,
      title: 'Canvas',
      subtitle: 'Page template, spacing, and margins',
      route: '/settings/canvas',
    ),
    _SettingsCategory(
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.systemIndigo,
      title: 'Writing Effects',
      subtitle: 'Ink effects and interaction animations',
      route: '/settings/effects',
    ),
    _SettingsCategory(
      icon: Icons.draw_rounded,
      iconColor: AppColors.systemGreen,
      title: 'Stylus',
      subtitle: 'Pressure, tilt, gestures, and palm rejection',
      route: '/settings/stylus',
    ),
    _SettingsCategory(
      icon: Icons.text_fields_rounded,
      iconColor: AppColors.systemRed,
      title: 'Recognition',
      subtitle: 'Handwriting language, mode, and engine',
      route: '/settings/recognition',
    ),
    _SettingsCategory(
      icon: Icons.shield_rounded,
      iconColor: AppColors.systemTeal,
      title: 'Backup & Data',
      subtitle: 'Auto-save, export defaults, and storage',
      route: '/settings/backup',
    ),
    _SettingsCategory(
      icon: Icons.cloud_rounded,
      iconColor: AppColors.accent,
      title: 'Cloud Sync',
      subtitle: 'iCloud, Google Drive, OneDrive, Dropbox',
      route: '/settings/cloud-sync',
    ),
    _SettingsCategory(
      icon: Icons.info_rounded,
      iconColor: AppColors.textSecondary,
      title: 'About',
      subtitle: 'Version, licenses, and credits',
      route: '/settings/about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Grouped section container
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < _categories.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 60,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.toolbarBorder,
                    ),
                  _SettingsTile(category: _categories[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.category});

  final _SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: category.iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          category.icon,
          size: 18,
          color: Colors.white,
        ),
      ),
      title: Text(
        category.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        category.subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.textSecondary.withOpacity(0.4),
      ),
      onTap: () => context.push(category.route),
    );
  }
}

class _SettingsCategory {
  const _SettingsCategory({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String route;
}
