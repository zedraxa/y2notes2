import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:y2notes2/core/engine/effects_compositor.dart';
import 'package:y2notes2/core/engine/render_pipeline.dart';
import 'package:y2notes2/core/engine/stroke_renderer.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_settings.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/effects/interaction/interaction_effects_engine.dart';
import 'package:y2notes2/features/effects/writing/writing_effects_engine.dart';
import 'package:y2notes2/features/handwriting/domain/entities/text_block.dart';
import 'package:y2notes2/features/shapes/domain/entities/shape_element.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';

/// Core rendering loop and coordination hub for the canvas.
///
/// Owns the [Ticker] that drives effect animations, the [RenderPipeline] for
/// bitmap caching, and the [EffectsCompositor] for layer ordering.
class CanvasEngine with ChangeNotifier {
  CanvasEngine({
    required TickerProvider vsync,
    required this.effectsEngine,
    this.interactionEngine,
  }) {
    _renderer = StrokeRenderer();
    _pipeline = RenderPipeline(renderer: _renderer);
    _compositor = EffectsCompositor(
      strokeRenderer: _renderer,
      effectsEngine: effectsEngine,
      interactionEngine: interactionEngine,
    );
    _ticker = vsync.createTicker(_onTick)..start();
  }

  final WritingEffectsEngine effectsEngine;

  /// Optional interaction effects engine — updated every tick.
  final InteractionEffectsEngine? interactionEngine;

  late final StrokeRenderer _renderer;
  late final RenderPipeline _pipeline;
  late final EffectsCompositor _compositor;
  late final Ticker _ticker;

  Duration _lastTickTime = Duration.zero;
  ui.Image? _strokesCache;

  // ─── Public API ───────────────────────────────────────────────────────────

  StrokeRenderer get renderer => _renderer;
  EffectsCompositor get compositor => _compositor;

  /// Called each animation frame.
  void _onTick(Duration elapsed) {
    final dt = _lastTickTime == Duration.zero
        ? 0.0
        : (elapsed - _lastTickTime).inMicroseconds / 1e6;
    _lastTickTime = elapsed;
    effectsEngine.update(dt);
    interactionEngine?.update(dt);
    notifyListeners();
  }

  /// Update the rasterized strokes cache.
  Future<void> updateStrokesCache(
    List<Stroke> strokes,
    Size canvasSize,
  ) async {
    _strokesCache = await _pipeline.getStrokesCache(strokes, canvasSize);
    notifyListeners();
  }

  /// Invalidate the raster cache (call on undo/redo/clear).
  void invalidateCache() => _pipeline.invalidateCache();

  /// Paint all layers onto [canvas].
  void paint({
    required Canvas canvas,
    required Size size,
    required CanvasConfig config,
    required List<Stroke> strokes,
    required Stroke? activeStroke,
    ToolSettings? activeToolSettings,
    List<ShapeElement> shapes = const [],
    List<StickerElement> stickers = const [],
    String? selectedStickerId,
    List<TextBlock> textBlocks = const [],
  }) {
    _compositor.compose(
      canvas: canvas,
      size: size,
      config: config,
      strokes: strokes,
      activeStroke: activeStroke,
      strokesCache: _strokesCache,
      activeToolSettings: activeToolSettings,
      shapes: shapes,
      stickers: stickers,
      selectedStickerId: selectedStickerId,
      textBlocks: textBlocks,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pipeline.dispose();
    super.dispose();
  }
}
