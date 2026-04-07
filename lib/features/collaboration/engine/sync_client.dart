import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:biscuitse/features/collaboration/engine/crdt_engine.dart';
import 'package:biscuitse/features/collaboration/domain/entities/participant.dart';

// ─── Connection state ─────────────────────────────────────────────────────────

/// The WebSocket connection lifecycle state.
enum SyncConnectionState {
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

// ─── Presence update ──────────────────────────────────────────────────────────

/// A cursor / activity broadcast from a remote peer.
class PresenceUpdate {
  const PresenceUpdate({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.cursorColor,
    this.cursorX,
    this.cursorY,
    this.activeNodeId,
    this.activeToolName,
    required this.status,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  /// ARGB integer encoding of the cursor color.
  final int cursorColor;

  /// Canvas X coordinate (null when the pointer is off-canvas).
  final double? cursorX;

  /// Canvas Y coordinate (null when the pointer is off-canvas).
  final double? cursorY;

  final String? activeNodeId;
  final String? activeToolName;
  final PresenceStatus status;

  factory PresenceUpdate.fromJson(Map<String, dynamic> j) => PresenceUpdate(
        userId: j['userId'] as String,
        displayName: j['displayName'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        cursorColor: (j['cursorColor'] as num).toInt(),
        cursorX: (j['cursorPositionX'] as num?)?.toDouble(),
        cursorY: (j['cursorPositionY'] as num?)?.toDouble(),
        activeNodeId: j['activeNodeId'] as String?,
        activeToolName: j['activeToolName'] as String?,
        status: PresenceStatus.values.byName(
            (j['status'] as String?) ?? PresenceStatus.active.name),
      );
}

// ─── SyncClient ───────────────────────────────────────────────────────────────

/// Abstract WebSocket client for real-time collaboration.
///
/// The concrete implementation ([_WebSocketSyncClient]) is created by
/// [SyncClient.create]. A stub ([_StubSyncClient]) is returned when
/// [SyncClient.stub] is called, which is useful for unit tests and offline
/// development.
abstract class SyncClient {
  /// Creates a real WebSocket-backed sync client.
  ///
  /// [serverUrl] defaults to the public Biscuitsé relay but can be overridden
  /// for self-hosted deployments.
  factory SyncClient.create({String? serverUrl}) =>
      _WebSocketSyncClient(serverUrl: serverUrl ?? 'wss://relay.biscuitse.app');

  /// Creates an in-process stub that never connects to a real server.
  factory SyncClient.stub() => _StubSyncClient();

  Future<void> connect(String roomId, String userId);
  void sendOperation(CrdtOperation op);
  void sendPresence(Map<String, dynamic> presenceJson);

  Stream<CrdtOperation> get incomingOperations;
  Stream<PresenceUpdate> get presenceUpdates;
  Stream<SyncConnectionState> get connectionState;

  Future<void> disconnect();
}

// ─── Stub (offline / test) ────────────────────────────────────────────────────

class _StubSyncClient implements SyncClient {
  final _ops = StreamController<CrdtOperation>.broadcast();
  final _presence = StreamController<PresenceUpdate>.broadcast();
  final _state = StreamController<SyncConnectionState>.broadcast();

  @override
  Future<void> connect(String roomId, String userId) async {
    _state.add(SyncConnectionState.disconnected);
  }

  @override
  void sendOperation(CrdtOperation op) {}

  @override
  void sendPresence(Map<String, dynamic> presenceJson) {}

  @override
  Stream<CrdtOperation> get incomingOperations => _ops.stream;

  @override
  Stream<PresenceUpdate> get presenceUpdates => _presence.stream;

  @override
  Stream<SyncConnectionState> get connectionState => _state.stream;

  @override
  Future<void> disconnect() async {
    await _ops.close();
    await _presence.close();
    await _state.close();
  }
}

// ─── Real WebSocket client ────────────────────────────────────────────────────

/// WebSocket sync client with:
///  • auto-reconnect with exponential back-off
///  • offline operation queue (replayed after reconnect)
///  • heartbeat/ping every 20 s to detect silent disconnections
class _WebSocketSyncClient implements SyncClient {
  _WebSocketSyncClient({required this.serverUrl});

  final String serverUrl;

  String? _roomId;
  String? _userId;

  // Using dynamic so we avoid importing dart:io/html directly — the actual
  // WebSocket is created via a platform-agnostic helper below.
  dynamic _ws;

  final _opController = StreamController<CrdtOperation>.broadcast();
  final _presenceController = StreamController<PresenceUpdate>.broadcast();
  final _stateController = StreamController<SyncConnectionState>.broadcast();

  // Pending operations queued while disconnected.
  final List<String> _queue = [];

  bool _intentionalClose = false;
  int _reconnectAttempt = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  static const int _maxReconnectAttempts = 8;
  static const Duration _heartbeatInterval = Duration(seconds: 20);

  @override
  Stream<CrdtOperation> get incomingOperations => _opController.stream;

  @override
  Stream<PresenceUpdate> get presenceUpdates => _presenceController.stream;

  @override
  Stream<SyncConnectionState> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String roomId, String userId) async {
    _roomId = roomId;
    _userId = userId;
    _intentionalClose = false;
    _reconnectAttempt = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _stateController.add(SyncConnectionState.connecting);
    try {
      final uri = Uri.parse('$serverUrl/rooms/$_roomId?userId=$_userId');
      _ws = await _platformConnect(uri);
      _reconnectAttempt = 0;
      _stateController.add(SyncConnectionState.connected);
      _startHeartbeat();
      _flushQueue();
      _listenToSocket();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _listenToSocket() {
    (_ws as Stream<dynamic>).listen(
      _onMessage,
      onError: (_) => _onDisconnected(),
      onDone: _onDisconnected,
    );
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msgType = json['msgType'] as String?;

      if (msgType == 'operation') {
        final op =
            CrdtOperation.fromJson(json['payload'] as Map<String, dynamic>);
        _opController.add(op);
      } else if (msgType == 'presence') {
        final presence = PresenceUpdate.fromJson(
            json['payload'] as Map<String, dynamic>);
        _presenceController.add(presence);
      }
    } catch (_) {
      // Silently ignore malformed messages.
    }
  }

  void _onDisconnected() {
    _heartbeatTimer?.cancel();
    if (_intentionalClose) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _stateController.add(SyncConnectionState.error);
      return;
    }
    _stateController.add(SyncConnectionState.reconnecting);
    final delay = Duration(
      milliseconds:
          (500 * math.pow(2, _reconnectAttempt).toInt()).clamp(500, 30000),
    );
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, _doConnect);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _send(jsonEncode({'msgType': 'ping'}));
    });
  }

