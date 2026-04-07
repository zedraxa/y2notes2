import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/library/domain/entities/folder.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_bloc.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_event.dart';
import 'package:y2notes2/features/library/presentation/bloc/library_state.dart';

/// Horizontal breadcrumb trail showing the current folder path.
///
/// Tapping a crumb navigates to that folder; tapping "Library" goes to root.
class FolderBreadcrumbs extends StatelessWidget {
  const FolderBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      buildWhen: (prev, next) =>
          prev.breadcrumbs != next.breadcrumbs ||
          prev.currentFolderId != next.currentFolderId,
      builder: (context, state) {
        final crumbs = state.breadcrumbs;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _Crumb(
                label: 'Library',
                isActive: crumbs.isEmpty,
                onTap: () => context
                    .read<LibraryBloc>()
                    .add(const NavigateToFolder(null)),
              ),
              ...crumbs.expand((folder) => [
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    _Crumb(
                      label: folder.name,
                      emoji: folder.emoji,
                      isActive: folder.id == state.currentFolderId,
                      onTap: () => context
                          .read<LibraryBloc>()
                          .add(NavigateToFolder(folder.id)),
                    ),
                  ]),
            ],
          ),
        );
      },
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    this.emoji,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
