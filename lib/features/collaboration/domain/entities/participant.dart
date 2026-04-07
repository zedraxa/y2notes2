import 'package:flutter/material.dart';
import 'package:y2notes2/features/collaboration/domain/entities/permission.dart';

/// Status of a participant in a collaboration session.
enum PresenceStatus { active, idle, disconnected }

/// Represents a single participant's real-time presence state.
class Participant {
  const Participant({
    required this.userId,
    required this.displayName,
    required this.cursorColor,
    required this.permission,
    this.avatarUrl,
    this.cursorPosition,
    this.activeNodeId,
    this.activeToolName,
    this.status = PresenceStatus.active,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final Color cursorColor;
  final Offset? cursorPosition;
  final String? activeNodeId;
  final String? activeToolName;
  final PresenceStatus status;
  final PermissionLevel permission;

  Participant copyWith({
    String? displayName,
    String? avatarUrl,
    Color? cursorColor,
    Offset? cursorPosition,
    bool clearCursorPosition = false,
    String? activeNodeId,
    bool clearActiveNodeId = false,
    String? activeToolName,
    bool clearActiveToolName = false,
    PresenceStatus? status,
    PermissionLevel? permission,
  }) =>
      Participant(
        userId: userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        cursorColor: cursorColor ?? this.cursorColor,
        cursorPosition: clearCursorPosition
            ? null
            : (cursorPosition ?? this.cursorPosition),
        activeNodeId:
            clearActiveNodeId ? null : (activeNodeId ?? this.activeNodeId),
        activeToolName: clearActiveToolName
            ? null
            : (activeToolName ?? this.activeToolName),
        status: status ?? this.status,
        permission: permission ?? this.permission,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'cursorColor': cursorColor.value,
        'cursorPositionX': cursorPosition?.dx,
        'cursorPositionY': cursorPosition?.dy,
        'activeNodeId': activeNodeId,
        'activeToolName': activeToolName,
        'status': status.name,
        'permission': permission.name,
      };

  factory Participant.fromJson(Map<String, dynamic> json) {
    final px = json['cursorPositionX'] as double?;
    final py = json['cursorPositionY'] as double?;
    return Participant(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      cursorColor: Color(json['cursorColor'] as int),
      cursorPosition: (px != null && py != null) ? Offset(px, py) : null,
      activeNodeId: json['activeNodeId'] as String?,
      activeToolName: json['activeToolName'] as String?,
      status: PresenceStatus.values.byName(json['status'] as String),
      permission:
          PermissionLevel.values.byName(json['permission'] as String),
    );
  }
}

/// Palette of 12 visually distinct colors for participant cursors.
const List<Color> kParticipantColors = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFFE91E63), // pink
  Color(0xFF3949AB), // indigo
  Color(0xFF00897B), // teal
  Color(0xFFF4511E), // deep orange
  Color(0xFF6D4C41), // brown
  Color(0xFF757575), // grey
];

/// Picks a deterministic color from [kParticipantColors] for a given [userId].
Color colorForUser(String userId) {
  final index = userId.codeUnits.fold(0, (sum, c) => sum + c) %
      kParticipantColors.length;
  return kParticipantColors[index];
}
