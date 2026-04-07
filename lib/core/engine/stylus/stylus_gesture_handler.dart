import 'package:y2notes2/core/engine/stylus/stylus_adapter.dart';
import 'package:y2notes2/core/engine/stylus/stylus_detector.dart';

/// Maps hardware stylus gestures to configurable app actions.
///
/// Every gesture→action mapping is configurable by the user and persisted in
/// [SettingsService].  If a gesture is not supported on the current device, it
/// silently no-ops.
///
/// Supported gestures and their default actions:
///
/// | Gesture           | Supported by          | Default action          |
/// |-------------------|-----------------------|-------------------------|
/// | Barrel double-tap | Apple Pencil 2 / Pro  | Switch to eraser        |
/// | Barrel button     | S Pen / Wacom         | Toggle eraser           |
/// | Squeeze           | Apple Pencil Pro      | Show tool picker        |
/// | Hover enter       | Apple Pencil Pro / S Pen | Show brush preview   |
/// | Barrel button 2   | Wacom                 | Undo                    |
/// | Air gesture       | S Pen                 | Configurable            |
enum StylusGesture {
  /// Apple Pencil 2+ barrel double-tap.
  barrelDoubleTap,

  /// S Pen / Wacom primary barrel button press.
  barrelButton,

  /// Apple Pencil Pro squeeze gesture.
  squeeze,

  /// Pen entering hover range above the screen.
  hoverEnter,

  /// Pen leaving hover range.
  hoverExit,

  /// Wacom / S Pen secondary barrel button.
  barrelButton2,

  /// S Pen Air Action remote gesture (wave, flick — stub).
  airGesture,
}

/// Actions that stylus gestures can be mapped to.
enum StylusGestureAction {
  /// No operation — gesture is ignored.
  none,

  /// Switch the active tool to the eraser.
  switchToEraser,

  /// Toggle between eraser and the previously-active tool.
  toggleEraser,

  /// Switch to the tool that was active before eraser was engaged.
  switchToLastTool,

  /// Open the tool-picker popup.
  showToolPicker,

  /// Open the colour picker.
  showColorPicker,

  /// Undo the last stroke.
  undo,

  /// Redo the last undone stroke.
  redo,

  /// Show / hide the effects panel.
  toggleEffects,

  /// User-configured custom action (future extension point).
  custom,
}

/// Handles the mapping from [StylusGesture] to [StylusGestureAction] and
/// exposes a callback-based API for the canvas to subscribe to gesture events.
///
/// Usage:
/// ```dart
/// final handler = StylusGestureHandler()
///   ..setMapping(StylusGesture.barrelDoubleTap, StylusGestureAction.switchToEraser)
///   ..onGesture = (action) { /* handle */ };
///
/// // In your platform-channel listener:
/// handler.handle(StylusGesture.barrelDoubleTap, input);
/// ```
class StylusGestureHandler {
  /// Called whenever a gesture fires. The [StylusGestureAction] is the
  /// resolved action for that gesture, and [input] carries the pointer data.
  void Function(StylusGestureAction action, StylusInput input)? onGesture;

  final Map<StylusGesture, StylusGestureAction> _mappings = {
    StylusGesture.barrelDoubleTap: StylusGestureAction.switchToEraser,
    StylusGesture.barrelButton: StylusGestureAction.toggleEraser,
    StylusGesture.squeeze: StylusGestureAction.showToolPicker,
    StylusGesture.hoverEnter: StylusGestureAction.none,
    StylusGesture.hoverExit: StylusGestureAction.none,
    StylusGesture.barrelButton2: StylusGestureAction.undo,
    StylusGesture.airGesture: StylusGestureAction.none,
  };

  // ─── Configuration ────────────────────────────────────────────────────────

  /// Returns the current action mapping for [gesture].
  StylusGestureAction getAction(StylusGesture gesture) =>
      _mappings[gesture] ?? StylusGestureAction.none;

