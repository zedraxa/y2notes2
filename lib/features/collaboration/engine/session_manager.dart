import 'dart:math' as math;

import 'package:biscuitse/features/collaboration/domain/entities/participant.dart';
import 'package:biscuitse/features/collaboration/domain/entities/permission.dart';
import 'package:biscuitse/features/collaboration/domain/entities/session.dart';

/// Manages session lifecycle: creating rooms, joining via code/link, and
/// tracking participant permissions.
///
/// In a production app this would talk to a backend; here it provides the
/// in-memory contract that [CollaborationBloc] builds on.
class SessionManager {
  SessionManager({required this.localUserId, required this.localDisplayName});

  final String localUserId;
  final String localDisplayName;

  Session? _currentSession;

  /// The active session, or null when not in a session.
  Session? get currentSession => _currentSession;

  // ─── Session creation ─────────────────────────────────────────────────────

  /// Create a new collaboration session and return it.
  Session createSession({RoomSettings settings = const RoomSettings()}) {
    final sessionId = _generateUuid();
    final roomCode = _generateRoomCode();
    final owner = Participant(
      userId: localUserId,
      displayName: localDisplayName,
      cursorColor: colorForUser(localUserId),
      permission: PermissionLevel.owner,
    );
    _currentSession = Session(
      sessionId: sessionId,
      roomCode: roomCode,
      hostUserId: localUserId,
      createdAt: DateTime.now(),
      participants: {localUserId: owner},
      settings: settings,
    );
    return _currentSession!;
  }

  // ─── Joining ──────────────────────────────────────────────────────────────

  /// Join an existing session by [roomCode].
  ///
  /// Returns the joined session. In a real implementation this would fetch
  /// session metadata from the relay server.
  Session joinSession(String roomCode) {
    // Synthesise a session object for the client-side state.
    final sessionId = _generateUuid();
    final self = Participant(
      userId: localUserId,
      displayName: localDisplayName,
      cursorColor: colorForUser(localUserId),
      permission: PermissionLevel.editor,
    );
    _currentSession = Session(
      sessionId: sessionId,
      roomCode: roomCode.toUpperCase(),
      hostUserId: '', // filled in when server confirms
      createdAt: DateTime.now(),
      participants: {localUserId: self},
    );
    return _currentSession!;
  }

  // ─── Participant management ───────────────────────────────────────────────

  /// Add or update a remote participant.
  void upsertParticipant(Participant participant) {
    if (_currentSession == null) return;
    final updated = Map<String, Participant>.from(
        _currentSession!.participants)
      ..[participant.userId] = participant;
    _currentSession = _currentSession!.copyWith(participants: updated);
    _appendHistory(participant.userId, participant.displayName, 'joined');
  }

  /// Remove a remote participant.
  void removeParticipant(String userId) {
    if (_currentSession == null) return;
    final existing = _currentSession!.participants[userId];
    final updated = Map<String, Participant>.from(
        _currentSession!.participants)
      ..remove(userId);
    _currentSession = _currentSession!.copyWith(participants: updated);
    if (existing != null) {
      _appendHistory(userId, existing.displayName, 'left');
    }
  }

  /// Change the [PermissionLevel] of [userId].
  ///
  /// Only the session owner can call this.
  void setPermission(String userId, PermissionLevel level) {
    if (_currentSession == null) return;
    final participant = _currentSession!.participants[userId];
    if (participant == null) return;
    final updated = Map<String, Participant>.from(
        _currentSession!.participants)
      ..[userId] = participant.copyWith(permission: level);
    _currentSession = _currentSession!.copyWith(participants: updated);
  }

  /// Update room settings.
  void updateSettings(RoomSettings settings) {
    if (_currentSession == null) return;
    _currentSession = _currentSession!.copyWith(settings: settings);
  }

  // ─── Leave / end ──────────────────────────────────────────────────────────

  /// Leave (or end) the current session.
  void leaveSession() {
    _currentSession = null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _appendHistory(String userId, String displayName, String action) {
    if (_currentSession == null) return;
    final entry = SessionHistoryEntry(
      userId: userId,
      displayName: displayName,
      action: action,
      timestamp: DateTime.now(),
    );
    final history = [..._currentSession!.history, entry];
    _currentSession = _currentSession!.copyWith(history: history);
  }

  static final _rng = math.Random();

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final part1 = List.generate(4, (_) => chars[_rng.nextInt(chars.length)])
        .join();
    final part2 = List.generate(4, (_) => chars[_rng.nextInt(chars.length)])
        .join();
    return '$part1-$part2';
  }

  /// Simple UUID v4 generator (no external package needed).
  static String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}'
        '-${bytes.sublist(4, 6).map(hex).join()}'
        '-${bytes.sublist(6, 8).map(hex).join()}'
        '-${bytes.sublist(8, 10).map(hex).join()}'
        '-${bytes.sublist(10, 16).map(hex).join()}';
  }
}
