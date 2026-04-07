import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/sync_conflict.dart';
import 'package:y2notes2/features/cloud_sync/domain/entities/sync_metadata.dart';
import 'package:y2notes2/features/cloud_sync/presentation/bloc/cloud_sync_bloc.dart';
import 'package:y2notes2/features/cloud_sync/presentation/bloc/cloud_sync_event.dart';
import 'package:y2notes2/features/cloud_sync/presentation/bloc/cloud_sync_state.dart';

/// Compact widget that shows the current sync status in the app bar or
/// a toolbar. Taps open the full cloud sync settings page.
class CloudSyncStatusWidget extends StatelessWidget {
  const CloudSyncStatusWidget({super.key, this.onTap});

  /// Called when the user taps the status indicator.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloudSyncBloc, CloudSyncState>(
      builder: (context, state) {
        final icon = _statusIcon(state);
        final color = _statusColor(state);
        final tooltip = _statusTooltip(state);

        return Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: state.isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: state.syncProgress > 0
                            ? state.syncProgress
                            : null,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 20, color: color),
            ),
          ),
        );
      },
    );
  }

  IconData _statusIcon(CloudSyncState state) {
    if (!state.hasActiveProvider) return Icons.cloud_off_outlined;
    if (state.hasConflicts) return Icons.warning_amber_outlined;
    if (state.hasError) return Icons.cloud_off_outlined;
    if (state.pendingChangesCount > 0) return Icons.cloud_upload_outlined;
    return Icons.cloud_done_outlined;
  }

  Color _statusColor(CloudSyncState state) {
    if (!state.hasActiveProvider) return Colors.grey;
    if (state.hasConflicts) return Colors.orange;
    if (state.hasError) return Colors.red;
    if (state.isSyncing) return Colors.blue;
    return Colors.green;
  }

  String _statusTooltip(CloudSyncState state) {
    if (!state.hasActiveProvider) return 'No cloud provider connected';
    if (state.isSyncing) return 'Syncing…';
    if (state.hasConflicts) return 'Sync conflict detected';
    if (state.hasError) return 'Sync error: ${state.errorMessage}';
    if (state.pendingChangesCount > 0) {
      return '${state.pendingChangesCount} notebook(s) pending sync';
    }
    if (state.lastGlobalSyncAt != null) {
      return 'Last synced: ${_formatTime(state.lastGlobalSyncAt!)}';
    }
    return 'Cloud sync connected';
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// A banner-style widget that shows conflict alerts and allows resolution.
class CloudSyncConflictBanner extends StatelessWidget {
  const CloudSyncConflictBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloudSyncBloc, CloudSyncState>(
      buildWhen: (prev, curr) => prev.conflicts != curr.conflicts,
      builder: (context, state) {
        final unresolvedConflicts =
            state.conflicts.where((c) => !c.isResolved).toList();

        if (unresolvedConflicts.isEmpty) return const SizedBox.shrink();

        return Material(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${unresolvedConflicts.length} sync conflict(s) need attention',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to conflict resolution.
                    _showConflictDialog(context, unresolvedConflicts.first);
                  },
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConflictDialog(BuildContext context, dynamic conflict) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Conflict'),
        content: Text(
          'The notebook "${conflict.notebookTitle}" has been modified both '
          'locally and in the cloud. How would you like to resolve this?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CloudSyncBloc>().add(
                    ResolveConflict(
                      notebookId: conflict.notebookId,
                      resolution:
                          const _KeepLocalResolution().resolution,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Keep Local'),
          ),
          TextButton(
            onPressed: () {
              context.read<CloudSyncBloc>().add(
                    ResolveConflict(
                      notebookId: conflict.notebookId,
                      resolution:
                          const _KeepRemoteResolution().resolution,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Keep Remote'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CloudSyncBloc>().add(
                    ResolveConflict(
                      notebookId: conflict.notebookId,
                      resolution: const _KeepBothResolution().resolution,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Keep Both'),
          ),
        ],
      ),
    );
  }
}

// Small helper classes to make the resolution references const-compatible.
class _KeepLocalResolution {
  const _KeepLocalResolution();
  ConflictResolution get resolution => ConflictResolution.keepLocal;
}

class _KeepRemoteResolution {
  const _KeepRemoteResolution();
  ConflictResolution get resolution => ConflictResolution.keepRemote;
}

class _KeepBothResolution {
  const _KeepBothResolution();
  ConflictResolution get resolution => ConflictResolution.keepBoth;
}

/// Inline card showing the sync status for a specific notebook.
class NotebookSyncStatusCard extends StatelessWidget {
  const NotebookSyncStatusCard({
    super.key,
    required this.notebookId,
    this.notebookTitle = 'Notebook',
  });

  final String notebookId;
  final String notebookTitle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloudSyncBloc, CloudSyncState>(
      builder: (context, state) {
        final metadata = state.syncMetadata[notebookId];

        if (!state.hasActiveProvider) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _buildStatusIcon(metadata),
            title: Text(notebookTitle),
            subtitle: Text(_buildSubtitle(metadata)),
            trailing: metadata?.syncStatus == SyncOperationStatus.syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () {
                      context
                          .read<CloudSyncBloc>()
                          .add(SyncNow(notebookId: notebookId));
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(SyncMetadata? metadata) {
    if (metadata == null) {
      return const Icon(Icons.cloud_off_outlined, color: Colors.grey);
    }

    switch (metadata.syncStatus) {
      case SyncOperationStatus.success:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncOperationStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
      case SyncOperationStatus.syncing:
        return const Icon(Icons.cloud_sync, color: Colors.blue);
      case SyncOperationStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange);
      case SyncOperationStatus.waitingForNetwork:
        return const Icon(Icons.wifi_off, color: Colors.grey);
      case SyncOperationStatus.idle:
        return const Icon(Icons.cloud_queue, color: Colors.grey);
    }
  }

  String _buildSubtitle(SyncMetadata? metadata) {
    if (metadata == null) return 'Not synced';

    if (metadata.syncStatus == SyncOperationStatus.syncing) {
      final percent = (metadata.transferProgress * 100).toInt();
      return 'Syncing… $percent%';
    }

    if (metadata.lastSyncedAt != null) {
      final diff = DateTime.now().difference(metadata.lastSyncedAt!);
      if (diff.inMinutes < 1) return 'Synced just now';
      if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
      return 'Synced ${diff.inDays}d ago';
    }

    return 'Not synced yet';
  }
}
