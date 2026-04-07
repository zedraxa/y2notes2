import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Persists widget state across sessions via SharedPreferences.
class WidgetRepository {
  WidgetRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'y2_smart_widgets';

  /// Saves the list of widget state snapshots.
  Future<void> saveWidgets(List<SmartWidget> widgets) async {
    final list = widgets.map(_widgetToJson).toList();
    await _prefs.setString(_key, jsonEncode(list));
  }

  /// Loads saved widget state (positions, sizes, widget-specific state).
  /// Returns raw maps — caller is responsible for deserialising into
  /// concrete widget types.
  Future<List<Map<String, dynamic>>> loadWidgetSnapshots() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _widgetToJson(SmartWidget w) => {
        'id': w.id,
        'type': w.type.index,
        'x': w.position.dx,
        'y': w.position.dy,
        'w': w.size.width,
        'h': w.size.height,
        'config': w.config,
        'state': w.state,
      };
}
