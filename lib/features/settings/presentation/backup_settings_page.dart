import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Backup & data settings with Apple iOS-style grouped rounded sections.
class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionHeader('Auto-save'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _AutoSaveToggle(settings: settings),
            _AutoSaveIntervalTile(settings: settings),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Export Defaults'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            _ExportFormatSelector(settings: settings),
          ]),
          const SizedBox(height: 24),
          _SectionHeader('Storage'),
          const SizedBox(height: 6),
          _GroupedSection(isDark: isDark, children: [
            const _StorageInfoTile(),
          ]),
        ],
      ),
    );
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

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _AutoSaveToggle extends StatelessWidget {
  const _AutoSaveToggle({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.autoSaveEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('Auto-save'),
          subtitle: const Text('Automatically save changes while editing'),
          value: enabled,
          onChanged: settings.setAutoSaveEnabled,
        ),
      );
}

class _AutoSaveIntervalTile extends StatelessWidget {
  const _AutoSaveIntervalTile({required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.autoSaveEnabledNotifier,
        builder: (context, autoSaveEnabled, _) =>
            ValueListenableBuilder<int>(
          valueListenable: settings.autoSaveIntervalNotifier,
          builder: (context, seconds, _) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            enabled: autoSaveEnabled,
            title: const Text('Save Interval'),
            subtitle: Slider(
              value: seconds.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: _formatInterval(seconds),
              onChanged: autoSaveEnabled
                  ? (v) => settings.setAutoSaveInterval(v.round())
                  : null,
            ),
            trailing: Text(
              _formatInterval(seconds),
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

class _ExportFormatSelector extends StatelessWidget {
  const _ExportFormatSelector({required this.settings});
  final SettingsService settings;

  static const _formats = [
    ('pdf', 'PDF', Icons.picture_as_pdf_rounded),
    ('png', 'PNG Image', Icons.image_rounded),
    ('jpeg', 'JPEG Image', Icons.photo_rounded),
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: settings.defaultExportFormatNotifier,
        builder: (context, current, _) => Column(
          children: _formats.map((f) {
            return RadioListTile<String>(
              value: f.$1,
              groupValue: current,
              title: Text(f.$2),
              secondary: Icon(f.$3, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onChanged: (v) {
                if (v != null) settings.setDefaultExportFormat(v);
              },
            );
          }).toList(),
        ),
      );
}

class _StorageInfoTile extends StatelessWidget {
  const _StorageInfoTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.systemGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.storage_rounded, size: 18, color: AppColors.systemGreen),
      ),
      title: const Text('Local Storage'),
      subtitle: const Text(
        'All notebooks are stored on-device. Use Export to create backups.',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.systemGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'On-device',
          style: TextStyle(
            color: AppColors.systemGreen,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
