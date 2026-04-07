import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/templates/domain/entities/page_template.dart';
import 'package:y2notes2/features/templates/domain/entities/template_region.dart';

/// Persists custom templates and recently-used template IDs.
class TemplateRepository {
  TemplateRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _customKey = 'y2_custom_templates';
  static const _recentKey = 'y2_recent_templates';
  static const int _maxRecent = 10;

  // ── Custom templates ───────────────────────────────────────────────────────

  Future<List<NoteTemplate>> loadCustomTemplates() async {
    final raw = _prefs.getString(_customKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(_templateFromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomTemplate(NoteTemplate t) async {
    final existing = await loadCustomTemplates();
    existing.add(t);
    await _prefs.setString(
      _customKey,
      jsonEncode(existing.map(_templateToJson).toList()),
    );
  }

  Future<void> deleteCustomTemplate(String id) async {
    final existing = await loadCustomTemplates();
    existing.removeWhere((t) => t.id == id);
    await _prefs.setString(
      _customKey,
      jsonEncode(existing.map(_templateToJson).toList()),
    );
  }

  // ── Recently used ──────────────────────────────────────────────────────────

  Future<List<String>> loadRecentlyUsedIds() async {
    final raw = _prefs.getStringList(_recentKey);
    return raw ?? [];
  }

  Future<void> recordTemplateUsage(String templateId) async {
    final ids = await loadRecentlyUsedIds();
    ids.remove(templateId);
    ids.insert(0, templateId);
    if (ids.length > _maxRecent) {
      ids.removeRange(_maxRecent, ids.length);
    }
    await _prefs.setStringList(_recentKey, ids);
  }

  // ── Serialisation helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _templateToJson(NoteTemplate t) => {
        'id': t.id,
        'name': t.name,
        'description': t.description,
        'category': t.category,
        'iconEmoji': t.iconEmoji,
        'accentColor': t.accentColor.value,
        'background': t.background.index,
        'regions': t.regions.map(_regionToJson).toList(),
        'isCustom': t.isCustom,
        'createdAt': t.createdAt.toIso8601String(),
      };

  NoteTemplate _templateFromJson(Map<String, dynamic> j) => NoteTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        category: j['category'] as String,
        iconEmoji: j['iconEmoji'] as String,
        accentColor: Color(j['accentColor'] as int),
        background: PageTemplate.values[j['background'] as int],
        regions:
            (j['regions'] as List).map((r) => _regionFromJson(r)).toList(),
        isCustom: true,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> _regionToJson(TemplateRegion r) => {
        'label': r.label,
        'l': r.bounds.left,
        't': r.bounds.top,
        'w': r.bounds.width,
        'h': r.bounds.height,
        'type': r.type.index,
        if (r.backgroundColor != null) 'bg': r.backgroundColor!.value,
      };

  TemplateRegion _regionFromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return TemplateRegion(
      label: m['label'] as String,
      bounds: Rect.fromLTWH(
        (m['l'] as num).toDouble(),
        (m['t'] as num).toDouble(),
        (m['w'] as num).toDouble(),
        (m['h'] as num).toDouble(),
      ),
      type: RegionType.values[m['type'] as int],
      backgroundColor: m['bg'] != null ? Color(m['bg'] as int) : null,
    );
  }
}
