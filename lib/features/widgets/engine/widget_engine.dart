import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

/// Manages widget lifecycle — hit testing, z-ordering, etc.
class WidgetEngine {
  /// Hit-tests all widgets at [position] (in canvas coordinates).
  /// Returns the topmost widget (last in list) that contains the position.
  SmartWidget? hitTest(List<SmartWidget> widgets, Offset position) {
    for (int i = widgets.length - 1; i >= 0; i--) {
      if (widgets[i].bounds.contains(position)) return widgets[i];
    }
    return null;
  }

  /// Returns widgets sorted front-to-back (last = front).
  List<SmartWidget> sortedByZ(List<SmartWidget> widgets) =>
      List<SmartWidget>.from(widgets);
}
