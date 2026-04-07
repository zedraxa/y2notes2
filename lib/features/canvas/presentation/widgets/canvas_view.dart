import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/engine/canvas_engine.dart';
import 'package:y2notes2/core/engine/stylus/hover_cursor.dart';
import 'package:y2notes2/core/engine/stylus/stylus_adapter.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';
import 'package:y2notes2/core/extensions/iterable_extensions.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/page_background.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/offline_indicator.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/remote_cursors.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effects_engine.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/handwriting/domain/entities/text_block.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/shapes/engine/shape_hit_tester.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_bloc.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_event.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_state.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/shape_handles.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/shape_properties_panel.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/snap_guides_overlay.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_state.dart';
import 'package:y2notes2/features/stickers/presentation/widgets/sticker_interaction_handler.dart';
import 'package:y2notes2/shared/widgets/service_provider.dart';

/// The actual drawing surface.
///
/// Uses a [Listener] widget (not GestureDetector) to access raw stylus
/// pressure/tilt data from [PointerEvent]. Pan & zoom are handled by
/// [InteractiveViewer].
class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView>
    with TickerProviderStateMixin {
  late final WritingEffectsEngine _effectsEngine;
  late final InteractionEffectsEngine _interactionEngine;
  late final CanvasEngine _canvasEngine;
  late final TransformationController _transformController;
  PointData? _lastPoint;
  double _lastScale = 1.0;

  /// Cached reference to SettingsService — used for pressure curve + sensitivity.
  late SettingsService _settingsService;

  /// Exponential moving average factor for pressure smoothing.
  /// 0 = no smoothing, 1 = full lag. 0.3 provides subtle jitter rejection
  /// without perceptible input delay.
  static const double _pressureSmoothingFactor = 0.3;

  // Tracks whether the current pointer gesture is a shape interaction
  // (drag/resize), so that pointer move/up events are routed to ShapeBloc
  // instead of the stroke drawing pipeline.
  bool _activeShapeGesture = false;

  // For detecting undo/redo/tool-switch between BLoC states
  int _prevStrokeCount = 0;
  int _prevRedoCount = 0;
  String _prevToolId = '';

  @override
  void initState() {
    super.initState();
    _effectsEngine = WritingEffectsEngine();
    _interactionEngine = InteractionEffectsEngine();
    _canvasEngine = CanvasEngine(
      vsync: this,
      effectsEngine: _effectsEngine,
      interactionEngine: _interactionEngine,
    );
    _transformController = TransformationController();

    // Rebuild the canvas view on each animation frame
    _canvasEngine.addListener(_onEngineUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Apply persisted interaction effect settings once the widget tree is ready.
    final settings = ServiceProvider.of<SettingsService>(context);
    _settingsService = settings;
    _interactionEngine.enabled = settings.interactionEffectsEnabledNotifier.value;
    for (final id in SettingsService.interactionEffectNames) {
      _interactionEngine.setEffectEnabled(
          id, settings.isInteractionEffectEnabled(id));
      _interactionEngine.setEffectIntensity(
          id, settings.interactionEffectIntensity(id));
    }
  }

  @override
  void dispose() {
    _canvasEngine
      ..removeListener(_onEngineUpdate)
      ..dispose();
    _effectsEngine.dispose();
    _interactionEngine.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  // ─── Pointer event handlers ───────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    final canvasBloc = context.read<CanvasBloc>();

    // Detect and report stylus type.
    final stylusType = StylusDetector.detectStylusType(event);
    canvasBloc.add(StylusDetectedEvent(stylusType));

    // When pen touches the screen, clear any hover state.
    if (canvasBloc.state.isHovering) {
      canvasBloc.add(const HoverEnded());
    }

    // ── Shape hit-testing ─────────────────────────────────────────────────
    // When shapes exist on the canvas, check whether the pointer landed on a
    // shape body or resize/rotation handle.  If so, route the gesture to the
    // ShapeBloc instead of starting a new ink stroke.
    final shapes = canvasBloc.state.shapes;
    if (shapes.isNotEmpty) {
      final hit = ShapeHitTester.hitTest(shapes, event.localPosition);
      if (hit != null) {
        final shapeBloc = context.read<ShapeBloc>();
        if (hit.isHandle) {
          shapeBloc.add(HandleDragStarted(
            shapeId: hit.shapeId,
            handleIndex: hit.handleIndex!,
            startPoint: event.localPosition,
          ));
        } else {
          shapeBloc.add(ShapeTapped(hit.shapeId));
          shapeBloc.add(ShapeDragStarted(
            shapeId: hit.shapeId,
            startPoint: event.localPosition,
          ));
        }
        _activeShapeGesture = true;
        return; // Do NOT start an ink stroke.
      }

      // Tapped on empty canvas — deselect any selected shape.
      if (canvasBloc.state.selectedShapeId != null) {
        context.read<ShapeBloc>().add(const ShapeDeselectedEvent());
      }
    }

    // ── Regular ink stroke ─────────────────────────────────────────────────
    _activeShapeGesture = false;
    final input = StylusAdapterFactory.convert(event);
    final point = _stylusInputToPointData(input, null);
    _lastPoint = point;
    canvasBloc.add(StrokeStarted(point));

    // Notify effects engines
    final state = canvasBloc.state;
    if (state.effectsEnabled) {
      _effectsEngine.onStrokeStart(point);
      _interactionEngine.onTouchDown(
        event.localPosition,
        toolColor: state.activeColor,
        pressure: event.pressure.clamp(0.0, 1.0),
      );
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    // Route to ShapeBloc if this gesture started on a shape.
    if (_activeShapeGesture) {
      final shapeBloc = context.read<ShapeBloc>();
      final shapeState = shapeBloc.state;
      if (shapeState.isDragging) {
        shapeBloc.add(ShapeDragUpdated(event.localPosition));
      } else if (shapeState.isResizing) {
        shapeBloc.add(HandleDragUpdated(event.localPosition));
      }
      return;
    }

    final bloc = context.read<CanvasBloc>();
    final prev = _lastPoint;

    final input = StylusAdapterFactory.convert(event);
    final point = _stylusInputToPointData(input, prev);
    _lastPoint = point;
    bloc.add(StrokeUpdated(point));

    final state = bloc.state;
    if (state.effectsEnabled && state.activeStroke != null) {
      _effectsEngine.onStrokePoint(point, prev, state.activeStroke!);
    }

    // Forward cursor position to collaboration presence manager.
    context
        .read<CollaborationBloc>()
        .updateCursorPosition(Offset(point.x, point.y));
  }

  void _onPointerUp(PointerUpEvent event) {
    // End a shape drag/resize gesture.
    if (_activeShapeGesture) {
      _activeShapeGesture = false;
      final shapeBloc = context.read<ShapeBloc>();
      final shapeState = shapeBloc.state;
      if (shapeState.isDragging) {
        shapeBloc.add(const ShapeDragEnded());
      } else if (shapeState.isResizing) {
        shapeBloc.add(const HandleDragEnded());
      }
      return;
    }

    final bloc = context.read<CanvasBloc>();
    // Capture active stroke BEFORE adding StrokeEnded (which clears it)
    final activeStroke = bloc.state.activeStroke;
    final effectsEnabled = bloc.state.effectsEnabled;
    bloc.add(const StrokeEnded());
    if (effectsEnabled && activeStroke != null) {
      _effectsEngine.onStrokeEnd(activeStroke);
    }
    _lastPoint = null;
    context.read<CollaborationBloc>().clearCursorPosition();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activeShapeGesture) {
      _activeShapeGesture = false;
      final shapeBloc = context.read<ShapeBloc>();
      if (shapeBloc.state.isDragging) {
        shapeBloc.add(const ShapeDragEnded());
      } else if (shapeBloc.state.isResizing) {
        shapeBloc.add(const HandleDragEnded());
      }
      return;
    }
    context.read<CanvasBloc>()
      ..add(const StrokeEnded())
      ..add(const HoverEnded());
    context.read<CollaborationBloc>().clearCursorPosition();
    _lastPoint = null;
  }

  /// Handles hover events when the stylus hovers above the screen.
  void _onPointerHover(PointerHoverEvent event) {
    if (!StylusDetector.isStylus(event)) return;
    final bloc = context.read<CanvasBloc>();
    bloc.add(HoverPositionChanged(event.localPosition));
  }

  // ─── InteractiveViewer zoom callbacks ────────────────────────────────────

  void _onViewerInteractionUpdate(ScaleUpdateDetails details) {
    if (details.scale != _lastScale) {
      _interactionEngine.onZoomChange(
        details.scale,
        details.localFocalPoint,
      );
      _lastScale = details.scale;
    }
  }

  void _onViewerInteractionEnd(ScaleEndDetails details) {
    _interactionEngine.onZoomEnd();
    _lastScale = 1.0;
  }

  // ─── BLoC state listener: detect undo/redo/tool switch ───────────────────

  void _onBlocStateChange(BuildContext context, CanvasState state) {
    final strokeCount = state.strokes.length;
    final redoCount = state.redoStack.length;

    // Detect undo (strokes decreased, redo stack grew)
    if (strokeCount < _prevStrokeCount && redoCount > _prevRedoCount) {
      _interactionEngine.onUndo();
    }
    // Detect redo (strokes grew, redo stack shrank)
    else if (strokeCount > _prevStrokeCount && redoCount < _prevRedoCount) {
      _interactionEngine.onRedo();
    }

    // Detect tool switch
    if (state.activeToolId != _prevToolId && _prevToolId.isNotEmpty) {
      _interactionEngine.onToolSwitch(
        Offset.zero, // cursor not available here; effects fall back gracefully
        fromColor: state.activeColor,
        toColor: state.activeColor,
      );
    }

    _prevStrokeCount = strokeCount;
    _prevRedoCount = redoCount;
    _prevToolId = state.activeToolId;
  }

  /// Converts a [StylusInput] to a [PointData], calculating velocity from the
  /// previous point if available.
  ///
  /// Applies the user's selected pressure curve, pressure sensitivity scaling,
  /// and light temporal smoothing to reduce stylus jitter.
  PointData _stylusInputToPointData(StylusInput input, PointData? previous) {
    double velocity = 0.0;
    if (previous != null) {
      final dt = (input.timestamp - previous.timestamp).abs();
      if (dt > 0) {
        final dx = input.position.dx - previous.x;
        final dy = input.position.dy - previous.y;
        velocity = (dx * dx + dy * dy) / dt;
      }
    }

    // ── Pressure pipeline ────────────────────────────────────────────────
    // 1. Map raw pressure through the user's Bézier pressure curve.
    final curve = _settingsService.activePressureCurve;
    double pressure = curve.apply(input.pressure.clamp(0.0, 1.0));

    // 2. Scale pressure range by pressureSensitivity.
    //    sensitivity = 1.0 → full range; 0.0 → constant 0.5 (no variation).
    final bloc = context.read<CanvasBloc>();
    final sensitivity = bloc.state.activeToolSettings.pressureSensitivity;
    pressure = 0.5 + (pressure - 0.5) * sensitivity;

    // 3. Temporal smoothing — exponential moving average on pressure to
    //    eliminate high-frequency stylus jitter.
    if (previous != null) {
      pressure = previous.pressure * _pressureSmoothingFactor +
          pressure * (1.0 - _pressureSmoothingFactor);
    }

    pressure = pressure.clamp(0.0, 1.0);

    return PointData(
      x: input.position.dx,
      y: input.position.dy,
      pressure: pressure,
      tilt: input.altitude,
      velocity: velocity,
      timestamp: input.timestamp,
      azimuth: input.azimuth,
      altitude: input.altitude,
      hoverDistance: input.hoverDistance,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CanvasBloc, CanvasState>(
        listenWhen: (prev, curr) =>
            prev.strokes.length != curr.strokes.length ||
            prev.redoStack.length != curr.redoStack.length ||
            prev.activeToolId != curr.activeToolId,
        listener: _onBlocStateChange,
        buildWhen: (prev, curr) =>
            prev.strokes != curr.strokes ||
            prev.activeStroke != curr.activeStroke ||
            prev.config != curr.config ||
            prev.activeToolId != curr.activeToolId ||
            prev.activeToolSettings != curr.activeToolSettings ||
            prev.shapes != curr.shapes ||
            prev.shapeRecognitionProposal != curr.shapeRecognitionProposal ||
            prev.selectedShapeId != curr.selectedShapeId ||
            prev.isHovering != curr.isHovering ||
            prev.hoverPosition != curr.hoverPosition,
        builder: (context, state) {
          final canvasSize = Size(state.config.width, state.config.height);
          _canvasEngine.updateStrokesCache(state.strokes, canvasSize);

          return BlocBuilder<StickerBloc, StickerState>(
            builder: (context, stickerState) {
              // Read text blocks from HandwritingBloc if available.
              List<TextBlock> textBlocks = const [];
              try {
                textBlocks =
                    context.watch<HandwritingBloc>().state.textBlocks;
              } on Exception {
                // HandwritingBloc not yet in tree — render without text blocks.
              }

              return Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.3,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(200),
                    onInteractionUpdate: _onViewerInteractionUpdate,
                    onInteractionEnd: _onViewerInteractionEnd,
                    child: SizedBox(
                      width: state.config.width,
                      height: state.config.height,
                      child: StickerInteractionHandler(
                        child: Stack(
                          children: [
                            // Layer 1: Page background
                            PageBackground(config: state.config),
                            // Layers 2–8: Canvas painter
                            // (strokes + shapes + stickers + effects + text blocks + interaction)
                            Listener(
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              onPointerCancel: _onPointerCancel,
                              onPointerHover: _onPointerHover,
                              child: CustomPaint(
                                painter: _CanvasPainter(
                                  engine: _canvasEngine,
                                  strokes: state.strokes,
                                  activeStroke: state.activeStroke,
                                  activeToolSettings: state.activeToolSettings,
                                  config: state.config,
                                  shapes: state.shapes,
                                  stickers: stickerState.sortedByZIndex,
                                  selectedStickerId:
                                      stickerState.selectedStickerId,
                                  textBlocks: textBlocks,
                                ),
                                size: canvasSize,
                              ),
                            ),
                            // Shape selection handles overlay
                            if (state.selectedShapeId != null)
                              BlocBuilder<ShapeBloc, ShapeState>(
                                buildWhen: (p, c) =>
                                    p.selectedShapeId != c.selectedShapeId,
                                builder: (ctx, shapeState) {
                                  final selectedId = state.selectedShapeId;
                                  if (selectedId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final sel = state.shapes
                                      .where((s) => s.id == selectedId)
                                      .firstOrNull;
                                  if (sel == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return ShapeHandles(
                                    shape: sel,
                                    onDeleteTap: () {
                                      ctx.read<CanvasBloc>().add(
                                          ShapeDeleted(sel.id));
                                      ctx.read<ShapeBloc>().add(
                                          const ShapeDeselectedEvent());
                                    },
                                  );
                                },
                              ),
                            // Snap guides overlay
                            BlocBuilder<ShapeBloc, ShapeState>(
                              buildWhen: (p, c) =>
                                  p.snapGuides != c.snapGuides,
                              builder: (_, shapeState) => SnapGuidesOverlay(
                                guides: shapeState.snapGuides,
                              ),
                            ),
                            // Layer 7: Remote cursors (collaboration)
                            BlocBuilder<CollaborationBloc, CollaborationState>(
                              builder: (_, collabState) => RemoteCursors(
                                participants: collabState.participants,
                              ),
                            ),
                            // Hover cursor — inside canvas coordinate space
                            if (state.isHovering && state.hoverPosition != null)
                              HoverCursor(
                                position: state.hoverPosition!,
                                brushSize: state.activeWidth.clamp(8.0, 60.0),
                                color: state.activeColor,
                                isEraser: state.activeTool.type ==
                                    StrokeTool.eraser,
                                isVisible: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Shape recognition confirmation banner
                  if (state.shapeRecognitionProposal != null)
                    _ShapeRecognitionBanner(
                      proposal: state.shapeRecognitionProposal!.type.name,
                      confidence: state.shapeRecognitionProposal!.confidence,
                      onAccept: () => context
                          .read<CanvasBloc>()
                          .add(const ShapeRecognitionAccepted()),
                      onReject: () => context
                          .read<CanvasBloc>()
                          .add(const ShapeRecognitionRejected()),
                    ),
                  // Shape properties panel — shown at bottom when a shape is
                  // selected so the user can adjust colours, fill, etc.
                  if (state.selectedShapeId != null)
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ShapePropertiesPanel(),
                    ),
                  // Offline / reconnecting banner (collaboration)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: OfflineIndicator(),
                  ),
                ],
              );
            },
          );
        },
      );
}

/// [CustomPainter] that delegates all rendering to the [CanvasEngine].
class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.engine,
    required this.strokes,
    required this.activeStroke,
    required this.activeToolSettings,
    required this.config,
    required this.shapes,
    required this.stickers,
    this.selectedStickerId,
    this.textBlocks = const [],
  });

  final CanvasEngine engine;
  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final ToolSettings activeToolSettings;
  final CanvasConfig config;
  final List<ShapeElement> shapes;
  final List<StickerElement> stickers;
  final String? selectedStickerId;
  final List<TextBlock> textBlocks;

  @override
  void paint(Canvas canvas, Size size) {
    engine.paint(
      canvas: canvas,
      size: size,
      config: config,
      strokes: strokes,
      activeStroke: activeStroke,
      activeToolSettings: activeToolSettings,
      shapes: shapes,
      stickers: stickers,
      selectedStickerId: selectedStickerId,
      textBlocks: textBlocks,
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes != strokes ||
      old.activeStroke != activeStroke ||
      old.activeToolSettings != activeToolSettings ||
      old.config != config ||
      old.shapes != shapes ||
      old.stickers != stickers ||
      old.selectedStickerId != selectedStickerId ||
      old.textBlocks != textBlocks;
}

/// Brief overlay that asks the user to confirm a shape recognition result.
class _ShapeRecognitionBanner extends StatelessWidget {
  const _ShapeRecognitionBanner({
    required this.proposal,
    required this.confidence,
    required this.onAccept,
    required this.onReject,
  });

  final String proposal;
  final double confidence;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_fix_high,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Did you mean ${_capitalize(proposal)}?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onAccept,
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onReject,
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
