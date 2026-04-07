import 'dart:math' as math;

/// Logical clock that tracks causality in a distributed system.
///
/// Each node maintains its own counter and knows the last-seen counter
/// of every peer. This enables causal ordering of operations.
class VectorClock {
  VectorClock([Map<String, int>? initial])
      : clocks = Map<String, int>.from(initial ?? {});

  final Map<String, int> clocks;

  /// Returns a new clock with [nodeId]'s counter incremented by 1.
  VectorClock increment(String nodeId) {
    final next = Map<String, int>.from(clocks);
    next[nodeId] = (next[nodeId] ?? 0) + 1;
    return VectorClock(next);
  }

  /// Returns a new clock that is the component-wise maximum of this and [other].
  VectorClock merge(VectorClock other) {
    final merged = Map<String, int>.from(clocks);
    for (final entry in other.clocks.entries) {
      merged[entry.key] =
          math.max(merged[entry.key] ?? 0, entry.value);
    }
    return VectorClock(merged);
  }

  /// True when every component of [this] ≤ [other] and at least one is strictly less.
  bool happensBefore(VectorClock other) {
    bool strictlyLess = false;
    for (final key in {...clocks.keys, ...other.clocks.keys}) {
      final a = clocks[key] ?? 0;
      final b = other.clocks[key] ?? 0;
      if (a > b) return false;
      if (a < b) strictlyLess = true;
    }
    return strictlyLess;
  }

  /// True when neither clock happens-before the other (concurrent events).
  bool isConcurrent(VectorClock other) =>
      !happensBefore(other) && !other.happensBefore(this);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(clocks);

  factory VectorClock.fromJson(Map<String, dynamic> json) =>
      VectorClock(json.map((k, v) => MapEntry(k, (v as num).toInt())));

  @override
  String toString() => 'VectorClock($clocks)';
}

// ─── Base operation ──────────────────────────────────────────────────────────

/// Base class for all CRDT operations.
abstract class CrdtOperation {
  CrdtOperation({
    required this.operationId,
    required this.authorId,
    required this.clock,
    required this.timestamp,
  });

  final String operationId;
  final String authorId;
  final VectorClock clock;
  final DateTime timestamp;

  String get type;

  Map<String, dynamic> toJson();

  /// Deserialises any [CrdtOperation] subclass from JSON.
  static CrdtOperation fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'StrokeInsert':
        return StrokeInsertOp.fromJson(json);
      case 'StrokeDelete':
        return StrokeDeleteOp.fromJson(json);
      case 'NodeMove':
        return NodeMoveOp.fromJson(json);
      case 'NodeUpdate':
        return NodeUpdateOp.fromJson(json);
      case 'EdgeAdd':
        return EdgeAddOp.fromJson(json);
      case 'EdgeRemove':
        return EdgeRemoveOp.fromJson(json);
      case 'TextEdit':
        return TextEditOp.fromJson(json);
      default:
        throw ArgumentError('Unknown CrdtOperation type: $type');
    }
  }

  Map<String, dynamic> _baseJson() => {
        'type': type,
        'operationId': operationId,
        'authorId': authorId,
        'clock': clock.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}

// ─── Stroke operations ────────────────────────────────────────────────────────

/// Serialisable point with stylus data.
class CrdtPoint {
  const CrdtPoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.tilt = 0.0,
  });

  final double x;
  final double y;
  final double pressure;
  final double tilt;

  Map<String, dynamic> toJson() =>
      {'x': x, 'y': y, 'pressure': pressure, 'tilt': tilt};

  factory CrdtPoint.fromJson(Map<String, dynamic> j) => CrdtPoint(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        pressure: (j['pressure'] as num?)?.toDouble() ?? 0.5,
        tilt: (j['tilt'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Insert a new freehand stroke.
class StrokeInsertOp extends CrdtOperation {
  StrokeInsertOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.strokeId,
    required this.points,
    required this.toolId,
    required this.colorValue,
    required this.baseWidth,
  });

  final String strokeId;
  final List<CrdtPoint> points;
  final String toolId;
  final int colorValue;
  final double baseWidth;

  @override
  String get type => 'StrokeInsert';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'strokeId': strokeId,
        'points': points.map((p) => p.toJson()).toList(),
        'toolId': toolId,
        'colorValue': colorValue,
        'baseWidth': baseWidth,
      };

  factory StrokeInsertOp.fromJson(Map<String, dynamic> j) => StrokeInsertOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        strokeId: j['strokeId'] as String,
        points: (j['points'] as List<dynamic>)
            .map((p) => CrdtPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        toolId: j['toolId'] as String,
        colorValue: (j['colorValue'] as num).toInt(),
        baseWidth: (j['baseWidth'] as num).toDouble(),
      );
}

/// Delete an existing stroke.
class StrokeDeleteOp extends CrdtOperation {
  StrokeDeleteOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.strokeId,
  });

  final String strokeId;

  @override
  String get type => 'StrokeDelete';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'strokeId': strokeId,
      };

  factory StrokeDeleteOp.fromJson(Map<String, dynamic> j) => StrokeDeleteOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        strokeId: j['strokeId'] as String,
      );
}

// ─── Node operations ──────────────────────────────────────────────────────────

