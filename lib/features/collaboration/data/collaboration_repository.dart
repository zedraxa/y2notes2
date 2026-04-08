import 'package:biscuits/features/collaboration/domain/entities/participant.dart';
import 'package:biscuits/features/collaboration/domain/entities/permission.dart';
import 'package:biscuits/features/collaboration/domain/entities/session.dart';
import 'package:biscuits/features/collaboration/engine/sync_client.dart';

/// Abstract repository contract for the collaboration feature.
///
/// A concrete implementation would talk to a backend REST API or a Firebase
/// project. The [CollaborationBloc] depends only on this interface.
abstract class CollaborationRepository {
  // ─── Session management ───────────────────────────────────────────────────

  Future<Session> createSession({
    required String hostUserId,
    required String hostDisplayName,
    RoomSettings settings = const RoomSettings(),
  });

  Future<Session> joinSession({
    required String roomCode,
    required String userId,
    required String displayName,
  });

  Future<void> leaveSession(String sessionId, String userId);

  Future<void> updateSettings(String sessionId, RoomSettings settings);

  Future<void> setPermission(
      String sessionId, String userId, PermissionLevel level);

  // ─── Streaming ────────────────────────────────────────────────────────────

  Stream<SyncConnectionState> watchConnectionState(String sessionId);

  Stream<Participant> watchParticipantUpdates(String sessionId);
}
