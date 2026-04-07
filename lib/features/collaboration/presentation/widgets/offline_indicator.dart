import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/collaboration/engine/sync_client.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_bloc.dart';

/// Banner shown when the WebSocket connection is lost.
///
/// Displays the number of pending operations that will be replayed on
/// reconnection.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollaborationBloc, CollaborationState>(
      buildWhen: (prev, curr) =>
          prev.connectionState != curr.connectionState ||
          prev.pendingOperations.length != curr.pendingOperations.length ||
          prev.isInSession != curr.isInSession,
      builder: (context, state) {
        if (!state.isInSession) return const SizedBox.shrink();

        final isOffline = state.connectionState ==
                SyncConnectionState.disconnected ||
            state.connectionState == SyncConnectionState.error;
        final isReconnecting =
            state.connectionState == SyncConnectionState.reconnecting;

        if (!isOffline && !isReconnecting) return const SizedBox.shrink();

        final queued = state.pendingOperations.length;
        final message = isReconnecting
            ? 'Reconnecting…'
            : 'Offline — ${queued > 0 ? '$queued op${queued == 1 ? '' : 's'} queued' : 'no unsaved changes'}';

        return Material(
          color: isReconnecting
              ? Colors.amber.shade700
              : Colors.red.shade700,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isReconnecting)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.wifi_off,
                        size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
