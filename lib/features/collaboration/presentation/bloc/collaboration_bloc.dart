import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/collaboration/domain/entities/participant.dart';
import 'package:y2notes2/features/collaboration/domain/entities/permission.dart';
import 'package:y2notes2/features/collaboration/engine/crdt_engine.dart';
import 'package:y2notes2/features/collaboration/engine/presence_manager.dart';
import 'package:y2notes2/features/collaboration/engine/session_manager.dart';
import 'package:y2notes2/features/collaboration/engine/sync_client.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_event.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_state.dart';

export 'collaboration_event.dart';
export 'collaboration_state.dart';

/// BLoC that orchestrates real-time collaboration.
///
/// Depends on:
///  • [SyncClient] — WebSocket transport layer
///  • [SessionManager] — room/permission management
///  • [PresenceManager] — cursor/presence tracking
///  • [CrdtEngine] — vector clock and idempotency
class CollaborationBloc
    extends Bloc<CollaborationEvent, CollaborationState> {
  CollaborationBloc({
    required String localUserId,
    required String localDisplayName,
    SyncClient? syncClient,
    String? localAvatarUrl,
  })  : _localUserId = localUserId,
        _syncClient = syncClient ?? SyncClient.stub(),
        _sessionManager = SessionManager(
          localUserId: localUserId,
          localDisplayName: localDisplayName,
        ),
        _crdtEngine = CrdtEngine(localUserId),
        super(const CollaborationState()) {
    _presenceManager = PresenceManager(
      localUserId: localUserId,
      localDisplayName: localDisplayName,
      syncClient: _syncClient,
      localAvatarUrl: localAvatarUrl,
    );

    on<StartSession>(_onStartSession);
    on<JoinSession>(_onJoinSession);
    on<LeaveSession>(_onLeaveSession);
    on<IncomingOperation>(_onIncomingOperation);
    on<SendOperation>(_onSendOperation);
    on<UserJoined>(_onUserJoined);
    on<UserLeft>(_onUserLeft);
    on<ConnectionChanged>(_onConnectionChanged);
    on<PermissionChanged>(_onPermissionChanged);
    on<SessionSettingsUpdated>(_onSessionSettingsUpdated);
  }

  final String _localUserId;
  final SyncClient _syncClient;
  final SessionManager _sessionManager;
  final CrdtEngine _crdtEngine;
  late final PresenceManager _presenceManager;

  StreamSubscription<CrdtOperation>? _opSub;
  StreamSubscription<SyncConnectionState>? _stateSub;

  // ─── Event handlers ───────────────────────────────────────────────────────

  Future<void> _onStartSession(
      StartSession event, Emitter<CollaborationState> emit) async {
    final session = _sessionManager.createSession(settings: event.settings);
    emit(state.copyWith(
      session: session,
      isHost: true,
      localPermission: PermissionLevel.owner,
    ));
    await _connectAndListen(session.sessionId);
  }

  Future<void> _onJoinSession(
      JoinSession event, Emitter<CollaborationState> emit) async {
    final session = _sessionManager.joinSession(event.roomCode);
    emit(state.copyWith(
      session: session,
      isHost: false,
      localPermission: PermissionLevel.editor,
    ));
    await _connectAndListen(session.sessionId);
  }

  Future<void> _onLeaveSession(
      LeaveSession event, Emitter<CollaborationState> emit) async {
    await _disconnect();
    _sessionManager.leaveSession();
    _crdtEngine.reset();
    emit(state.copyWith(
      clearSession: true,
      connectionState: SyncConnectionState.disconnected,
      pendingOperations: const [],
      isHost: false,
      localPermission: PermissionLevel.viewer,
    ));
  }

  void _onIncomingOperation(
      IncomingOperation event, Emitter<CollaborationState> emit) {
    if (!_crdtEngine.shouldApply(event.operation)) return;
    // The actual canvas mutation is handled by CanvasBloc listening to this
    // bloc's state or via a shared stream. Here we just acknowledge receipt.
    // (No state change needed for the collaboration state itself.)
  }

  void _onSendOperation(
      SendOperation event, Emitter<CollaborationState> emit) {
    if (!state.localPermission.canEdit) return;
    if (state.isConnected) {
      _syncClient.sendOperation(event.operation);
    } else {
      // Queue for later delivery.
      emit(state.copyWith(
        pendingOperations: [...state.pendingOperations, event.operation],
      ));
    }
  }

  void _onUserJoined(UserJoined event, Emitter<CollaborationState> emit) {
    _sessionManager.upsertParticipant(
      Participant(
        userId: event.userId,
        displayName: event.displayName,
        cursorColor: colorForUser(event.userId),
        permission: PermissionLevel.editor,
      ),
    );
    final session = _sessionManager.currentSession;
    if (session != null) emit(state.copyWith(session: session));
  }

  void _onUserLeft(UserLeft event, Emitter<CollaborationState> emit) {
    _sessionManager.removeParticipant(event.userId);
    _presenceManager.removeParticipant(event.userId);
    final session = _sessionManager.currentSession;
    if (session != null) emit(state.copyWith(session: session));
  }

  void _onConnectionChanged(
      ConnectionChanged event, Emitter<CollaborationState> emit) {
    emit(state.copyWith(connectionState: event.connectionState));

    // When reconnected, flush pending operations.
    if (event.connectionState == SyncConnectionState.connected) {
      for (final op in state.pendingOperations) {
        _syncClient.sendOperation(op);
      }
      emit(state.copyWith(pendingOperations: const []));
    }
  }

  void _onPermissionChanged(
      PermissionChanged event, Emitter<CollaborationState> emit) {
    _sessionManager.setPermission(event.userId, event.newLevel);
    final session = _sessionManager.currentSession;
    if (session != null) {
      final newState = state.copyWith(session: session);
      // Also update own permission if changed.
      if (event.userId == _localUserId) {
        emit(newState.copyWith(localPermission: event.newLevel));
      } else {
        emit(newState);
      }
    }
  }

  void _onSessionSettingsUpdated(
      SessionSettingsUpdated event, Emitter<CollaborationState> emit) {
    _sessionManager.updateSettings(event.settings);
    final session = _sessionManager.currentSession;
    if (session != null) emit(state.copyWith(session: session));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _connectAndListen(String sessionId) async {
    _presenceManager.start();

    _stateSub = _syncClient.connectionState.listen((connState) {
      add(ConnectionChanged(connState));
    });

    _opSub = _syncClient.incomingOperations.listen((op) {
      add(IncomingOperation(op));
    });

    await _syncClient.connect(sessionId, _localUserId);
  }

  Future<void> _disconnect() async {
    await _opSub?.cancel();
    await _stateSub?.cancel();
    await _syncClient.disconnect();
    _presenceManager.dispose();
  }

  @override
  Future<void> close() async {
    await _disconnect();
    return super.close();
  }

  // ─── Presence forwarding ──────────────────────────────────────────────────

  /// Returns the [PresenceManager] for widgets that need cursor data.
  PresenceManager get presenceManager => _presenceManager;
}
