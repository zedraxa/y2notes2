import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/cloud_sync/domain/entities/cloud_provider.dart';
import 'package:biscuits/features/cloud_sync/presentation/bloc/cloud_sync_bloc.dart';
import 'package:biscuits/features/cloud_sync/presentation/bloc/cloud_sync_event.dart';
import 'package:biscuits/features/cloud_sync/presentation/bloc/cloud_sync_state.dart';

/// Full-page settings UI for configuring cloud synchronization.
class CloudSyncSettingsPage extends StatelessWidget {
  const CloudSyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloudSyncBloc, CloudSyncState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Cloud Sync')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── Connected providers ──────────────────────────────────────
              _SectionHeader('Cloud Providers'),
              ..._buildProviderTiles(context, state),
              const Divider(height: 24),

              // ── Active provider ─────────────────────────────────────────
              _SectionHeader('Active Provider'),
              _ActiveProviderTile(state: state),
              const Divider(height: 24),

              // ── Auto-sync settings ──────────────────────────────────────
              _SectionHeader('Automatic Sync'),
              _AutoSyncToggle(state: state),
              _AutoSyncIntervalTile(state: state),
              _WifiOnlyToggle(state: state),
              const Divider(height: 24),

              // ── Sync actions ────────────────────────────────────────────
              _SectionHeader('Sync Actions'),
              _SyncAllTile(state: state),
              _RefreshRemoteTile(state: state),
              const Divider(height: 24),

              // ── Status info ─────────────────────────────────────────────
              _SectionHeader('Status'),
              _SyncStatusInfoTile(state: state),
              _StorageQuotaTile(state: state),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildProviderTiles(
      BuildContext context, CloudSyncState state) {
    return CloudProviderType.values.map((type) {
      final config = state.providers[type];
      final isConnected = config?.isAuthenticated ?? false;
      final isActive = state.activeProvider == type;

      return ListTile(
        leading: Icon(
          _providerIcon(type),
          color: isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(_providerDisplayName(type)),
        subtitle: isConnected
            ? Text(config!.accountEmail ?? 'Connected')
            : const Text('Not connected'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            isConnected
                ? IconButton(
                    icon: const Icon(Icons.link_off),
                    tooltip: 'Disconnect',
                    onPressed: () {
                      context.read<CloudSyncBloc>().add(
                            DisconnectProvider(providerType: type),
                          );
                    },
                  )
                : TextButton(
                    onPressed: () {
                      context.read<CloudSyncBloc>().add(
                            ConnectProvider(providerType: type),
                          );
                    },
                    child: const Text('Connect'),
                  ),
          ],
        ),
      );
    }).toList();
  }

  IconData _providerIcon(CloudProviderType type) {
    switch (type) {
      case CloudProviderType.iCloud:
        return Icons.cloud_outlined;
      case CloudProviderType.googleDrive:
        return Icons.add_to_drive_outlined;
      case CloudProviderType.oneDrive:
        return Icons.cloud_circle_outlined;
      case CloudProviderType.dropbox:
        return Icons.cloud_queue_outlined;
    }
  }

  String _providerDisplayName(CloudProviderType type) {
    switch (type) {
      case CloudProviderType.iCloud:
        return 'iCloud';
      case CloudProviderType.googleDrive:
        return 'Google Drive';
      case CloudProviderType.oneDrive:
        return 'OneDrive';
      case CloudProviderType.dropbox:
        return 'Dropbox';
    }
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

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

// ─── Active provider selector ────────────────────────────────────────────────

class _ActiveProviderTile extends StatelessWidget {
  const _ActiveProviderTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) {
    final connectedProviders = state.providers.entries
        .where((e) => e.value.isAuthenticated)
        .toList();

    if (connectedProviders.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.cloud_off_outlined, color: Colors.grey),
        title: Text('No providers connected'),
        subtitle: Text('Connect a cloud provider above to enable sync'),
      );
    }

    return ListTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Sync with'),
      subtitle: Text(
        state.activeProviderConfig?.displayName ?? 'None selected',
      ),
      trailing: DropdownButton<CloudProviderType>(
        value: state.activeProvider,
        underline: const SizedBox.shrink(),
        items: connectedProviders
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value.displayName),
                ))
            .toList(),
        onChanged: (type) {
          if (type != null) {
            context
                .read<CloudSyncBloc>()
                .add(SetActiveProvider(providerType: type));
          }
        },
      ),
    );
  }
}

