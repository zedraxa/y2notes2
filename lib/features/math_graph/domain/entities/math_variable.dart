import 'package:equatable/equatable.dart';

/// A user-defined variable that can be used in graph expressions.
///
/// For example: `a = 3` allows the user to write `a*x + 1`.
class MathVariable extends Equatable {
  const MathVariable({
    required this.name,
    required this.value,
    this.min,
    this.max,
    this.step,
  });

  /// Single-character or short name for the variable (e.g. "a", "b", "k").
  final String name;

  /// Current numeric value.
  final double value;

  /// Optional range limits for slider-based editing.
  final double? min;
  final double? max;
  final double? step;

  /// Whether this variable supports slider editing.
  bool get hasRange => min != null && max != null;

  MathVariable copyWith({
    String? name,
    double? value,
    double? min,
    double? max,
    double? step,
    bool clearRange = false,
  }) =>
      MathVariable(
        name: name ?? this.name,
        value: value ?? this.value,
        min: clearRange ? null : (min ?? this.min),
        max: clearRange ? null : (max ?? this.max),
        step: clearRange ? null : (step ?? this.step),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (step != null) 'step': step,
      };

  factory MathVariable.fromJson(Map<String, dynamic> json) => MathVariable(
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        step: (json['step'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [name, value, min, max, step];
}
