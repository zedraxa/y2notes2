import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biscuits/features/library/domain/entities/folder.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/domain/entities/smart_collection.dart';
import 'package:biscuits/features/library/domain/entities/tag.dart';

/// Persistence layer for the library feature.
///
/// All data is serialised to [SharedPreferences] as JSON.  In a production app
/// this would be replaced by a proper database (e.g. sqlite / Hive).
class LibraryRepository {
  LibraryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _itemsKey = 'library_items';
  static const String _foldersKey = 'library_folders';
  static const String _tagsKey = 'library_tags';

  // ── Items ────────────────────────────────────────────────────────────────

  Future<List<LibraryItem>> loadItems() async {
    final raw = _prefs.getString(_itemsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(_itemFromMap).toList();
  }

  Future<void> saveItems(List<LibraryItem> items) async {
    await _prefs.setString(
      _itemsKey,
      jsonEncode(items.map(_itemToMap).toList()),
    );
  }

  // ── Folders ──────────────────────────────────────────────────────────────

  Future<List<Folder>> loadFolders() async {
    final raw = _prefs.getString(_foldersKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(_folderFromMap).toList();
  }

  Future<void> saveFolders(List<Folder> folders) async {
    await _prefs.setString(
      _foldersKey,
      jsonEncode(folders.map(_folderToMap).toList()),
    );
  }

  // ── Tags ─────────────────────────────────────────────────────────────────

  Future<List<Tag>> loadTags() async {
    final raw = _prefs.getString(_tagsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(_tagFromMap).toList();
  }

  Future<void> saveTags(List<Tag> tags) async {
    await _prefs.setString(
      _tagsKey,
      jsonEncode(tags.map(_tagToMap).toList()),
    );
  }

  // ── Serialisation helpers ────────────────────────────────────────────────

  Map<String, dynamic> _itemToMap(LibraryItem item) => {
        'id': item.id,
        'type': item.type.name,
        'name': item.name,
        'folderId': item.folderId,
        'thumbnailPath': item.thumbnailPath,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
        'tagIds': item.tagIds,
        'colorLabel': item.colorLabel?.name,
        'isFavorite': item.isFavorite,
        'isInTrash': item.isInTrash,
        'trashedAt': item.trashedAt?.toIso8601String(),
      };

  LibraryItem _itemFromMap(Map<String, dynamic> m) => LibraryItem(
        id: m['id'] as String,
        type: LibraryItemType.values.byName(m['type'] as String),
        name: m['name'] as String,
        folderId: m['folderId'] as String?,
        thumbnailPath: m['thumbnailPath'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        tagIds: (m['tagIds'] as List).cast<String>(),
        colorLabel: m['colorLabel'] == null
            ? null
            : ColorLabel.values.byName(m['colorLabel'] as String),
        isFavorite: m['isFavorite'] as bool,
        isInTrash: m['isInTrash'] as bool,
        trashedAt: m['trashedAt'] == null
            ? null
            : DateTime.parse(m['trashedAt'] as String),
      );

  Map<String, dynamic> _folderToMap(Folder f) => {
        'id': f.id,
        'name': f.name,
        'parentFolderId': f.parentFolderId,
        'color': f.color?.value,
        'emoji': f.emoji,
        'createdAt': f.createdAt.toIso8601String(),
        'updatedAt': f.updatedAt.toIso8601String(),
        'childCount': f.childCount,
      };

  Folder _folderFromMap(Map<String, dynamic> m) => Folder(
        id: m['id'] as String,
        name: m['name'] as String,
        parentFolderId: m['parentFolderId'] as String?,
        color: m['color'] == null ? null : Color(m['color'] as int),
        emoji: m['emoji'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        childCount: m['childCount'] as int? ?? 0,
      );

  Map<String, dynamic> _tagToMap(Tag t) => {
        'id': t.id,
        'name': t.name,
        'color': t.color.value,
        'parentTagId': t.parentTagId,
        'emoji': t.emoji,
        'usageCount': t.usageCount,
        'createdAt': t.createdAt.toIso8601String(),
      };

  Tag _tagFromMap(Map<String, dynamic> m) => Tag(
        id: m['id'] as String,
        name: m['name'] as String,
        color: Color(m['color'] as int),
        parentTagId: m['parentTagId'] as String?,
        emoji: m['emoji'] as String?,
        usageCount: m['usageCount'] as int? ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

/// Default smart collections available in every fresh install.
List<SmartCollection> get builtInSmartCollections => defaultSmartCollections();
