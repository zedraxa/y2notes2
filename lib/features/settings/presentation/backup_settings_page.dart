import 'package:flutter/material.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// Backup & data settings: auto-save toggle, default export format, and
/// a visual storage usage hint.
class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ServiceProvider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Data')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Auto-save'),
          _AutoSaveToggle(settings: settings),
          _AutoSaveIntervalTile(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Export Defaults'),
          _ExportFormatSelector(settings: settings),
          const Divider(height: 24),
          _SectionHeader('Storage'),
          const _StorageInfoTile(),
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

class _AutoSaveToggle extends StatelessWidget {
  const _AutoSaveToggle({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: settings.autoSaveEnabledNotifier,
        builder: (context, enabled, _) => SwitchListTile(
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
    ('pdf', 'PDF', Icons.picture_as_pdf_outlined),
    ('png', 'PNG Image', Icons.image_outlined),
    ('jpeg', 'JPEG Image', Icons.photo_outlined),
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
      leading: const Icon(Icons.storage_outlined),
      title: const Text('Local Storage'),
      subtitle: const Text(
        'All notebooks are stored on-device. '
        'Use Export to create backups.',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'On-device',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