  /// Sets the action to perform when [gesture] fires.
  void setMapping(StylusGesture gesture, StylusGestureAction action) {
    _mappings[gesture] = action;
  }

  /// Resets all mappings to their defaults.
  void resetToDefaults() {
    _mappings
      ..[StylusGesture.barrelDoubleTap] = StylusGestureAction.switchToEraser
      ..[StylusGesture.barrelButton] = StylusGestureAction.toggleEraser
      ..[StylusGesture.squeeze] = StylusGestureAction.showToolPicker
      ..[StylusGesture.hoverEnter] = StylusGestureAction.none
      ..[StylusGesture.hoverExit] = StylusGestureAction.none
      ..[StylusGesture.barrelButton2] = StylusGestureAction.undo
      ..[StylusGesture.airGesture] = StylusGestureAction.none;
  }

  // ─── Event dispatch ───────────────────────────────────────────────────────

  /// Processes [gesture] for [input] and fires [onGesture] if the resolved
  /// action is not [StylusGestureAction.none].
  ///
  /// Silently no-ops when no callback is registered or when the gesture is not
  /// supported by [input.stylusType].
  void handle(StylusGesture gesture, StylusInput input) {
    if (!_isSupported(gesture, input.stylusType)) return;
    final action = _mappings[gesture] ?? StylusGestureAction.none;
    if (action == StylusGestureAction.none) return;
    onGesture?.call(action, input);
  }

  // ─── Support matrix ───────────────────────────────────────────────────────

  /// Returns `true` if [gesture] is physically supported by [type].
  static bool _isSupported(StylusGesture gesture, StylusType type) {
    switch (gesture) {
      case StylusGesture.barrelDoubleTap:
        return type == StylusType.applePencil2 ||
            type == StylusType.applePencilPro;
      case StylusGesture.squeeze:
        return type == StylusType.applePencilPro;
      case StylusGesture.barrelButton:
        return type == StylusType.samsungSPen ||
            type == StylusType.wacomEmr;
      case StylusGesture.barrelButton2:
        return type == StylusType.wacomEmr;
      case StylusGesture.airGesture:
        return type == StylusType.samsungSPen;
      case StylusGesture.hoverEnter:
      case StylusGesture.hoverExit:
        return type == StylusType.applePencilPro ||
            type == StylusType.samsungSPen;
    }
  }

  /// Returns a human-readable label for a [StylusGestureAction].
  static String actionLabel(StylusGestureAction action) {
    switch (action) {
      case StylusGestureAction.none:
        return 'No Action';
      case StylusGestureAction.switchToEraser:
        return 'Switch to Eraser';
      case StylusGestureAction.toggleEraser:
        return 'Toggle Eraser';
      case StylusGestureAction.switchToLastTool:
        return 'Switch to Last Tool';
      case StylusGestureAction.showToolPicker:
        return 'Show Tool Picker';
      case StylusGestureAction.showColorPicker:
        return 'Show Colour Picker';
      case StylusGestureAction.undo:
        return 'Undo';
      case StylusGestureAction.redo:
        return 'Redo';
      case StylusGestureAction.toggleEffects:
        return 'Toggle Effects';
      case StylusGestureAction.custom:
        return 'Custom';
    }
  }

  /// Returns a human-readable label for a [StylusGesture].
  static String gestureLabel(StylusGesture gesture) {
    switch (gesture) {
      case StylusGesture.barrelDoubleTap:
        return 'Double Tap (Pencil 2+)';
      case StylusGesture.barrelButton:
        return 'Barrel Button';
      case StylusGesture.squeeze:
        return 'Squeeze (Pencil Pro)';
      case StylusGesture.hoverEnter:
        return 'Hover Enter';
      case StylusGesture.hoverExit:
        return 'Hover Exit';
      case StylusGesture.barrelButton2:
        return 'Barrel Button 2';
      case StylusGesture.airGesture:
        return 'Air Gesture (S Pen)';
    }
  }
}