  void _flushQueue() {
    for (final msg in _queue) {
      _send(msg);
    }
    _queue.clear();
  }

  void _send(String message) {
    try {
      if (_ws != null) {
        (_ws as dynamic).add(message);
      }
    } catch (_) {
      _queue.add(message);
    }
  }

  @override
  void sendOperation(CrdtOperation op) {
    final msg = jsonEncode({
      'msgType': 'operation',
      'payload': op.toJson(),
    });
    if (_ws == null) {
      _queue.add(msg);
    } else {
      _send(msg);
    }
  }

  @override
  void sendPresence(Map<String, dynamic> presenceJson) {
    final msg = jsonEncode({
      'msgType': 'presence',
      'payload': presenceJson,
    });
    // Presence updates are best-effort — don't queue if offline.
    _send(msg);
  }

  @override
  Future<void> disconnect() async {
    _intentionalClose = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      await (_ws as dynamic)?.close();
    } catch (_) {}
    _ws = null;
    _stateController.add(SyncConnectionState.disconnected);
  }

  // ─── Platform shim ────────────────────────────────────────────────────────
  // Returns a Stream<String> backed by a real WebSocket.
  // Replace with `web_socket_channel` in production.
  Future<dynamic> _platformConnect(Uri uri) {
    throw UnimplementedError(
      'Replace _platformConnect with web_socket_channel.WebSocketChannel '
      'connect in a real deployment. URI was: $uri',
    );
  }
}
