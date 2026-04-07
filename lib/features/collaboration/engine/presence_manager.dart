import 'dart:async';

import 'package:flutter/material.dart';
import 'package:y2notes2/features/collaboration/domain/entities/participant.dart';
import 'package:y2notes2/features/collaboration/domain/entities/permission.dart';
import 'package:y2notes2/features/collaboration/engine/sync_client.dart';

/// Manages the live presence state of all remote participants.
///
/// Responsibilities:
///  • Tracks cursor positions, active nodes, and status for every remote user.
///  • Broadcasts the local user's own presence at most every [_broadcastInterval].
///  • Marks participants as [PresenceStatus.idle] after [_idleTimeout] of
///    inactivity.
class PresenceManager {
  PresenceManager({
    required this.localUserId,
    required this.localDisplayName,
    required SyncClient syncClient,
    String? localAvatarUrl,
  })  : _syncClient = syncClient,
        _localAvatarUrl = localAvatarUrl;

  final String localUserId;
  final String localDisplayName;
  final String? _localAvatarUrl;
  final SyncClient _syncClient;

  /// How often the local cursor is broadcast during active movement.
  static const Duration _broadcastInterval = Duration(milliseconds: 50);

  /// Time before a participant is marked idle.
  static const Duration _idleTimeout = Duration(seconds: 30);

  final Map<String, Participant> _participants = {};
  final Map<String, Timer> _idleTimers = {};

  final _controller =
      StreamController<Map<String, Participant>>.broadcast();

  StreamSubscription<PresenceUpdate>? _presenceSub;

  // ─── Last known local state ───────────────────────────────────────────────
  Offset? _lastCursorPosition;
  String? _activeNodeId;
  String? _activeToolName;
  DateTime _lastBroadcast = DateTime.fromMillisecondsSinceEpoch(0);

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Stream of remote participants map, emitted whenever any participant
  /// changes.
  Stream<Map<String, Participant>> get participants => _controller.stream;

  /// Current snapshot of all remote participants.
  Map<String, Participant> get currentParticipants =>
      Map.unmodifiable(_participants);

  /// Start listening to incoming presence updates.
  void start() {
    _presenceSub = _syncClient.presenceUpdates.listen(_onPresenceUpdate);
  }

  /// Update the local cursor position and broadcast (throttled).
  void updateCursorPosition(Offset position) {
    _lastCursorPosition = position;
    _maybeBroadcast();
  }

  /// Signal that the pointer has left the canvas.
  void clearCursorPosition() {
    _lastCursorPosition = null;
    _broadcast();
  }

  /// Notify peers that the local user started editing [nodeId].
  void setActiveNode(String? nodeId) {
    _activeNodeId = nodeId;
    _broadcast();
  }

  /// Notify peers which tool the local user is using.
  void setActiveTool(String? toolName) {
    _activeToolName = toolName;
    _broadcast();
  }

  /// Remove a participant (e.g. they explicitly left the session).
  void removeParticipant(String userId) {
    _idleTimers[userId]?.cancel();
    _idleTimers.remove(userId);
    _participants.remove(userId);
    _emit();
  }

  bool _disposed = false;

  /// Release all resources. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _presenceSub?.cancel();
    for (final t in _idleTimers.values) {
      t.cancel();
    }
    _idleTimers.clear();
    _controller.close();
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  void _maybeBroadcast() {
    final now = DateTime.now();
    if (now.difference(_lastBroadcast) >= _broadcastInterval) {
      _broadcast();
    }
  }

  void _broadcast() {
    _lastBroadcast = DateTime.now();
    final color = colorForUser(localUserId);
    _syncClient.sendPresence({
      'userId': localUserId,
      'displayName': localDisplayName,
      'avatarUrl': _localAvatarUrl,
      'cursorColor': color.value,
      'cursorPositionX': _lastCursorPosition?.dx,
      'cursorPositionY': _lastCursorPosition?.dy,
      'activeNodeId': _activeNodeId,
      'activeToolName': _activeToolName,
      'status': PresenceStatus.active.name,
    });
  }

  void _onPresenceUpdate(PresenceUpdate update) {
    if (update.userId == localUserId) return; // ignore own reflections

    final existing = _participants[update.userId];
    final color = Color(update.cursorColor);
    final Offset? cursor = (update.cursorX != null && update.cursorY != null)
        ? Offset(update.cursorX!, update.cursorY!)
        : null;

    final participant = Participant(
      userId: update.userId,
      displayName: update.displayName,
      avatarUrl: update.avatarUrl,
      cursorColor: color,
      cursorPosition: cursor,
      activeNodeId: update.activeNodeId,
      activeToolName: update.activeToolName,
      status: update.status,
      permission: existing?.permission ?? PermissionLevel.editor,
    );

    _participants[update.userId] = participant;
    _emit();

    // Reset idle timer.
    _idleTimers[update.userId]?.cancel();
    if (update.status != PresenceStatus.disconnected) {
      _idleTimers[update.userId] = Timer(_idleTimeout, () {
        final p = _participants[update.userId];
        if (p != null) {
          _participants[update.userId] =
              p.copyWith(status: PresenceStatus.idle);
          _emit();
        }
      });
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Map.unmodifiable(_participants));
    }
  }
}
