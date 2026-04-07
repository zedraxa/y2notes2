import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// URL with preview title/favicon, tap to open.
class LinkCardWidget extends SmartWidget {
  LinkCardWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(260, 90),
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
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _LinkCardOverlay(widget: this, onStateChanged: onStateChanged);
}

class _LinkCardOverlay extends StatelessWidget {
  const _LinkCardOverlay(
      {required this.widget, required this.onStateChanged});
  final LinkCardWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final url = widget.state['url'] as String? ?? '';
    final title = widget.state['title'] as String? ?? '';
    final desc = widget.state['description'] as String? ?? '';

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open: $url')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(url,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.blue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
