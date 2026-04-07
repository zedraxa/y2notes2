import 'package:equatable/equatable.dart';
import 'package:biscuitse/features/collaboration/domain/entities/permission.dart';
import 'package:biscuitse/features/collaboration/domain/entities/session.dart';
import 'package:biscuitse/features/collaboration/engine/crdt_engine.dart';
import 'package:biscuitse/features/collaboration/engine/sync_client.dart';

/// All events that can be dispatched to [CollaborationBloc].
abstract class CollaborationEvent extends Equatable {
  const CollaborationEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new collaboration session (caller becomes the host).
class StartSession extends CollaborationEvent {
  const StartSession({this.settings = const RoomSettings()});
  final RoomSettings settings;

  @override
  List<Object?> get props => [settings];
}

/// Join an existing session using a room code or deep-link.
class JoinSession extends CollaborationEvent {
  const JoinSession(this.roomCode);
  final String roomCode;

  @override
  List<Object?> get props => [roomCode];
}

/// Leave (or end) the current session.
class LeaveSession extends CollaborationEvent {
  const LeaveSession();
}

/// A CRDT operation arrived from a remote peer.
class IncomingOperation extends CollaborationEvent {
  const IncomingOperation(this.operation);
  final CrdtOperation operation;

  @override
  List<Object?> get props => [operation];
}

/// Dispatch a local CRDT operation to all peers.
class SendOperation extends CollaborationEvent {
  const SendOperation(this.operation);
  final CrdtOperation operation;

  @override
  List<Object?> get props => [operation];
}

/// A remote user joined the session.
class UserJoined extends CollaborationEvent {
  const UserJoined({required this.userId, required this.displayName});
  final String userId;
  final String displayName;

  @override
  List<Object?> get props => [userId, displayName];
}

/// A remote user left the session.
class UserLeft extends CollaborationEvent {
  const UserLeft(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// The WebSocket connection state changed.
class ConnectionChanged extends CollaborationEvent {
  const ConnectionChanged(this.connectionState);
  final SyncConnectionState connectionState;

  @override
  List<Object?> get props => [connectionState];
}

/// A participant's permission level was changed by the host.
class PermissionChanged extends CollaborationEvent {
  const PermissionChanged({
    required this.userId,
    required this.newLevel,
  });
  final String userId;
  final PermissionLevel newLevel;

  @override
  List<Object?> get props => [userId, newLevel];
}

/// The room settings were updated by the host.
class SessionSettingsUpdated extends CollaborationEvent {
  const SessionSettingsUpdated(this.settings);
  final RoomSettings settings;

  @override
  List<Object?> get props => [settings];
}
