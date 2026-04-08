import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';

/// Helper widgets for creating Apple-style animations and transitions.
///
/// These provide reusable animation patterns that match iOS/macOS motion design:
/// - Spring-based transitions
/// - Smooth fade and scale combinations
/// - Physics-driven interactions
library;

/// Animated container that scales and fades content with Apple-style spring.
///
/// Perfect for:
/// - Button press feedback
/// - Toggle state changes
/// - Item selection
class SpringContainer extends StatefulWidget {
  const SpringContainer({
    super.key,
    required this.child,
    this.isPressed = false,
    this.pressedScale = 0.95,
    this.duration = AppleDurations.quick,
    this.curve = AppleCurves.gentleSpring,
  });

  final Widget child;
  final bool isPressed;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  @override
  State<SpringContainer> createState() => _SpringContainerState();
}

class _SpringContainerState extends State<SpringContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(SpringContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPressed != oldWidget.isPressed) {
      if (widget.isPressed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      );
}

/// Animated opacity that fades in/out with Apple timing.
class AppleFade extends StatelessWidget {
  const AppleFade({
    super.key,
    required this.visible,
    required this.child,
    this.duration = AppleDurations.standard,
    this.curve = AppleCurves.standard,
  });

  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: child,
      );
}

/// Combined fade and scale animation (like iOS alerts).
class AppleFadeScale extends StatelessWidget {
  const AppleFadeScale({
    super.key,
    required this.visible,
    required this.child,
    this.duration = AppleDurations.standard,
    this.curve = AppleCurves.gentleSpring,
    this.scaleBegin = 0.8,
  });

  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double scaleBegin;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: visible ? 1.0 : scaleBegin,
        duration: duration,
        curve: curve,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: duration,
          curve: curve,
          child: child,
        ),
      );
}

/// Slide transition with Apple-style curves.
class AppleSlide extends StatelessWidget {
  const AppleSlide({
    super.key,
    required this.visible,
    required this.child,
    this.direction = AxisDirection.up,
    this.duration = AppleDurations.standard,
    this.curve = AppleCurves.decelerate,
    this.distance = 24.0,
  });

  final bool visible;
  final Widget child;
  final AxisDirection direction;
  final Duration duration;
  final Curve curve;
  final double distance;

  @override
  Widget build(BuildContext context) {
    Offset begin;
    switch (direction) {
      case AxisDirection.up:
        begin = Offset(0, distance / 100);
        break;
      case AxisDirection.down:
        begin = Offset(0, -distance / 100);
        break;
      case AxisDirection.left:
        begin = Offset(distance / 100, 0);
        break;
      case AxisDirection.right:
        begin = Offset(-distance / 100, 0);
        break;
    }

    return AnimatedSlide(
      offset: visible ? Offset.zero : begin,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// Hero-style page transition builder.
class ApplePageTransition extends PageRouteBuilder {
  ApplePageTransition({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppleDurations.medium,
          reverseTransitionDuration: AppleDurations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: AppleCurves.decelerate));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Modal presentation transition (from bottom).
class AppleModalTransition extends PageRouteBuilder {
  AppleModalTransition({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppleDurations.medium,
          reverseTransitionDuration: AppleDurations.standard,
          opaque: false,
          barrierColor: Colors.black54,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: AppleCurves.decelerate));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

/// Shimmer loading effect (skeleton screens).
class AppleShimmer extends StatefulWidget {
  const AppleShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<AppleShimmer> createState() => _AppleShimmerState();
}

class _AppleShimmerState extends State<AppleShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              highlightColor,
              baseColor,
            ],
            stops: [
              0.0,
              _controller.value,
              1.0,
            ],
          ).createShader(bounds);
        },
        child: widget.child,
      ),
    );
  }
}
