import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/shared/widgets/apple_list_tile.dart';
import 'package:biscuits/app/theme/colors.dart';
import 'package:biscuits/app/theme/elevation.dart';

/// Main settings hub with navigation tiles to each settings category.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppleSpacing.md),
        children: [
          // ── App Settings ──────────────────────────────────────────────
          AppleInsetGroup(
            header: const Text('APP'),
            children: [
              AppleListTile(
                leading: _SettingsIcon(Icons.palette_outlined, iconColor),
                title: const Text('General'),
                subtitle: const Text('Appearance, haptics, and defaults'),
                onTap: () => context.push('/settings/general'),
              ),
              AppleListTile(
                leading: _SettingsIcon(Icons.note_alt_outlined, iconColor),
                title: const Text('Canvas'),
                subtitle:
                    const Text('Page template, spacing, and margins'),
                onTap: () => context.push('/settings/canvas'),
              ),
              AppleListTile(
                leading:
                    _SettingsIcon(Icons.auto_awesome_outlined, iconColor),
                title: const Text('Writing Effects'),
                subtitle:
                    const Text('Ink effects and interaction animations'),
                onTap: () => context.push('/settings/effects'),
              ),
            ],
          ),

          // ── Input Settings ────────────────────────────────────────────
          AppleInsetGroup(
            header: const Text('INPUT'),
            children: [
              AppleListTile(
                leading: _SettingsIcon(Icons.draw_outlined, iconColor),
                title: const Text('Stylus'),
                subtitle: const Text(
                    'Pressure, tilt, gestures, and palm rejection'),
                onTap: () => context.push('/settings/stylus'),
              ),
              AppleListTile(
                leading:
                    _SettingsIcon(Icons.text_fields_outlined, iconColor),
                title: const Text('Recognition'),
                subtitle: const Text(
                    'Handwriting language, mode, and engine'),
                onTap: () => context.push('/settings/recognition'),
              ),
            ],
          ),

          // ── Data & Cloud ──────────────────────────────────────────────
          AppleInsetGroup(
            header: const Text('DATA & CLOUD'),
            children: [
              AppleListTile(
                leading: _SettingsIcon(Icons.backup_outlined, iconColor),
                title: const Text('Backup & Data'),
                subtitle: const Text(
                    'Auto-save, export defaults, and storage'),
                onTap: () => context.push('/settings/backup'),
              ),
              AppleListTile(
                leading:
                    _SettingsIcon(Icons.cloud_sync_outlined, iconColor),
                title: const Text('Cloud Sync'),
                subtitle: const Text(
                    'iCloud, Google Drive, OneDrive, Dropbox'),
                onTap: () => context.push('/settings/cloud-sync'),
              ),
            ],
          ),

          // ── About ─────────────────────────────────────────────────────
          AppleInsetGroup(
            children: [
              AppleListTile(
                leading: _SettingsIcon(Icons.info_outline, iconColor),
                title: const Text('About'),
                subtitle: const Text('Version, licenses, and credits'),
                onTap: () => context.push('/settings/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rounded icon container for settings list tiles.
class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
