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
  bool _isEditing = false;

  late final TextEditingController _urlCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

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
    super.dispose();
  }

  void _save() {
    setState(() {
      _url = _urlCtrl.text;
      _title = _titleCtrl.text;
      _description = _descCtrl.text;
      _isEditing = false;
    });
    widget.onStateChanged({
      'url': _url,
      'title': _title,
      'description': _description,
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
                          color: Colors.blue.shade600,
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
                            fontWeight: FontWeight.w600,
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
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ],
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Copy button
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: _url),
                      );
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text('URL copied'),
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
                  const SizedBox(width: 8),
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
