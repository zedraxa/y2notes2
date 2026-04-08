import 'package:flutter/material.dart';
import 'package:y2notes2/app/theme/colors.dart';

/// Apple-style about page with clean hero section and grouped info tiles.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SizedBox(height: 24),
          // ── App hero section ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.systemIndigo,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Y2Notes',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'A cross-platform note-taking app\nwith magical writing effects',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // ── Application section ─────────────────────────────────────
          _SectionHeader('Application'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _InfoTile(
                icon: Icons.flutter_dash_rounded,
                iconColor: AppColors.accent,
                title: 'Built with Flutter',
                subtitle: 'Cross-platform native performance',
              ),
              _InfoTile(
                icon: Icons.lock_rounded,
                iconColor: AppColors.systemGreen,
                title: 'Privacy-first',
                subtitle: 'All data stays on your device',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Licenses ────────────────────────────────────────────────
          _SectionHeader('Licenses'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.systemIndigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    size: 18,
                    color: AppColors.systemIndigo,
                  ),
                ),
                title: const Text('Open Source Licenses'),
                subtitle: const Text('View third-party library licenses'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary.withOpacity(0.4),
                ),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Y2Notes',
                  applicationVersion: '1.0.0',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.systemIndigo],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Acknowledgements ────────────────────────────────────────
          _SectionHeader('Acknowledgements'),
          const SizedBox(height: 6),
          _GroupedSection(
            isDark: isDark,
            children: [
              _InfoTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.systemPink,
                title: 'perfect_freehand',
                subtitle: 'Beautiful pressure-sensitive strokes',
              ),
              _InfoTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.systemRed,
                title: 'pdf / printing',
                subtitle: 'PDF generation and export',
              ),
            ],
          ),
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

// ─── Grouped section ────────────────────────────────────────────────────────

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({
    required this.isDark,
    required this.children,
  });

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
                height: 0.5,
                thickness: 0.5,
                indent: 60,
                color: isDark ? AppColors.darkDivider : AppColors.toolbarBorder,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─── Info tile ──────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      );
}
