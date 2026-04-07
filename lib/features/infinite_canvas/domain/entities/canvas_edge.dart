import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Defines the visual style of a connection line.
enum EdgeStyle {
  /// Continuous line.
  solid,

  /// Dashed line.
  dashed,

  /// Dotted line.
  dotted,
}

/// How the path between two nodes is drawn.
enum EdgePathType {
  /// Straight line.
  straight,

  /// Simple quadratic bezier curve.
  curved,

  /// Axis-aligned right-angle routing.
  orthogonal,

  /// Cubic bezier with configurable control points.
  bezier,
}

/// Which side of a node an edge connects to.
enum AnchorPoint {
  top,
  bottom,
  left,
  right,
  center,

  /// The engine picks the closest anchor automatically.
  auto,
}

/// Decoration at the end of an edge line.
enum ArrowStyle {
  none,
  arrow,
  filledArrow,
  diamond,
  filledDiamond,
  circle,
  filledCircle,
}

/// A visual connection between two [CanvasNode]s — the core of mind mapping.
class CanvasEdge {
  CanvasEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.style = EdgeStyle.solid,
    this.color = const Color(0xFF757575),
    this.width = 2.0,
    this.label,
    this.sourceAnchor = AnchorPoint.auto,
    this.targetAnchor = AnchorPoint.auto,
    this.pathType = EdgePathType.curved,
    this.controlPoint1,
    this.controlPoint2,
    this.sourceArrow = ArrowStyle.none,
    this.targetArrow = ArrowStyle.filledArrow,
  });

  /// Create a new edge with a generated UUID.
  factory CanvasEdge.create({
    required String sourceNodeId,
    required String targetNodeId,
    EdgeStyle style = EdgeStyle.solid,
    Color color = const Color(0xFF757575),
    double width = 2.0,
    String? label,
    AnchorPoint sourceAnchor = AnchorPoint.auto,
    AnchorPoint targetAnchor = AnchorPoint.auto,
    EdgePathType pathType = EdgePathType.curved,
    ArrowStyle sourceArrow = ArrowStyle.none,
    ArrowStyle targetArrow = ArrowStyle.filledArrow,
  }) =>
      CanvasEdge(
        id: const Uuid().v4(),
        sourceNodeId: sourceNodeId,
        targetNodeId: targetNodeId,
        style: style,
        color: color,
        width: width,
        label: label,
        sourceAnchor: sourceAnchor,
        targetAnchor: targetAnchor,
        pathType: pathType,
        sourceArrow: sourceArrow,
        targetArrow: targetArrow,
      );

  final String id;
  final String sourceNodeId;
  final String targetNodeId;

  final EdgeStyle style;
  final Color color;
  final double width;

  /// Optional text label rendered at the midpoint of the edge.
  final String? label;

  final AnchorPoint sourceAnchor;
  final AnchorPoint targetAnchor;

  final EdgePathType pathType;

  /// First control point for bezier paths (world coordinates).
  final Offset? controlPoint1;

  /// Second control point for bezier paths (world coordinates).
  final Offset? controlPoint2;

  final ArrowStyle? sourceArrow;
  final ArrowStyle? targetArrow;

  CanvasEdge copyWith({
    String? sourceNodeId,
    String? targetNodeId,
    EdgeStyle? style,
    Color? color,
    double? width,
    String? label,
    AnchorPoint? sourceAnchor,
    AnchorPoint? targetAnchor,
    EdgePathType? pathType,
    Offset? controlPoint1,
    Offset? controlPoint2,
    ArrowStyle? sourceArrow,
    ArrowStyle? targetArrow,
  }) =>
      CanvasEdge(
        id: id,
        sourceNodeId: sourceNodeId ?? this.sourceNodeId,
        targetNodeId: targetNodeId ?? this.targetNodeId,
        style: style ?? this.style,
        color: color ?? this.color,
        width: width ?? this.width,
        label: label ?? this.label,
        sourceAnchor: sourceAnchor ?? this.sourceAnchor,
        targetAnchor: targetAnchor ?? this.targetAnchor,
        pathType: pathType ?? this.pathType,
        controlPoint1: controlPoint1 ?? this.controlPoint1,
        controlPoint2: controlPoint2 ?? this.controlPoint2,
        sourceArrow: sourceArrow ?? this.sourceArrow,
        targetArrow: targetArrow ?? this.targetArrow,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        'style': style.name,
        'color': color.value,
        'width': width,
        if (label != null) 'label': label,
        'sourceAnchor': sourceAnchor.name,
        'targetAnchor': targetAnchor.name,
        'pathType': pathType.name,
        if (controlPoint1 != null)
          'controlPoint1': {
            'dx': controlPoint1!.dx,
            'dy': controlPoint1!.dy,
          },
        if (controlPoint2 != null)
          'controlPoint2': {
            'dx': controlPoint2!.dx,
            'dy': controlPoint2!.dy,
          },
        'sourceArrow': sourceArrow?.name,
        'targetArrow': targetArrow?.name,
      };

  factory CanvasEdge.fromJson(Map<String, dynamic> json) {
    Offset? _parseOffset(dynamic raw) {
      if (raw == null) return null;
      final m = raw as Map<String, dynamic>;
      return Offset(
        (m['dx'] as num).toDouble(),
        (m['dy'] as num).toDouble(),
      );
    }

    return CanvasEdge(
      id: json['id'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      targetNodeId: json['targetNodeId'] as String,
      style: EdgeStyle.values.byName(json['style'] as String),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      label: json['label'] as String?,
      sourceAnchor: AnchorPoint.values.byName(json['sourceAnchor'] as String),
      targetAnchor: AnchorPoint.values.byName(json['targetAnchor'] as String),
      pathType: EdgePathType.values.byName(json['pathType'] as String),
      controlPoint1: _parseOffset(json['controlPoint1']),
      controlPoint2: _parseOffset(json['controlPoint2']),
      sourceArrow: json['sourceArrow'] != null
          ? ArrowStyle.values.byName(json['sourceArrow'] as String)
          : null,
      targetArrow: json['targetArrow'] != null
          ? ArrowStyle.values.byName(json['targetArrow'] as String)
          : null,
    );
  }
}
