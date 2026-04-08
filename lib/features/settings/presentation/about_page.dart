import 'package:flutter/material.dart';
import 'package:biscuits/shared/widgets/biscuits_logo.dart';

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
          const SizedBox(height: 32),
          // App logo & name block
          const Center(
            child: BiscuitsLogo(size: 80),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'A modern note-taking app\nwith magical writing effects',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
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
              applicationIcon: const Padding(
                padding: EdgeInsets.all(8),
                child: BiscuitsLogo(size: 48, showText: false),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}
