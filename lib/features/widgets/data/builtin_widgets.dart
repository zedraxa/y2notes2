import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';
import 'package:y2notes2/features/widgets/widgets/calculator_widget.dart';
import 'package:y2notes2/features/widgets/widgets/checkbox_list_widget.dart';
import 'package:y2notes2/features/widgets/widgets/color_swatch_widget.dart';
import 'package:y2notes2/features/widgets/widgets/counter_widget.dart';
import 'package:y2notes2/features/widgets/widgets/date_picker_widget.dart';
import 'package:y2notes2/features/widgets/widgets/link_card_widget.dart';
import 'package:y2notes2/features/widgets/widgets/pomodoro_widget.dart';
import 'package:y2notes2/features/widgets/widgets/progress_bar_widget.dart';
import 'package:y2notes2/features/widgets/widgets/rating_widget.dart';
import 'package:y2notes2/features/widgets/widgets/timer_widget.dart';
import 'package:y2notes2/features/widgets/widgets/voice_note_widget.dart';
import 'package:y2notes2/features/widgets/widgets/weather_widget.dart';

/// Registry of all available built-in smart widget prototypes.
abstract class BuiltinWidgets {
  BuiltinWidgets._();

  /// Creates a fresh list of all available widget prototypes.
  static List<SmartWidget> all() => [
        CheckboxListWidget(),
        TimerWidget(),
        ProgressBarWidget(),
        CounterWidget(),
        RatingWidget(),
        DatePickerWidget(),
        ColorSwatchWidget(),
        PomodoroWidget(),
        WeatherWidget(),
        LinkCardWidget(),
        CalculatorWidget(),
        VoiceNoteWidget(),
      ];
}
