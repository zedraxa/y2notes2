import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_state.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

/// Detects two-finger horizontal swipe gestures to navigate between notebook
/// pages.
///
/// The handler distinguishes between page-navigation swipes (fast, primarily
/// horizontal, two-finger) and pinch-zoom / pan gestures by checking:
///   1. The number of active pointers is exactly two.
///   2. Cumulative horizontal displacement exceeds the threshold.
///   3. The movement is primarily horizontal (angle check).
///   4. Velocity at the end of the gesture exceeds the minimum.
///
/// Edge swipes (starting within [_edgeMargin] pixels of the left/right edge)
/// are also supported using a single finger.
///
/// Visual feedback is provided via an animated edge indicator (shadow + page
/// peek) while the gesture is in progress.
class PageGestureHandler extends StatefulWidget {
  const PageGestureHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<PageGestureHandler> createState() => _PageGestureHandlerState();
}

class _PageGestureHandlerState extends State<PageGestureHandler>
    with SingleTickerProviderStateMixin {
  // ── Configuration ─────────────────────────────────────────────────────────

  /// Width (in logical pixels) of the edge-swipe hit zone.
  static const double _edgeMargin = 28.0;

  /// Minimum horizontal displacement to commit a page change.
  static const double _commitThreshold = 80.0;

  /// Minimum fling velocity (logical pixels / second) for a quick-swipe commit.
  static const double _flingVelocity = 300.0;

  /// Maximum ratio of |dy| / |dx| allowed for a horizontal swipe.
  static const double _maxAngleRatio = 0.6;

  /// Minimum absolute horizontal displacement before visual feedback starts.
  static const double _minDragThreshold = 4.0;

  /// Minimum horizontal displacement to classify a swipe (vs. a tap/noise).
  static const double _minSwipeDistance = 10.0;

  // ── Multi-touch tracking ──────────────────────────────────────────────────

  /// Pointer IDs currently touching the screen.
  final Set<int> _activePointers = {};

  /// Set once exactly two pointers are down simultaneously.
  bool _twoFingerGestureActive = false;

  /// Cumulative horizontal translation while two fingers are down.
  double _twoFingerDx = 0.0;

  /// Cumulative vertical translation while two fingers are down.
  double _twoFingerDy = 0.0;

  /// Timestamp of the most recent pointer-move in the two-finger gesture.
  DateTime? _lastMoveTime;

  /// Horizontal position at [_lastMoveTime], used for velocity estimation.
  double _lastMoveDx = 0.0;

  // ── Edge-swipe tracking ───────────────────────────────────────────────────

  bool _edgeSwipeActive = false;
  double _edgeDx = 0.0;
  double _edgeDy = 0.0;
  double _edgeStartX = 0.0;
  DateTime? _edgeLastMoveTime;
  double _edgeLastMoveDx = 0.0;

  // ── Visual feedback ───────────────────────────────────────────────────────

  /// Normalised drag progress in the range [-1, 1].
  ///   – negative → swiping right (go to previous page)
  ///   – positive → swiping left (go to next page)
  double _dragProgress = 0.0;

  /// Runs the spring-back / commit animation when the gesture ends.
  late final AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        setState(() {
          _dragProgress = _progressAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _enabled {
    try {
      return ServiceProvider.of<SettingsService>(context)
          .pageGesturesEnabledNotifier
          .value;
    } catch (_) {
      return true;
    }
  }

  double _velocityEstimate(
    DateTime? lastTime,
    double lastDx,
    double currentDx,
  ) {
    if (lastTime == null) return 0.0;
    final elapsed =
        DateTime.now().difference(lastTime).inMilliseconds.toDouble();
    if (elapsed <= 0) return 0.0;
    return ((currentDx - lastDx) / elapsed) * 1000.0; // px / s
  }

  void _commitNavigation(DocumentBloc bloc, DocumentState state) {
    if (_dragProgress < 0 && state.canGoBack) {
      bloc.add(const GoToPreviousPage());
    } else if (_dragProgress > 0 && state.canGoForward) {
      bloc.add(const GoToNextPage());
    }
  }

  void _animateBack() {
    _progressAnimation = Tween<double>(
      begin: _dragProgress,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward(from: 0.0);
  }

  void _animateCommit(double targetProgress) {
    _progressAnimation = Tween<double>(
      begin: _dragProgress,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController
      ..forward(from: 0.0)
      ..addStatusListener(_onCommitAnimationDone);
  }

  void _onCommitAnimationDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animController.removeStatusListener(_onCommitAnimationDone);
      final bloc = context.read<DocumentBloc>();
      _commitNavigation(bloc, bloc.state);
      // Reset visual state after navigation.
      setState(() => _dragProgress = 0.0);
    }
  }

  // ── Two-finger gesture callbacks ──────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    if (!_enabled) return;

    _activePointers.add(event.pointer);

    // Start edge swipe when touch begins in the edge zone.
    if (_activePointers.length == 1 && !_twoFingerGestureActive) {
      final widgetWidth = context.size?.width ?? 0;
      if (widgetWidth > 0 &&
          (event.localPosition.dx <= _edgeMargin ||
           event.localPosition.dx >= widgetWidth - _edgeMargin)) {
        _edgeSwipeActive = true;
        _edgeDx = 0.0;
        _edgeDy = 0.0;
        _edgeStartX = event.localPosition.dx;
        _edgeLastMoveTime = DateTime.now();
        _edgeLastMoveDx = 0.0;
      }
    }

    // Activate two-finger tracking when a second pointer arrives.
    if (_activePointers.length == 2) {
      _twoFingerGestureActive = true;
      _edgeSwipeActive = false; // cancel edge swipe if upgrading to two-finger
      _twoFingerDx = 0.0;
      _twoFingerDy = 0.0;
      _lastMoveTime = DateTime.now();
      _lastMoveDx = 0.0;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_enabled) return;

    // Two-finger mode takes priority.
    if (_twoFingerGestureActive && _activePointers.length >= 2) {
      _twoFingerDx += event.delta.dx;
      _twoFingerDy += event.delta.dy;
      _lastMoveTime = DateTime.now();
      _lastMoveDx = _twoFingerDx;

      _updateDragProgress(_twoFingerDx, _twoFingerDy);
      return;
    }

    if (_edgeSwipeActive && _activePointers.length == 1) {
      _edgeDx += event.delta.dx;
      _edgeDy += event.delta.dy;
      _edgeLastMoveTime = DateTime.now();
      _edgeLastMoveDx = _edgeDx;

      _updateDragProgress(_edgeDx, _edgeDy);
    }
  }

  void _updateDragProgress(double dx, double dy) {
    // Only update visual feedback if horizontal movement dominates.
    if (dx.abs() < _minDragThreshold) return;
    if (dy.abs() / dx.abs() > _maxAngleRatio) return;

    final state = context.read<DocumentBloc>().state;
    // Prevent dragging into an impossible direction.
    if (dx > 0 && !state.canGoBack) return; // swiping right but no prev page
    if (dx < 0 && !state.canGoForward) return; // swiping left but no next page

    // Map displacement to progress.
    // Negative dx = swipe left = next page = positive progress.
    final raw = -dx / _commitThreshold;
    setState(() {
      _dragProgress = raw.clamp(-1.0, 1.0);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _tryEndGesture();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _tryEndGesture();
  }

  void _tryEndGesture() {
    if (!_enabled) {
      _resetGestureState();
      return;
    }

    // For two-finger gesture, wait until all pointers are lifted.
    if (_twoFingerGestureActive && _activePointers.isNotEmpty) return;

    if (_twoFingerGestureActive) {
      _endSwipe(
        _twoFingerDx,
        _twoFingerDy,
        _velocityEstimate(_lastMoveTime, _lastMoveDx, _twoFingerDx),
      );
      _twoFingerGestureActive = false;
      return;
    }

    if (_edgeSwipeActive && _activePointers.isEmpty) {
      _endSwipe(
        _edgeDx,
        _edgeDy,
        _velocityEstimate(_edgeLastMoveTime, _edgeLastMoveDx, _edgeDx),
      );
      _edgeSwipeActive = false;
    }
  }

  void _endSwipe(double dx, double dy, double velocity) {
    final absDx = dx.abs();
    final absDy = dy.abs();

    // Not a horizontal swipe – spring back.
    if (absDx < _minSwipeDistance ||
        (absDy / math.max(absDx, 1.0)) > _maxAngleRatio) {
      _animateBack();
      return;
    }

    final absVelocity = velocity.abs();
    final committed =
        absDx >= _commitThreshold || absVelocity >= _flingVelocity;

    if (committed) {
      final target = _dragProgress > 0 ? 1.0 : -1.0;
      _animateCommit(target);
    } else {
      _animateBack();
    }
  }

  void _resetGestureState() {
    _activePointers.clear();
    _twoFingerGestureActive = false;
    _edgeSwipeActive = false;
    _twoFingerDx = 0.0;
    _twoFingerDy = 0.0;
    _edgeDx = 0.0;
    _edgeDy = 0.0;
    if (_dragProgress != 0.0) {
      _animateBack();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentBloc, DocumentState>(
      buildWhen: (prev, curr) =>
          prev.canGoBack != curr.canGoBack ||
          prev.canGoForward != curr.canGoForward,
      builder: (context, state) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Stack(
            children: [
              widget.child,
              // Left edge indicator (swipe to go to previous page).
              if (_dragProgress < 0 && state.canGoBack)
                _PageEdgeIndicator(
                  alignment: Alignment.centerLeft,
                  progress: -_dragProgress,
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous',
                ),
              // Right edge indicator (swipe to go to next page).
              if (_dragProgress > 0 && state.canGoForward)
                _PageEdgeIndicator(
                  alignment: Alignment.centerRight,
                  progress: _dragProgress,
                  icon: Icons.chevron_right_rounded,
                  label: 'Next',
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Edge indicator widget ─────────────────────────────────────────────────────

/// A subtle, animated indicator shown at the left or right edge of the canvas
/// when the user is mid-swipe.
class _PageEdgeIndicator extends StatelessWidget {
  const _PageEdgeIndicator({
    required this.alignment,
    required this.progress,
    required this.icon,
    required this.label,
  });

  /// [Alignment.centerLeft] or [Alignment.centerRight].
  final Alignment alignment;

  /// 0.0 → just started, 1.0 → fully committed.
  final double progress;

  final IconData icon;
  final String label;

  /// Minimum progress before the icon/label become visible.
  static const double _iconVisibilityThreshold = 0.4;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    // Width of the indicator grows as the user drags.
    final width = 48.0 * progress.clamp(0.0, 1.0);
    final opacity = (progress * 1.5).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: opacity,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.0),
                  theme.colorScheme.primary.withOpacity(0.12),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: progress >= _iconVisibilityThreshold
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: theme.colorScheme.primary.withOpacity(opacity),
                        size: 24,
                        semanticLabel: label,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.primary.withOpacity(opacity),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
