import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:biscuitse/features/canvas/domain/entities/stroke.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Base node
// ─────────────────────────────────────────────────────────────────────────────

/// Every element placed on the infinite canvas is a [CanvasNode].
///
/// World-space coordinates are used throughout — (0, 0) is the canvas origin.
abstract class CanvasNode {
  CanvasNode({
    required this.id,
    required this.worldPosition,
    required this.worldSize,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Unique identifier.
  final String id;

  /// Centre of the node in world coordinates.
  final Offset worldPosition;

  /// Width/height in world units.
  final Size worldSize;

  /// Rotation in radians around [worldPosition].
  final double rotation;

  /// Stacking order (higher = drawn on top).
  final int zIndex;

  /// When locked the node cannot be moved or resized interactively.
  final bool isLocked;

  /// Creation timestamp (UTC).
  final DateTime createdAt;

  /// Axis-aligned bounding rectangle in world space.
  Rect get worldBounds => Rect.fromCenter(
        center: worldPosition,
        width: worldSize.width,
        height: worldSize.height,
      );

  /// A stable string identifier for the concrete subtype.
  ///
  /// Used for JSON serialisation. Each subclass overrides this.
  String get nodeType;

  /// Subclasses must return a copy with overridden fields.
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  });

  /// JSON serialisation — subclasses call `super.toJson()` and spread the map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': nodeType,
        'worldPosition': {'dx': worldPosition.dx, 'dy': worldPosition.dy},
        'worldSize': {'width': worldSize.width, 'height': worldSize.height},
        'rotation': rotation,
        'zIndex': zIndex,
        'isLocked': isLocked,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Stroke region
// ─────────────────────────────────────────────────────────────────────────────

/// A rectangular region in which freehand [Stroke]s can be drawn.
class StrokeRegionNode extends CanvasNode {
  StrokeRegionNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    this.strokes = const [],
    this.backgroundColor = Colors.white,
    this.cornerRadius = 8.0,
    this.showBorder = true,
    this.title,
  });

  factory StrokeRegionNode.create({
    required Offset worldPosition,
    Size worldSize = const Size(400, 300),
    Color backgroundColor = Colors.white,
    double cornerRadius = 8.0,
    bool showBorder = true,
    String? title,
  }) =>
      StrokeRegionNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: worldSize,
        backgroundColor: backgroundColor,
        cornerRadius: cornerRadius,
        showBorder: showBorder,
        title: title,
      );

  final List<Stroke> strokes;
  final Color backgroundColor;
  final double cornerRadius;
  final bool showBorder;

  /// Optional label displayed above the region.
  final String? title;

  StrokeRegionNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    List<Stroke>? strokes,
    Color? backgroundColor,
    double? cornerRadius,
    bool? showBorder,
    String? title,
  }) =>
      StrokeRegionNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        strokes: strokes ?? this.strokes,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        showBorder: showBorder ?? this.showBorder,
        title: title ?? this.title,
      );

  @override
  String get nodeType => 'StrokeRegionNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'backgroundColor': backgroundColor.value,
        'cornerRadius': cornerRadius,
        'showBorder': showBorder,
        if (title != null) 'title': title,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Text card
// ─────────────────────────────────────────────────────────────────────────────

/// A typed-text card that can optionally auto-resize as content grows.
class TextCardNode extends CanvasNode {
  TextCardNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    this.text = '',
    this.fontSize = 16.0,
    this.textColor = const Color(0xFF1A1A1A),
    this.cardColor = Colors.white,
    this.alignment = TextAlign.left,
    this.autoResize = true,
  });

  factory TextCardNode.create({
    required Offset worldPosition,
    String text = '',
    double fontSize = 16.0,
    Color? cardColor,
  }) =>
      TextCardNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: const Size(250, 150),
        text: text,
        fontSize: fontSize,
        cardColor: cardColor ?? Colors.white,
      );

  final String text;
  final double fontSize;
  final Color textColor;
  final Color cardColor;
  final TextAlign alignment;

  /// When true the card height grows as the user types.
  final bool autoResize;

  TextCardNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? text,
    double? fontSize,
    Color? textColor,
    Color? cardColor,
    TextAlign? alignment,
    bool? autoResize,
  }) =>
      TextCardNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        textColor: textColor ?? this.textColor,
        cardColor: cardColor ?? this.cardColor,
        alignment: alignment ?? this.alignment,
        autoResize: autoResize ?? this.autoResize,
      );

  @override
  String get nodeType => 'TextCardNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'text': text,
        'fontSize': fontSize,
        'textColor': textColor.value,
        'cardColor': cardColor.value,
        'alignment': alignment.index,
        'autoResize': autoResize,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Image node
// ─────────────────────────────────────────────────────────────────────────────

/// An image imported from the device's gallery or filesystem.
class ImageNode extends CanvasNode {
  ImageNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    required this.imagePath,
    this.opacity = 1.0,
    this.fit = BoxFit.contain,
  });

  factory ImageNode.create({
    required Offset worldPosition,
    required String imagePath,
    Size worldSize = const Size(300, 200),
  }) =>
      ImageNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: worldSize,
        imagePath: imagePath,
      );

  final String imagePath;
  final double opacity;
  final BoxFit fit;

  ImageNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? imagePath,
    double? opacity,
    BoxFit? fit,
  }) =>
      ImageNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        imagePath: imagePath ?? this.imagePath,
        opacity: opacity ?? this.opacity,
        fit: fit ?? this.fit,
      );

  @override
  String get nodeType => 'ImageNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'imagePath': imagePath,
        'opacity': opacity,
        'fit': fit.index,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky note
