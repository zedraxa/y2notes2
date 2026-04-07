import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/engine/canvas_engine.dart';
import 'package:y2notes2/core/extensions/iterable_extensions.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/page_background.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/offline_indicator.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/remote_cursors.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_bloc.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_event.dart';
import 'package:y2notes2/features/shapes/presentation/bloc/shape_state.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/shape_handles.dart';
import 'package:y2notes2/features/shapes/presentation/widgets/snap_guides_overlay.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:y2notes2/features/stickers/presentation/bloc/sticker_state.dart';
import 'package:y2notes2/features/stickers/presentation/widgets/sticker_interaction_handler.dart';

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
  late final CanvasEngine _canvasEngine;
  late final TransformationController _transformController;
  PointData? _lastPoint;

  @override
  void initState() {
    super.initState();
    _effectsEngine = WritingEffectsEngine();
    _canvasEngine = CanvasEngine(vsync: this, effectsEngine: _effectsEngine);
    _transformController = TransformationController();

    // Rebuild the canvas view on each animation frame
    _canvasEngine.addListener(_onEngineUpdate);
  }

  @override
  void dispose() {
    _canvasEngine
      ..removeListener(_onEngineUpdate)
      ..dispose();
    _effectsEngine.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  // ─── Pointer event handlers ───────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    final bloc = context.read<CanvasBloc>();
    final point = _eventToPointData(event, null);
    _lastPoint = point;
    bloc.add(StrokeStarted(point));

    // Notify effects engine
    final state = bloc.state;
    if (state.effectsEnabled) {
      _effectsEngine.onStrokeStart(point);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final bloc = context.read<CanvasBloc>();
    final prev = _lastPoint;
    final point = _eventToPointData(event, prev);
    _lastPoint = point;
    bloc.add(StrokeUpdated(point));

    final state = bloc.state;
    if (state.effectsEnabled && state.activeStroke != null) {
      _effectsEngine.onStrokePoint(point, prev, state.activeStroke!);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final bloc = context.read<CanvasBloc>();
    // Capture active stroke BEFORE adding StrokeEnded (which clears it)
    final activeStroke = bloc.state.activeStroke;
    final effectsEnabled = bloc.state.effectsEnabled;
    bloc.add(const StrokeEnded());
    if (effectsEnabled && activeStroke != null) {
      _effectsEngine.onStrokeEnd(activeStroke);
    }
    _lastPoint = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    context.read<CanvasBloc>().add(const StrokeEnded());
    _lastPoint = null;
  }

  PointData _eventToPointData(PointerEvent event, PointData? previous) {
    double velocity = 0.0;
    if (previous != null) {
      final dt =
          (event.timeStamp.inMilliseconds - previous.timestamp).abs();
      if (dt > 0) {
        final dx = event.localPosition.dx - previous.x;
        final dy = event.localPosition.dy - previous.y;
        final dist = (dx * dx + dy * dy);
        velocity = dist / dt;
      }
    }

    return PointData(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure.clamp(0.0, 1.0),
      tilt: event.tilt,
      velocity: velocity,
      timestamp: event.timeStamp.inMilliseconds,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasBloc, CanvasState>(
        buildWhen: (prev, curr) =>
            prev.strokes != curr.strokes ||
            prev.activeStroke != curr.activeStroke ||
            prev.config != curr.config ||
            prev.activeToolId != curr.activeToolId ||
            prev.activeToolSettings != curr.activeToolSettings ||
            prev.shapes != curr.shapes ||
            prev.shapeRecognitionProposal != curr.shapeRecognitionProposal ||
            prev.selectedShapeId != curr.selectedShapeId,
        builder: (context, state) {
          final canvasSize = Size(state.config.width, state.config.height);
          _canvasEngine.updateStrokesCache(state.strokes, canvasSize);

          return BlocBuilder<StickerBloc, StickerState>(
            builder: (context, stickerState) {
              return Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.3,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: SizedBox(
                      width: state.config.width,
                      height: state.config.height,
                      child: StickerInteractionHandler(
                        child: Stack(
                          children: [
                            // Layer 1: Page background
                            PageBackground(config: state.config),
                            // Layers 2–8: Canvas painter (strokes + shapes + stickers + effects)
                            Listener(
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              onPointerCancel: _onPointerCancel,
                              child: CustomPaint(
                                painter: _CanvasPainter(
                                  engine: _canvasEngine,
                                  strokes: state.strokes,
                                  activeStroke: state.activeStroke,
                                  activeToolSettings: state.activeToolSettings,
                                  config: state.config,
                                  shapes: state.shapes,
                                  stickers: stickerState.sortedByZIndex,
                                  selectedStickerId: stickerState.selectedStickerId,
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
                                  if (sel == null) return const SizedBox.shrink();
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
                              buildWhen: (p, c) => p.snapGuides != c.snapGuides,
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
  });

  final CanvasEngine engine;
  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final ToolSettings activeToolSettings;
  final CanvasConfig config;
  final List<ShapeElement> shapes;
  final List<StickerElement> stickers;
  final String? selectedStickerId;

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
      old.selectedStickerId != selectedStickerId;
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
