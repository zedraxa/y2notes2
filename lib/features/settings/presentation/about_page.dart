import 'package:flutter/material.dart';

/// About page: app name, version, open-source licenses, and credits.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 24),
          // App icon / name block
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Biscuits',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'A cross-platform note-taking app\nwith magical writing effects',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          _SectionHeader('Application'),
          const ListTile(
            leading: Icon(Icons.flutter_dash),
            title: Text('Built with Flutter'),
            subtitle: Text('Cross-platform native performance'),
          ),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Privacy-first'),
            subtitle: Text('All data stays on your device'),
          ),
          const Divider(height: 24),
          _SectionHeader('Licenses'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open Source Licenses'),
            subtitle: const Text('View third-party library licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Biscuits',
              applicationVersion: '1.0.0',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          _SectionHeader('Acknowledgements'),
          const ListTile(
            leading: Icon(Icons.favorite_outline),
            title: Text('perfect_freehand'),
            subtitle: Text('Beautiful pressure-sensitive strokes'),
          ),
          const ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('pdf / printing'),
            subtitle: Text('PDF generation and export'),
          ),
          const SizedBox(height: 24),
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
