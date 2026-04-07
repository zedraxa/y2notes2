import 'package:flutter/material.dart';

/// An entry stored inside a [QuadTree].
class _QtEntry<T> {
  _QtEntry(this.id, this.item, this.bounds);
  final String id;
  final T item;
  final Rect bounds;
}

/// A QuadTree for O(log n) spatial queries.
///
/// Supports insert / remove / query operations.  Nodes outside the initial
/// [bounds] are stored in the root bucket (they still work, but queries
/// against very large regions will be O(n)).
class QuadTree<T> {
  QuadTree({
    required this.bounds,
    int maxItems = 8,
    int maxDepth = 10,
  })  : _maxItems = maxItems,
        _maxDepth = maxDepth;

  /// The spatial region covered by this tree node.
  final Rect bounds;
  final int _maxItems;
  final int _maxDepth;

  final List<_QtEntry<T>> _items = [];

  // Four quadrants: NW, NE, SW, SE
  QuadTree<T>? _nw;
  QuadTree<T>? _ne;
  QuadTree<T>? _sw;
  QuadTree<T>? _se;
  bool get _isLeaf => _nw == null;

  int get _depth => _depthOf(this);

  static int _depthOf<T>(QuadTree<T> node) {
    if (node._isLeaf) return 0;
    return 1 + _depthOf(node._nw!);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Insert [item] with spatial key [itemBounds].
  void insert(T item, Rect itemBounds) {
    _insert(_QtEntry<T>(_idOf(item), item, itemBounds));
  }

  /// Remove the entry whose id matches [id].
  void remove(String id) {
    _remove(id);
  }

  /// Return all items whose bounds intersect [queryRect].
  List<T> query(Rect queryRect) {
    final results = <T>[];
    _query(queryRect, results);
    return results;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _insert(_QtEntry<T> entry) {
    if (!bounds.overlaps(entry.bounds) &&
        !bounds.contains(entry.bounds.center)) {
      // Clamp out-of-bounds items into this root.
      _items.add(entry);
      return;
    }

    if (!_isLeaf) {
      final q = _quadrantFor(entry.bounds);
      if (q != null) {
        q._insert(entry);
        return;
      }
    }

    _items.add(entry);

    // Split if over capacity and not at max depth.
    if (_items.length > _maxItems && _depth < _maxDepth) {
      _split();
    }
  }

  void _split() {
    final mid = bounds.center;
    _nw = QuadTree<T>(
      bounds: Rect.fromLTRB(bounds.left, bounds.top, mid.dx, mid.dy),
      maxItems: _maxItems,
      maxDepth: _maxDepth,
    );
    _ne = QuadTree<T>(
      bounds: Rect.fromLTRB(mid.dx, bounds.top, bounds.right, mid.dy),
      maxItems: _maxItems,
      maxDepth: _maxDepth,
    );
    _sw = QuadTree<T>(
      bounds: Rect.fromLTRB(bounds.left, mid.dy, mid.dx, bounds.bottom),
      maxItems: _maxItems,
      maxDepth: _maxDepth,
    );
    _se = QuadTree<T>(
      bounds: Rect.fromLTRB(mid.dx, mid.dy, bounds.right, bounds.bottom),
      maxItems: _maxItems,
      maxDepth: _maxDepth,
    );

    final toRedistribute = List<_QtEntry<T>>.from(_items);
    _items.clear();

    for (final e in toRedistribute) {
      final q = _quadrantFor(e.bounds);
      if (q != null) {
        q._insert(e);
      } else {
        _items.add(e); // Spans multiple quadrants — keep in parent.
      }
    }
  }

  QuadTree<T>? _quadrantFor(Rect r) {
    final mid = bounds.center;
    if (r.right <= mid.dx && r.bottom <= mid.dy) return _nw;
    if (r.left >= mid.dx && r.bottom <= mid.dy) return _ne;
    if (r.right <= mid.dx && r.top >= mid.dy) return _sw;
    if (r.left >= mid.dx && r.top >= mid.dy) return _se;
    return null; // Spans more than one quadrant.
  }

  bool _remove(String id) {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items.removeAt(i);
        return true;
      }
    }
    if (!_isLeaf) {
      return _nw!._remove(id) ||
          _ne!._remove(id) ||
          _sw!._remove(id) ||
          _se!._remove(id);
    }
    return false;
  }

  void _query(Rect queryRect, List<T> out) {
    if (!bounds.overlaps(queryRect)) return;

    for (final e in _items) {
      if (e.bounds.overlaps(queryRect)) {
        out.add(e.item);
      }
    }

    if (!_isLeaf) {
      _nw!._query(queryRect, out);
      _ne!._query(queryRect, out);
      _sw!._query(queryRect, out);
      _se!._query(queryRect, out);
    }
  }

  /// Extracts a stable string ID from [item].  Assumes T has an `id` field
  /// (all CanvasNode subtypes do).  Falls back to hash for other types.
  static String _idOf(dynamic item) {
    try {
      return (item as dynamic).id as String;
    } catch (_) {
      return item.hashCode.toString();
    }
  }
}
