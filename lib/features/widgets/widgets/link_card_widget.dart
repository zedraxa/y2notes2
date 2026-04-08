import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// URL link card with editable fields and copy support.
class LinkCardWidget extends SmartWidget {
  LinkCardWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(260, 140),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.linkCard,
          state: state ??
              const {
                'url': 'https://example.com',
                'title': 'Example',
                'description': 'An example link',
              },
        );

  @override
  String get label => 'Link Card';
  @override
  String get iconEmoji => '🔗';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      LinkCardWidget(
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
      _LinkCardOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _LinkCardOverlay extends StatefulWidget {
  const _LinkCardOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final LinkCardWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_LinkCardOverlay> createState() =>
      _LinkCardOverlayState();
}

class _LinkCardOverlayState
    extends State<_LinkCardOverlay> {
  late String _url;
  late String _title;
  late String _description;
  late bool _isBookmarked;
  late List<String> _tags;
  bool _isEditing = false;
  bool _addingTag = false;

  late final TextEditingController _urlCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _url =
        widget.widget.state['url'] as String? ?? '';
    _title =
        widget.widget.state['title'] as String? ?? '';
    _description =
        widget.widget.state['description']
            as String? ??
            '';
    _isBookmarked =
        widget.widget.state['isBookmarked']
                as bool? ??
            false;
    final rawTags =
        widget.widget.state['tags'] as List?;
    _tags = rawTags
            ?.map((e) => e.toString())
            .toList() ??
        [];
    _urlCtrl = TextEditingController(text: _url);
    _titleCtrl = TextEditingController(text: _title);
    _descCtrl =
        TextEditingController(text: _description);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _url = _urlCtrl.text;
      _title = _titleCtrl.text;
      _description = _descCtrl.text;
      _isEditing = false;
    });
    _notifyAll();
  }

  void _notifyAll() {
    widget.onStateChanged({
      'url': _url,
      'title': _title,
      'description': _description,
      'isBookmarked': _isBookmarked,
      'tags': _tags,
    });
  }

  String get _domain {
    try {
      return Uri.parse(_url).host;
    } catch (_) {
      return _url;
    }
  }

  String get _faviconLetter {
    final d = _domain;
    if (d.startsWith('www.')) {
      return d.substring(4, 5).toUpperCase();
    }
    return d.isNotEmpty
        ? d[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditMode();
    }
    return _buildDisplayMode(context);
  }

  Widget _buildDisplayMode(BuildContext context) =>
      Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: _isBookmarked
                ? Border.all(
                    color: Colors.amber.shade300,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Favicon placeholder
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _faviconLetter,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.blue.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        Text(
                          _domain,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bookmark toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _isBookmarked =
                          !_isBookmarked);
                      _notifyAll();
                    },
                    child: Icon(
                      _isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 20,
                      color: _isBookmarked
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              if (_description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Tags
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: _tags
                      .asMap()
                      .entries
                      .map(
                        (e) => GestureDetector(
                          onLongPress: () {
                            setState(() =>
                                _tags.removeAt(
                                  e.key,
                                ));
                            _notifyAll();
                          },
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .blue.shade50,
                              borderRadius:
                                  BorderRadius
                                      .circular(8),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue
                                    .shade600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const Spacer(),
              // Action row
              Row(
                children: [
                  // URL display
                  Expanded(
                    child: Text(
                      _url,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                  // Add tag button
                  if (_addingTag)
                    SizedBox(
                      width: 60,
                      height: 18,
                      child: TextField(
                        controller: _tagCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        decoration:
                            const InputDecoration(
                          isDense: true,
                          hintText: 'tag',
                          contentPadding:
                              EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          if (v.isNotEmpty) {
                            setState(
                              () => _tags.add(v),
                            );
                            _notifyAll();
                          }
                          setState(() {
                            _addingTag = false;
                            _tagCtrl.clear();
                          });
                        },
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(
                        () => _addingTag = true,
                      ),
                      child: Icon(
                        Icons.label_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Copy button
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: _url),
                      );
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text('URL copied'),
                          duration:
                              Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit button
                  GestureDetector(
                    onTap: () => setState(
                      () => _isEditing = true,
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildEditMode() => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _field(_titleCtrl, 'Title'),
              const SizedBox(height: 4),
              _field(_urlCtrl, 'URL'),
              const SizedBox(height: 4),
              _field(_descCtrl, 'Description'),
              const Spacer(),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _isEditing = false,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
  ) =>
      SizedBox(
        height: 28,
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ),
      );
}