/// Move a canvas node (sticker, shape, text card).
class NodeMoveOp extends CrdtOperation {
  NodeMoveOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.nodeId,
    required this.x,
    required this.y,
  });

  final String nodeId;
  final double x;
  final double y;

  @override
  String get type => 'NodeMove';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'nodeId': nodeId,
        'x': x,
        'y': y,
      };

  factory NodeMoveOp.fromJson(Map<String, dynamic> j) => NodeMoveOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        nodeId: j['nodeId'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
      );
}

/// Update arbitrary properties of a node (e.g. size, text content).
class NodeUpdateOp extends CrdtOperation {
  NodeUpdateOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.nodeId,
    required this.properties,
  });

  final String nodeId;

  /// Key/value map of changed properties.
  final Map<String, dynamic> properties;

  @override
  String get type => 'NodeUpdate';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'nodeId': nodeId,
        'properties': properties,
      };

  factory NodeUpdateOp.fromJson(Map<String, dynamic> j) => NodeUpdateOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        nodeId: j['nodeId'] as String,
        properties: Map<String, dynamic>.from(
            j['properties'] as Map<String, dynamic>),
      );
}

// ─── Edge operations ──────────────────────────────────────────────────────────

/// Add a directed edge between two nodes.
class EdgeAddOp extends CrdtOperation {
  EdgeAddOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.edgeId,
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
  });

  final String edgeId;
  final String fromNodeId;
  final String toNodeId;
  final String? label;

  @override
  String get type => 'EdgeAdd';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'edgeId': edgeId,
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        if (label != null) 'label': label,
      };

  factory EdgeAddOp.fromJson(Map<String, dynamic> j) => EdgeAddOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        edgeId: j['edgeId'] as String,
        fromNodeId: j['fromNodeId'] as String,
        toNodeId: j['toNodeId'] as String,
        label: j['label'] as String?,
      );
}

/// Remove an existing edge.
class EdgeRemoveOp extends CrdtOperation {
  EdgeRemoveOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.edgeId,
  });

  final String edgeId;

  @override
  String get type => 'EdgeRemove';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'edgeId': edgeId,
      };

  factory EdgeRemoveOp.fromJson(Map<String, dynamic> j) => EdgeRemoveOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        edgeId: j['edgeId'] as String,
      );
}

// ─── Text edit operation ───────────────────────────────────────────────────────

/// A character-level insert or delete in a collaborative text node.
///
/// Used alongside [TextCrdt] (see text_crdt.dart) to broadcast individual
/// character operations to peers.
class TextEditOp extends CrdtOperation {
  TextEditOp({
    required super.operationId,
    required super.authorId,
    required super.clock,
    required super.timestamp,
    required this.nodeId,
    required this.charId,
    required this.isInsert,
    this.character,
    this.afterCharId,
  });

  /// The text-card or sticky-note node being edited.
  final String nodeId;

  /// Unique ID for this character (used in RGA CRDT).
  final String charId;

  /// True = insert; false = delete.
  final bool isInsert;

  /// The character being inserted (null for delete).
  final String? character;

  /// ID of the character after which this one is inserted (null = insert at head).
  final String? afterCharId;

  @override
  String get type => 'TextEdit';

  @override
  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        'nodeId': nodeId,
        'charId': charId,
        'isInsert': isInsert,
        if (character != null) 'character': character,
        if (afterCharId != null) 'afterCharId': afterCharId,
      };

  factory TextEditOp.fromJson(Map<String, dynamic> j) => TextEditOp(
        operationId: j['operationId'] as String,
        authorId: j['authorId'] as String,
        clock: VectorClock.fromJson(j['clock'] as Map<String, dynamic>),
        timestamp: DateTime.parse(j['timestamp'] as String),
        nodeId: j['nodeId'] as String,
        charId: j['charId'] as String,
        isInsert: j['isInsert'] as bool,
        character: j['character'] as String?,
        afterCharId: j['afterCharId'] as String?,
      );
}

// ─── CRDT document state ──────────────────────────────────────────────────────

/// Maintains the set of applied operation IDs to guarantee idempotency.
///
/// All remote (and local) operations pass through [apply] before being
/// reflected in the local canvas. Duplicate operations are silently ignored,
/// ensuring at-least-once delivery from the transport layer is safe.
class CrdtEngine {
  CrdtEngine(this.localNodeId)
      : _clock = VectorClock(),
        _appliedIds = {};

  final String localNodeId;
  VectorClock _clock;
  final Set<String> _appliedIds;

  /// The current local vector clock.
  VectorClock get clock => _clock;

  /// Increments the local clock and returns a new clock value for outgoing ops.
  VectorClock tick() {
    _clock = _clock.increment(localNodeId);
    return _clock;
  }

  /// Updates the local clock after receiving a remote operation.
  void receive(VectorClock remoteClock) {
    _clock = _clock.merge(remoteClock).increment(localNodeId);
  }

  /// Returns true if [op] has not been applied yet (idempotency check).
  bool shouldApply(CrdtOperation op) {
    if (_appliedIds.contains(op.operationId)) return false;
    _appliedIds.add(op.operationId);
    receive(op.clock);
    return true;
  }

  /// Resets the engine state (e.g. on session leave).
  void reset() {
    _clock = VectorClock();
    _appliedIds.clear();
  }
}
