import 'package:flutter/material.dart';
import 'package:biscuitse/features/widgets/domain/entities/smart_widget.dart';

class DatePickerWidget extends SmartWidget {
  DatePickerWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 100),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.datePicker,
          state: state ??
              {'date': DateTime.now().toIso8601String(), 'showCountdown': true},
        );

  @override
  String get label => 'Date Picker';
  @override
  String get iconEmoji => '📆';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      DatePickerWidget(
        id: id,
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
        state: state ?? this.state,
      );

  @override
  Widget buildInteractiveOverlay(BuildContext context,
          {required ValueChanged<Map<String, dynamic>> onStateChanged}) =>
      _DatePickerOverlay(widget: this, onStateChanged: onStateChanged);
}

class _DatePickerOverlay extends StatefulWidget {
  const _DatePickerOverlay(
      {required this.widget, required this.onStateChanged});
  final DatePickerWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_DatePickerOverlay> createState() => _DatePickerOverlayState();
}

class _DatePickerOverlayState extends State<_DatePickerOverlay> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = DateTime.tryParse(
            widget.widget.state['date'] as String? ?? '') ??
        DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final diff = _date.difference(DateTime.now());
    final daysStr = diff.isNegative
        ? '${diff.inDays.abs()} days ago'
        : diff.inDays == 0
            ? 'Today'
            : 'in ${diff.inDays} days';

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            setState(() => _date = picked);
            widget.onStateChanged({'date': picked.toIso8601String()});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📆', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(daysStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
