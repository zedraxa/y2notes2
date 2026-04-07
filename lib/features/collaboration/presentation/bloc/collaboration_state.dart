import 'package:equatable/equatable.dart';
import 'package:biscuitse/features/collaboration/domain/entities/participant.dart';
import 'package:biscuitse/features/collaboration/domain/entities/permission.dart';
import 'package:biscuitse/features/collaboration/domain/entities/session.dart';
import 'package:biscuitse/features/collaboration/engine/crdt_engine.dart';
import 'package:biscuitse/features/collaboration/engine/sync_client.dart';

/// Immutable snapshot of the collaboration subsystem.
class CollaborationState extends Equatable {
  const CollaborationState({
    this.session,
    this.connectionState = SyncConnectionState.disconnected,
    this.pendingOperations = const [],
    this.isHost = false,
    this.localPermission = PermissionLevel.viewer,
  });

  /// The active session, or null when not in a session.
  final Session? session;

  final SyncConnectionState connectionState;

  /// Operations queued for delivery while the connection is down.
  final List<CrdtOperation> pendingOperations;

  /// Whether the local user is the session owner.
  final bool isHost;

  /// The local user's effective permission.
  final PermissionLevel localPermission;

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get isInSession => session != null;
  bool get isConnected => connectionState == SyncConnectionState.connected;
  bool get isOffline => connectionState == SyncConnectionState.disconnected ||
      connectionState == SyncConnectionState.error;

  Map<String, Participant> get participants =>
      session?.participants ?? const {};

  String? get sessionId => session?.sessionId;
  String? get roomCode => session?.roomCode;
  String? get shareUrl => session?.shareUrl;

  CollaborationState copyWith({
    Session? session,
    bool clearSession = false,
    SyncConnectionState? connectionState,
    List<CrdtOperation>? pendingOperations,
    bool? isHost,
    PermissionLevel? localPermission,
  }) =>
      CollaborationState(
        session: clearSession ? null : (session ?? this.session),
        connectionState: connectionState ?? this.connectionState,
        pendingOperations: pendingOperations ?? this.pendingOperations,
        isHost: isHost ?? this.isHost,
        localPermission: localPermission ?? this.localPermission,
      );

  @override
  List<Object?> get props => [
        session,
        connectionState,
        pendingOperations,
        isHost,
        localPermission,
      ];
}
