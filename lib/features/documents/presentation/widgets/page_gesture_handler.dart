import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Width (in logical pixels) of the tap-to-navigate zone at each edge.
  ///
  /// Single-tap anywhere within this zone (left or right) triggers page
  /// navigation without requiring a swipe gesture.
  static const double _tapZoneWidth = 48.0;

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

  // ── Tap-zone tracking ─────────────────────────────────────────────────────

  /// Whether the current single-pointer down is in a tap zone and hasn't
  /// moved beyond [_minSwipeDistance] yet.
  bool _tapZoneDown = false;

  /// The side (left / right) of the tap-zone touch. `true` = left zone.
  bool _tapZoneIsLeft = false;

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
      _triggerPageTurnHaptic();
    } else if (_dragProgress > 0 && state.canGoForward) {
      bloc.add(const GoToNextPage());
      _triggerPageTurnHaptic();
    }
  }

  /// Fire a light haptic impact when a page turn is committed, if enabled.
  void _triggerPageTurnHaptic() {
    try {
      final settings = ServiceProvider.of<SettingsService>(context);
      if (settings.pageGestureHapticsEnabledNotifier.value) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      HapticFeedback.lightImpact();
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

    // Start edge swipe / tap-zone detection when touch begins in the edge zone.
    if (_activePointers.length == 1 && !_twoFingerGestureActive) {
      final widgetWidth = context.size?.width ?? 0;
      if (widgetWidth > 0) {
        final x = event.localPosition.dx;
        final inLeft = x <= math.max(_edgeMargin, _tapZoneWidth);
        final inRight = x >= widgetWidth - math.max(_edgeMargin, _tapZoneWidth);
        if (inLeft || inRight) {
          _edgeSwipeActive = true;
          _edgeDx = 0.0;
          _edgeDy = 0.0;
          _edgeStartX = x;
          _edgeLastMoveTime = DateTime.now();
          _edgeLastMoveDx = 0.0;

          // Track potential tap in the tap zone (slightly wider than swipe zone).
          _tapZoneDown = x <= _tapZoneWidth || x >= widgetWidth - _tapZoneWidth;
          _tapZoneIsLeft = x <= _tapZoneWidth;
        }
      }
    }

    // Activate two-finger tracking when a second pointer arrives.
    if (_activePointers.length == 2) {
      _twoFingerGestureActive = true;
      _edgeSwipeActive = false; // cancel edge swipe if upgrading to two-finger
      _tapZoneDown = false;
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

      // Cancel tap-zone detection once the user starts swiping.
      if (_edgeDx.abs() > _minSwipeDistance || _edgeDy.abs() > _minSwipeDistance) {
        _tapZoneDown = false;
      }

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

    // Tap-zone: single-tap with minimal movement navigates immediately.
    if (_tapZoneDown && _activePointers.isEmpty) {
      _tapZoneDown = false;
      _edgeSwipeActive = false;
      final bloc = context.read<DocumentBloc>();
      final state = bloc.state;
      if (_tapZoneIsLeft && state.canGoBack) {
        bloc.add(const GoToPreviousPage());
        _triggerPageTurnHaptic();
      } else if (!_tapZoneIsLeft && state.canGoForward) {
        bloc.add(const GoToNextPage());
        _triggerPageTurnHaptic();
      }
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
    _tapZoneDown = false;
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
          prev.canGoForward != curr.canGoForward ||
          prev.currentPageIndex != curr.currentPageIndex ||
          prev.pageCount != curr.pageCount,
      builder: (context, state) {
        final isDragging = _dragProgress.abs() > 0.05;
        // The page we'd land on if the current drag commits.
        final targetPageIndex = _dragProgress < 0
            ? state.currentPageIndex - 1
            : state.currentPageIndex + 1;

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
              // Live page-number indicator during a drag.
              if (isDragging && state.pageCount > 1)
                _PageNumberIndicator(
                  currentPage: state.currentPageIndex + 1,
                  targetPage: targetPageIndex.clamp(1, state.pageCount),
                  totalPages: state.pageCount,
                  progress: _dragProgress.abs(),
                  direction: _dragProgress < 0 ? -1 : 1,
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

// ── Page number indicator ─────────────────────────────────────────────────────

/// A pill indicator shown in the centre-bottom of the canvas during a drag
/// that shows both the current and target page numbers.
class _PageNumberIndicator extends StatelessWidget {
  const _PageNumberIndicator({
    required this.currentPage,
    required this.targetPage,
    required this.totalPages,
    required this.progress,
    required this.direction,
  });

  final int currentPage;
  final int targetPage;
  final int totalPages;

  /// 0.0–1.0; used for opacity fade-in.
  final double progress;

  /// -1 = going to previous page, +1 = going to next page.
  final int direction;

  @override
  Widget build(BuildContext context) {
    final opacity = (progress * 2.0).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 80),
          opacity: opacity,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (direction < 0) ...[
                    Icon(
                      Icons.chevron_left,
                      size: 16,
                      color: theme.colorScheme.onInverseSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    '$targetPage / $totalPages',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (direction > 0) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.onInverseSurface.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