// ─── Auto-sync widgets ───────────────────────────────────────────────────────

class _AutoSyncToggle extends StatelessWidget {
  const _AutoSyncToggle({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: const Text('Auto-sync'),
        subtitle:
            const Text('Automatically sync notebooks in the background'),
        value: state.isAutoSyncEnabled,
        onChanged: state.hasActiveProvider
            ? (v) =>
                context.read<CloudSyncBloc>().add(ToggleAutoSync(enabled: v))
            : null,
      );
}

class _AutoSyncIntervalTile extends StatelessWidget {
  const _AutoSyncIntervalTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) => ListTile(
        enabled: state.isAutoSyncEnabled && state.hasActiveProvider,
        title: const Text('Sync Interval'),
        subtitle: Slider(
          value: state.autoSyncIntervalMinutes.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          label: _formatInterval(state.autoSyncIntervalMinutes),
          onChanged: (state.isAutoSyncEnabled && state.hasActiveProvider)
              ? (v) => context
                  .read<CloudSyncBloc>()
                  .add(SetAutoSyncInterval(minutes: v.round()))
              : null,
        ),
        trailing: Text(
          _formatInterval(state.autoSyncIntervalMinutes),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );

  String _formatInterval(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _WifiOnlyToggle extends StatelessWidget {
  const _WifiOnlyToggle({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: const Text('Wi-Fi only'),
        subtitle: const Text('Only sync when connected to Wi-Fi'),
        value: state.isWifiOnlyEnabled,
        onChanged: state.hasActiveProvider
            ? (v) => context
                .read<CloudSyncBloc>()
                .add(ToggleWifiOnlySync(enabled: v))
            : null,
      );
}

// ─── Sync action widgets ─────────────────────────────────────────────────────

class _SyncAllTile extends StatelessWidget {
  const _SyncAllTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: state.isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        title: const Text('Sync All Now'),
        subtitle: Text(state.isSyncing
            ? 'Syncing… ${(state.syncProgress * 100).toInt()}%'
            : '${state.pendingChangesCount} pending change(s)'),
        enabled: state.hasActiveProvider && !state.isSyncing,
        onTap: () => context
            .read<CloudSyncBloc>()
            .add(const SyncAllNotebooks()),
      );
}

class _RefreshRemoteTile extends StatelessWidget {
  const _RefreshRemoteTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: state.isLoadingRemote
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_download_outlined),
        title: const Text('Refresh Remote Notebooks'),
        subtitle:
            Text('${state.remoteNotebooks.length} notebook(s) in cloud'),
        enabled: state.hasActiveProvider && !state.isLoadingRemote,
        onTap: () => context
            .read<CloudSyncBloc>()
            .add(const RefreshRemoteNotebooks()),
      );
}

// ─── Status widgets ──────────────────────────────────────────────────────────

class _SyncStatusInfoTile extends StatelessWidget {
  const _SyncStatusInfoTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) {
    final hasError = state.hasError;

    return ListTile(
      leading: Icon(
        hasError ? Icons.error_outline : Icons.info_outline,
        color: hasError ? Colors.red : null,
      ),
      title: Text(hasError ? 'Sync Error' : 'Last Sync'),
      subtitle: Text(hasError
          ? state.errorMessage ?? 'Unknown error'
          : (state.lastGlobalSyncAt != null
              ? _formatDateTime(state.lastGlobalSyncAt!)
              : 'Never synced')),
      trailing: hasError
          ? TextButton(
              onPressed: () => context
                  .read<CloudSyncBloc>()
                  .add(const ClearSyncError()),
              child: const Text('Dismiss'),
            )
          : null,
    );
  }

  String _formatDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _StorageQuotaTile extends StatelessWidget {
  const _StorageQuotaTile({required this.state});

  final CloudSyncState state;

  @override
  Widget build(BuildContext context) {
    final config = state.activeProviderConfig;
    if (config == null) {
      return const ListTile(
        leading: Icon(Icons.storage_outlined),
        title: Text('Cloud Storage'),
        subtitle: Text('Connect a provider to see storage info'),
      );
    }

    final usedGB = config.quotaUsedBytes / (1024 * 1024 * 1024);
    final totalGB = config.quotaTotalBytes / (1024 * 1024 * 1024);

    return ListTile(
      leading: const Icon(Icons.storage_outlined),
      title: Text('${config.displayName} Storage'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: config.quotaUsageFraction,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 4),
          Text(
            '${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(0)} GB used',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
