import 'package:flutter/material.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

class DatePickerWidget extends SmartWidget {
  DatePickerWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(220, 130),
    super.config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.datePicker,
          state: state ??
              {
                'date': DateTime.now().toIso8601String(),
                'showCountdown': true,
                'note': '',
              },
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
  Widget buildInteractiveOverlay(
    BuildContext context, {
    required ValueChanged<Map<String, dynamic>> onStateChanged,
  }) =>
      _DatePickerOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _DatePickerOverlay extends StatefulWidget {
  const _DatePickerOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final DatePickerWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_DatePickerOverlay> createState() =>
      _DatePickerOverlayState();
}

class _DatePickerOverlayState
    extends State<_DatePickerOverlay> {
  late DateTime _date;
  late String _note;
  late bool _isImportant;
  bool _editingNote = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = DateTime.tryParse(
          widget.widget.state['date'] as String? ?? '',
        ) ??
        DateTime.now();
    _note =
        widget.widget.state['note'] as String? ?? '';
    _isImportant =
        widget.widget.state['isImportant']
                as bool? ??
            false;
    _noteController.text = _note;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onStateChanged({
      'date': _date.toIso8601String(),
      'note': _note,
      'isImportant': _isImportant,
    });
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int _weekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final dayOfYear = date
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    return ((dayOfYear -
                    date.weekday +
                    10) ~/
                7)
            .clamp(1, 53);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(_date.year, _date.month, _date.day);
    final diff = target.difference(today);

    String daysStr;
    Color daysColor;
    if (diff.inDays == 0) {
      daysStr = '📌 Today';
      daysColor = Colors.green;
    } else if (diff.inDays == 1) {
      daysStr = 'Tomorrow';
      daysColor = Colors.blue;
    } else if (diff.inDays == -1) {
      daysStr = 'Yesterday';
      daysColor = Colors.orange;
    } else if (diff.isNegative) {
      daysStr = '${diff.inDays.abs()} days ago';
      daysColor = Colors.grey;
    } else {
      daysStr = 'in ${diff.inDays} days';
      daysColor = Colors.blue;
    }

    final weekday = _weekdays[_date.weekday - 1];
    final month = _months[_date.month - 1];
    final weekNum = _weekNumber(_date);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _date = picked);
            _notify();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: _isImportant
                ? Border.all(
                    color: Colors.amber.shade300,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              // Day of week + importance + week num
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isImportant =
                          !_isImportant);
                      _notify();
                    },
                    child: Text(
                      _isImportant ? '⭐' : '📆',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: Text(
                      'W$weekNum',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Full date
              Text(
                '$month ${_date.day}, ${_date.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              // Countdown
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  daysStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: daysColor,
                  ),
                ),
              ),
              // Note field
              const SizedBox(height: 4),
              if (_editingNote)
                SizedBox(
                  height: 24,
                  child: TextField(
                    controller: _noteController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    onSubmitted: (v) {
                      setState(() {
                        _note = v;
                        _editingNote = false;
                      });
                      _notify();
                    },
                  ),
                )
              else
                GestureDetector(
                  onTap: () => setState(
                    () => _editingNote = true,
                  ),
                  child: Text(
                    _note.isEmpty
                        ? 'Tap to add note'
                        : _note,
                    style: TextStyle(
                      fontSize: 11,
                      color: _note.isEmpty
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontStyle: _note.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
