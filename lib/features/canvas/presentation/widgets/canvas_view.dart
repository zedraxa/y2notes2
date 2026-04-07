import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/core/engine/canvas_engine.dart';
import 'package:y2notes2/features/canvas/domain/entities/point_data.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_bloc.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_event.dart';
import 'package:y2notes2/features/canvas/presentation/bloc/canvas_state.dart';
import 'package:y2notes2/features/canvas/presentation/widgets/page_background.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
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
            prev.activeToolSettings != curr.activeToolSettings,
        builder: (context, canvasState) {
          final canvasSize =
              Size(canvasState.config.width, canvasState.config.height);
          _canvasEngine.updateStrokesCache(canvasState.strokes, canvasSize);

          return BlocBuilder<StickerBloc, StickerState>(
            builder: (context, stickerState) {
              return InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.3,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(200),
                child: SizedBox(
                  width: canvasState.config.width,
                  height: canvasState.config.height,
                  child: StickerInteractionHandler(
                    child: Stack(
                      children: [
                        // Layer 1: Page background
                        PageBackground(config: canvasState.config),
                        // Layers 2–7: Canvas painter (strokes + stickers)
                        Listener(
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: CustomPaint(
                            painter: _CanvasPainter(
                              engine: _canvasEngine,
                              strokes: canvasState.strokes,
                              activeStroke: canvasState.activeStroke,
                              activeToolSettings: canvasState.activeToolSettings,
                              config: canvasState.config,
                              stickers: stickerState.sortedByZIndex,
                              selectedStickerId: stickerState.selectedStickerId,
                            ),
                            size: canvasSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    required this.stickers,
    this.selectedStickerId,
  });

  final CanvasEngine engine;
  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final ToolSettings activeToolSettings;
  final CanvasConfig config;
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
      old.stickers != stickers ||
      old.selectedStickerId != selectedStickerId;
}
