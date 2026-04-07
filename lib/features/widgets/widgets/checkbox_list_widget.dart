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
                  {'text': 'Item 1', 'checked': false},
                  {'text': 'Item 2', 'checked': false},
                  {'text': 'Item 3', 'checked': false},
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
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _CheckboxListOverlay(widget: this, onStateChanged: onStateChanged);
}

class _CheckboxListOverlay extends StatefulWidget {
  const _CheckboxListOverlay({
    required this.widget,
    required this.onStateChanged,
  });

  final CheckboxListWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_CheckboxListOverlay> createState() => _CheckboxListOverlayState();
}

class _CheckboxListOverlayState extends State<_CheckboxListOverlay> {
  late List<Map<String, dynamic>> _items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final raw = widget.widget.state['items'] as List?;
    _items = raw
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  void _notify() {
    widget.onStateChanged({'items': _items});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('☑️ Checklist',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  onReorder: (old, nw) {
                    setState(() {
                      final item = _items.removeAt(old);
                      _items.insert(nw > old ? nw - 1 : nw, item);
                    });
                    _notify();
                  },
                  itemBuilder: (_, i) => CheckboxListTile(
                    key: ValueKey(i),
                    value: _items[i]['checked'] as bool? ?? false,
                    title: Text(
                      _items[i]['text'] as String? ?? '',
                      style: TextStyle(
                        decoration: _items[i]['checked'] == true
                            ? TextDecoration.lineThrough
                            : null,
                        fontSize: 14,
                      ),
                    ),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) {
                      setState(
                          () => _items[i]['checked'] = v ?? false);
                      _notify();
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() => _items.removeAt(i));
                        _notify();
                      },
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add item...',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: _addItem,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _addItem() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _items.add({'text': _controller.text, 'checked': false});
      _controller.clear();
    });
    _notify();
  }
}
