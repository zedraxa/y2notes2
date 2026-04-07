/// RGA (Replicated Growable Array) character-level CRDT for collaborative
/// text editing inside TextCardNode / StickyNoteNode.
///
/// Each character has a globally-unique [charId] and a pointer to the
/// character that precedes it. Insertions are conflict-free because a new
/// character is always positioned relative to an existing one (or the head).
/// Deletions are implemented as soft-deletes (tombstones) so concurrent
/// delete + insert sequences remain consistent.
library text_crdt;

/// A single character entry in the RGA sequence.
class RgaChar {
  const RgaChar({
    required this.charId,
    required this.authorId,
    required this.character,
    this.afterCharId,
    this.isDeleted = false,
  });

  /// Globally unique identifier for this character.
  final String charId;

  /// The user who inserted this character.
  final String authorId;

  /// The visible character (single Unicode scalar value).
  final String character;

  /// ID of the character this one was inserted after (null = head of document).
  final String? afterCharId;

  /// Tombstone flag — character has been deleted but kept for ordering.
  final bool isDeleted;

  RgaChar copyWith({bool? isDeleted}) => RgaChar(
        charId: charId,
        authorId: authorId,
        character: character,
        afterCharId: afterCharId,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'charId': charId,
        'authorId': authorId,
        'character': character,
        'afterCharId': afterCharId,
        'isDeleted': isDeleted,
      };

  factory RgaChar.fromJson(Map<String, dynamic> json) => RgaChar(
        charId: json['charId'] as String,
        authorId: json['authorId'] as String,
        character: json['character'] as String,
        afterCharId: json['afterCharId'] as String?,
        isDeleted: (json['isDeleted'] as bool?) ?? false,
      );
}

/// Collaborative text document using the RGA algorithm.
///
/// Operations are idempotent — applying the same insert or delete twice has
/// no additional effect. Concurrent inserts at the same position are resolved
/// deterministically by comparing [charId] strings (lexicographic order).
class TextCrdt {
  TextCrdt() : _chars = [];

  /// Internal list of all characters (including tombstoned ones) in order.
  final List<RgaChar> _chars;

  /// Applied charIds used for idempotency.
  final Set<String> _appliedInserts = {};
  final Set<String> _appliedDeletes = {};

  // ─── Queries ──────────────────────────────────────────────────────────────

  /// Returns the visible (non-deleted) text content.
  String get text =>
      _chars.where((c) => !c.isDeleted).map((c) => c.character).join();

  /// Returns all character entries (including tombstones) in document order.
  List<RgaChar> get chars => List.unmodifiable(_chars);

  // ─── Mutations ────────────────────────────────────────────────────────────

  /// Insert [char] with identity [charId] after the character [afterCharId].
  ///
  /// If [afterCharId] is null the character is inserted at the head.
  /// Idempotent — a second call with the same [charId] is a no-op.
  void insert({
    required String charId,
    required String authorId,
    required String character,
    String? afterCharId,
  }) {
    if (_appliedInserts.contains(charId)) return;
    _appliedInserts.add(charId);

    final entry = RgaChar(
      charId: charId,
      authorId: authorId,
      character: character,
      afterCharId: afterCharId,
    );

    // Find the insertion index using RGA rules:
    // 1. Locate the anchor (afterCharId), or head if null.
    // 2. Skip over any concurrent inserts with a lexicographically greater charId
    //    that also refer to the same anchor (to keep ordering stable).
    int insertPos = 0;
    if (afterCharId != null) {
      insertPos = _chars.indexWhere((c) => c.charId == afterCharId);
      if (insertPos == -1) {
        // Anchor not yet known — append at end (will be re-ordered on resync).
        _chars.add(entry);
        return;
      }
      insertPos += 1; // start scanning after the anchor
    }

    // Skip concurrent siblings with a higher charId (tie-break).
    while (insertPos < _chars.length) {
      final sibling = _chars[insertPos];
      if (sibling.afterCharId == afterCharId &&
          sibling.charId.compareTo(charId) > 0) {
        insertPos++;
      } else {
        break;
      }
    }

    _chars.insert(insertPos, entry);
  }

  /// Mark character [charId] as deleted (tombstone).
  ///
  /// Idempotent — deleting an already-deleted character is a no-op.
  void delete(String charId) {
    if (_appliedDeletes.contains(charId)) return;
    _appliedDeletes.add(charId);

    final idx = _chars.indexWhere((c) => c.charId == charId);
    if (idx == -1) return;
    _chars[idx] = _chars[idx].copyWith(isDeleted: true);
  }

  // ─── Convenience helpers ─────────────────────────────────────────────────

  /// Returns the [charId] of the visible character at [visibleIndex], or null
  /// if the index is out of range.
  String? charIdAt(int visibleIndex) {
    int count = 0;
    for (final c in _chars) {
      if (!c.isDeleted) {
        if (count == visibleIndex) return c.charId;
        count++;
      }
    }
    return null;
  }

  /// Returns the [charId] of the character immediately before [visibleIndex]
  /// (i.e. the anchor for inserting at that position).
  ///
  /// Returns null when inserting at the head (position 0).
  String? anchorBefore(int visibleIndex) {
    if (visibleIndex == 0) return null;
    return charIdAt(visibleIndex - 1);
  }

  // ─── Serialisation ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> toJson() =>
      _chars.map((c) => c.toJson()).toList();

  /// Rebuilds a [TextCrdt] from a serialised snapshot.
  static TextCrdt fromJson(List<dynamic> json) {
    final doc = TextCrdt();
    for (final raw in json) {
      final c = RgaChar.fromJson(raw as Map<String, dynamic>);
      // Re-apply as inserts (then deletes) so ordering logic is respected.
      doc.insert(
        charId: c.charId,
        authorId: c.authorId,
        character: c.character,
        afterCharId: c.afterCharId,
      );
      if (c.isDeleted) doc.delete(c.charId);
    }
    return doc;
  }
}
