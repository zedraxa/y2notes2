import 'package:biscuits/features/collaboration/domain/entities/participant.dart';
import 'package:biscuits/features/collaboration/domain/entities/permission.dart';

/// Describes a single join/leave event recorded in session history.
class SessionHistoryEntry {
  const SessionHistoryEntry({
    required this.userId,
    required this.displayName,
    required this.action,
    required this.timestamp,
  });

  final String userId;
  final String displayName;

  /// 'joined' or 'left'
  final String action;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SessionHistoryEntry(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        action: json['action'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Room settings for a collaboration session.
class RoomSettings {
  const RoomSettings({
    this.maxParticipants = 20,
    this.isPublic = false,
    this.allowCursorVisibility = true,
    this.autoAcceptJoins = false,
  });

  final int maxParticipants;
  final bool isPublic;
  final bool allowCursorVisibility;
  final bool autoAcceptJoins;

  RoomSettings copyWith({
    int? maxParticipants,
    bool? isPublic,
    bool? allowCursorVisibility,
    bool? autoAcceptJoins,
  }) =>
      RoomSettings(
        maxParticipants: maxParticipants ?? this.maxParticipants,
        isPublic: isPublic ?? this.isPublic,
        allowCursorVisibility:
            allowCursorVisibility ?? this.allowCursorVisibility,
        autoAcceptJoins: autoAcceptJoins ?? this.autoAcceptJoins,
      );

  Map<String, dynamic> toJson() => {
        'maxParticipants': maxParticipants,
        'isPublic': isPublic,
        'allowCursorVisibility': allowCursorVisibility,
        'autoAcceptJoins': autoAcceptJoins,
      };

  factory RoomSettings.fromJson(Map<String, dynamic> json) => RoomSettings(
        maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 20,
        isPublic: (json['isPublic'] as bool?) ?? false,
        allowCursorVisibility:
            (json['allowCursorVisibility'] as bool?) ?? true,
        autoAcceptJoins: (json['autoAcceptJoins'] as bool?) ?? false,
      );
}

/// Immutable snapshot of a collaboration session.
class Session {
  const Session({
    required this.sessionId,
    required this.roomCode,
    required this.hostUserId,
    required this.createdAt,
    this.participants = const {},
    this.history = const [],
    this.settings = const RoomSettings(),
  });

  /// Unique session identifier (UUID).
  final String sessionId;

  /// Short human-readable room code (e.g. "ABCD-1234").
  final String roomCode;

  /// userId of the session owner / host.
  final String hostUserId;
  final DateTime createdAt;

  /// All current participants keyed by userId.
  final Map<String, Participant> participants;

  /// Chronological join/leave log.
  final List<SessionHistoryEntry> history;
  final RoomSettings settings;

  /// Returns the deep-link URL for this session.
  String get shareUrl => 'biscuits://join/$roomCode';

  Session copyWith({
    Map<String, Participant>? participants,
    List<SessionHistoryEntry>? history,
    RoomSettings? settings,
  }) =>
      Session(
        sessionId: sessionId,
        roomCode: roomCode,
        hostUserId: hostUserId,
        createdAt: createdAt,
        participants: participants ?? this.participants,
        history: history ?? this.history,
        settings: settings ?? this.settings,
      );

  PermissionLevel permissionOf(String userId) {
    if (userId == hostUserId) return PermissionLevel.owner;
    return participants[userId]?.permission ?? PermissionLevel.viewer;
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'roomCode': roomCode,
        'hostUserId': hostUserId,
        'createdAt': createdAt.toIso8601String(),
        'participants':
            participants.map((k, v) => MapEntry(k, v.toJson())),
        'history': history.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        sessionId: json['sessionId'] as String,
        roomCode: json['roomCode'] as String,
        hostUserId: json['hostUserId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        participants: (json['participants'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, Participant.fromJson(v as Map<String, dynamic>)),
        ),
        history: (json['history'] as List<dynamic>)
            .map((e) =>
                SessionHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        settings: RoomSettings.fromJson(
            json['settings'] as Map<String, dynamic>),
      );
}