// ─────────────────────────────────────────────────────────────────────────────

/// A coloured sticky-note square with editable text.
class StickyNoteNode extends CanvasNode {
  StickyNoteNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    this.text = '',
    this.color = const Color(0xFFFFF176), // yellow
    this.fontSize = 14.0,
  });

  factory StickyNoteNode.create({
    required Offset worldPosition,
    Color? color,
  }) =>
      StickyNoteNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: const Size(200, 200),
        color: color ?? const Color(0xFFFFF176),
      );

  final String text;

  /// Background colour — yellow, pink, blue, green or purple.
  final Color color;
  final double fontSize;

  StickyNoteNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? text,
    Color? color,
    double? fontSize,
  }) =>
      StickyNoteNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        text: text ?? this.text,
        color: color ?? this.color,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  String get nodeType => 'StickyNoteNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'text': text,
        'color': color.value,
        'fontSize': fontSize,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Group node
// ─────────────────────────────────────────────────────────────────────────────

/// A logical grouping of other nodes.
class GroupNode extends CanvasNode {
  GroupNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    this.childNodeIds = const [],
    this.groupColor,
    this.groupLabel,
  });

  factory GroupNode.create({
    required Offset worldPosition,
    required Size worldSize,
    required List<String> childNodeIds,
    String? groupLabel,
    Color? groupColor,
  }) =>
      GroupNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: worldSize,
        childNodeIds: childNodeIds,
        groupLabel: groupLabel,
        groupColor: groupColor,
      );

  final List<String> childNodeIds;
  final Color? groupColor;
  final String? groupLabel;

  GroupNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    List<String>? childNodeIds,
    Color? groupColor,
    String? groupLabel,
  }) =>
      GroupNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        childNodeIds: childNodeIds ?? this.childNodeIds,
        groupColor: groupColor ?? this.groupColor,
        groupLabel: groupLabel ?? this.groupLabel,
      );

  @override
  String get nodeType => 'GroupNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'childNodeIds': childNodeIds,
        if (groupColor != null) 'groupColor': groupColor!.value,
        if (groupLabel != null) 'groupLabel': groupLabel,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Frame node
// ─────────────────────────────────────────────────────────────────────────────

/// A Figma-style named container that can clip its children.
class FrameNode extends CanvasNode {
  FrameNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    this.label = 'Frame',
    this.frameColor = const Color(0xFF2196F3),
    this.clipContent = false,
    this.childNodeIds = const [],
  });

  factory FrameNode.create({
    required Offset worldPosition,
    required Size worldSize,
    String label = 'Frame',
    Color? frameColor,
  }) =>
      FrameNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: worldSize,
        label: label,
        frameColor: frameColor ?? const Color(0xFF2196F3),
      );

  final String label;
  final Color frameColor;
  final bool clipContent;
  final List<String> childNodeIds;

  FrameNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? label,
    Color? frameColor,
    bool? clipContent,
    List<String>? childNodeIds,
  }) =>
      FrameNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        label: label ?? this.label,
        frameColor: frameColor ?? this.frameColor,
        clipContent: clipContent ?? this.clipContent,
        childNodeIds: childNodeIds ?? this.childNodeIds,
      );

  @override
  String get nodeType => 'FrameNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'label': label,
        'frameColor': frameColor.value,
        'clipContent': clipContent,
        'childNodeIds': childNodeIds,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Embedded notebook page
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a thumbnail preview of a regular notebook page inside the canvas.
class EmbeddedPageNode extends CanvasNode {
  EmbeddedPageNode({
    required super.id,
    required super.worldPosition,
    required super.worldSize,
    super.rotation,
    super.zIndex,
    super.isLocked,
    super.createdAt,
    required this.notebookId,
    required this.pageNumber,
  });

  factory EmbeddedPageNode.create({
    required Offset worldPosition,
    required String notebookId,
    required int pageNumber,
  }) =>
      EmbeddedPageNode(
        id: const Uuid().v4(),
        worldPosition: worldPosition,
        worldSize: const Size(240, 340),
        notebookId: notebookId,
        pageNumber: pageNumber,
      );

  final String notebookId;
  final int pageNumber;

  EmbeddedPageNode copyWith({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? notebookId,
    int? pageNumber,
  }) =>
      EmbeddedPageNode(
        id: id,
        worldPosition: worldPosition ?? this.worldPosition,
        worldSize: worldSize ?? this.worldSize,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        isLocked: isLocked ?? this.isLocked,
        createdAt: createdAt,
        notebookId: notebookId ?? this.notebookId,
        pageNumber: pageNumber ?? this.pageNumber,
      );

  @override
  String get nodeType => 'EmbeddedPageNode';

  @override
  CanvasNode copyWithBase({
    Offset? worldPosition,
    Size? worldSize,
    double? rotation,
    int? zIndex,
    bool? isLocked,
  }) =>
      copyWith(
        worldPosition: worldPosition,
        worldSize: worldSize,
        rotation: rotation,
        zIndex: zIndex,
        isLocked: isLocked,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'notebookId': notebookId,
        'pageNumber': pageNumber,
      };
}
