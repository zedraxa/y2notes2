import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

class CheckboxListWidget extends SmartWidget {
  CheckboxListWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(260, 300),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.checkboxList,
          state: state ??
              const {
                'items': [
                  {
                    'text': 'Item 1',
                    'checked': false,
                    'priority': 0,
                  },
                  {
                    'text': 'Item 2',
                    'checked': false,
                    'priority': 0,
                  },
                  {
                    'text': 'Item 3',
                    'checked': false,
                    'priority': 0,
                  },
                ],
              },
        );

  @override
  String get label => 'Checklist';
  @override
  String get iconEmoji => '☑️';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      CheckboxListWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _CheckboxListOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _CheckboxListOverlay extends StatefulWidget {
  const _CheckboxListOverlay({
    required this.widget,
    required this.onStateChanged,
  });

  final CheckboxListWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CheckboxListOverlay> createState() =>
      _CheckboxListOverlayState();
}

class _CheckboxListOverlayState
    extends State<_CheckboxListOverlay> {
  late List<Map<String, dynamic>> _items;
  final _controller = TextEditingController();
  int _editingIndex = -1;
  final _editController = TextEditingController();
  int _sortMode = 0; // 0=manual, 1=priority, 2=alpha

  static const _sortLabels = ['⇅', '🚩', 'Aa'];

  @override
  void initState() {
    super.initState();
    final raw = widget.widget.state['items'] as List?;
    _items = raw
            ?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList() ??
        [];
    _sortMode =
        widget.widget.state['sortMode'] as int? ?? 0;
  }

  void _notify() {
    widget.onStateChanged({
      'items': _items,
      'sortMode': _sortMode,
    });
  }

  int get _checkedCount =>
      _items.where((e) => e['checked'] == true).length;

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 1:
        return '!';
      case 2:
        return '!!';
      default:
        return '';
    }
  }

  void _cyclePriority(int index) {
    setState(() {
      final cur =
          _items[index]['priority'] as int? ?? 0;
      _items[index]['priority'] = (cur + 1) % 3;
    });
    _notify();
  }

  void _clearCompleted() {
    setState(() {
      _items.removeWhere(
        (e) => e['checked'] == true,
      );
    });
    _notify();
  }

  void _cycleSortMode() {
    setState(() {
      _sortMode = (_sortMode + 1) % 3;
    });
    _notify();
  }

  List<Map<String, dynamic>> get _sortedItems {
    if (_sortMode == 0) return _items;
    final sorted =
        List<Map<String, dynamic>>.from(_items);
    if (_sortMode == 1) {
      // Sort by priority desc, unchecked first
      sorted.sort((a, b) {
        final aChecked =
            a['checked'] == true ? 1 : 0;
        final bChecked =
            b['checked'] == true ? 1 : 0;
        if (aChecked != bChecked) {
          return aChecked - bChecked;
        }
        final aPri = a['priority'] as int? ?? 0;
        final bPri = b['priority'] as int? ?? 0;
        return bPri - aPri;
      });
    } else if (_sortMode == 2) {
      // Sort alphabetically
      sorted.sort((a, b) {
        final aText =
            (a['text'] as String? ?? '')
                .toLowerCase();
        final bText =
            (b['text'] as String? ?? '')
                .toLowerCase();
        return aText.compareTo(bText);
      });
    }
    return sorted;
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text =
          _items[index]['text'] as String? ?? '';
    });
  }

  void _finishEditing() {
    if (_editingIndex >= 0 &&
        _editingIndex < _items.length) {
      setState(() {
        _items[_editingIndex]['text'] =
            _editController.text;
        _editingIndex = -1;
      });
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final done = _checkedCount;
    final progress =
        total > 0 ? done / total : 0.0;
    final displayItems = _sortedItems;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Text(
                    '☑️ Checklist',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Sort toggle
                  GestureDetector(
                    onTap: _cycleSortMode,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _sortMode > 0
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(
                        _sortLabels[_sortMode],
                        style: TextStyle(
                          fontSize: 11,
                          color: _sortMode > 0
                              ? Colors.blue.shade600
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$done/$total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (done > 0) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _clearCompleted,
                      child: Icon(
                        Icons.cleaning_services,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      Colors.grey.shade200,
                  color:
                      done == total && total > 0
                          ? Colors.green
                          : Colors.blue,
                ),
              ),
            ),
            // Completion celebration
            if (done == total && total > 0)
              Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                  left: 8,
                ),
                child: Text(
                  '🎉 All done!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            // Items list
            Expanded(
              child: _sortMode == 0
                  ? ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          displayItems.length,
                      onReorder: (old, nw) {
                        setState(() {
                          final item =
                              _items.removeAt(old);
                          _items.insert(
                            nw > old
                                ? nw - 1
                                : nw,
                            item,
                          );
                        });
                        _notify();
                      },
                      itemBuilder: (_, i) =>
                          _buildItem(
                        displayItems[i],
                        i,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          displayItems.length,
                      itemBuilder: (_, i) =>
                          _buildItem(
                        displayItems[i],
                        _items.indexOf(
                          displayItems[i],
                        ),
                      ),
                    ),
            ),
            // Add item row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(
                      hintText: 'Add item...',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                  ),
                  onPressed: _addItem,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    Map<String, dynamic> item,
    int originalIndex,
  ) {
    final priority =
        item['priority'] as int? ?? 0;
    final isEditing =
        _editingIndex == originalIndex;

    return CheckboxListTile(
      key: ValueKey(originalIndex),
      value: item['checked'] as bool? ?? false,
      title: Row(
        children: [
          if (priority > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: _priorityColor(
                  priority,
                ).withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(4),
              ),
              child: Text(
                _priorityLabel(priority),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _priorityColor(
                    priority,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: isEditing
                ? SizedBox(
                    height: 24,
                    child: TextField(
                      controller:
                          _editController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      decoration:
                          const InputDecoration(
                        isDense: true,
                        border:
                            InputBorder.none,
                        contentPadding:
                            EdgeInsets.zero,
                      ),
                      onSubmitted: (_) =>
                          _finishEditing(),
                    ),
                  )
                : GestureDetector(
                    onDoubleTap: () =>
                        _startEditing(
                      originalIndex,
                    ),
                    child: Text(
                      item['text']
                              as String? ??
                          '',
                      style: TextStyle(
                        decoration:
                            item['checked'] ==
                                    true
                                ? TextDecoration
                                    .lineThrough
                                : null,
                        color:
                            item['checked'] ==
                                    true
                                ? Colors.grey
                                    .shade400
                                : null,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      dense: true,
      controlAffinity:
          ListTileControlAffinity.leading,
      onChanged: (v) {
        setState(() =>
            _items[originalIndex]['checked'] =
                v ?? false);
        _notify();
      },
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _cyclePriority(
              originalIndex,
            ),
            child: Icon(
              Icons.flag,
              size: 14,
              color: priority > 0
                  ? _priorityColor(priority)
                  : Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(
                () => _items.removeAt(
                  originalIndex,
                ),
              );
              _notify();
            },
            child: const Icon(
              Icons.close,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _items.add({
        'text': _controller.text,
        'checked': false,
        'priority': 0,
      });
      _controller.clear();
    });
    _notify();
  }
}
