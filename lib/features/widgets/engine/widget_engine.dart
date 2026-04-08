import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

/// Manages widget lifecycle — hit testing, z-ordering, etc.
class WidgetEngine {
  final Map<String, int> _zOrder = {};
  int _nextZ = 0;

  /// Hit-tests all widgets at [position] (in canvas coordinates).
  /// Returns the topmost widget (highest z-order) that contains
  /// the position.
  SmartWidget? hitTest(
    List<SmartWidget> widgets,
    Offset position,
  ) {
    final sorted = sortedByZ(widgets);
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].bounds.contains(position)) {
        return sorted[i];
      }
    }
    return null;
  }

  /// Returns widgets sorted front-to-back (last = front).
  List<SmartWidget> sortedByZ(
    List<SmartWidget> widgets,
  ) {
    final list = List<SmartWidget>.from(widgets);
    list.sort((a, b) {
      final zA = _zOrder[a.id] ?? 0;
      final zB = _zOrder[b.id] ?? 0;
      return zA.compareTo(zB);
    });
    return list;
  }

  /// Brings the widget with [id] to the front of the z-order.
  void bringToFront(String id) {
    _nextZ++;
    _zOrder[id] = _nextZ;
  }

  /// Sends the widget with [id] to the back of the z-order.
  void sendToBack(String id) {
    final minZ = _zOrder.values.isEmpty
        ? 0
        : _zOrder.values.reduce(
            (a, b) => a < b ? a : b,
          );
    _zOrder[id] = minZ - 1;
  }

  /// Returns the z-index of the given widget id.
  int zIndexOf(String id) => _zOrder[id] ?? 0;

  /// Removes the widget from z-order tracking.
  void remove(String id) {
    _zOrder.remove(id);
  }
}
