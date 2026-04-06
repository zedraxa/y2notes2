import 'package:equatable/equatable.dart';

/// A single captured pointer sample from a stylus or finger.
class PointData extends Equatable {
  const PointData({
    required this.x,
    required this.y,
    required this.pressure,
    required this.tilt,
    required this.velocity,
    required this.timestamp,
  });

  final double x;
  final double y;

  /// Normalised pressure value in range [0.0, 1.0].
  final double pressure;

  /// Stylus tilt angle in radians.
  final double tilt;

  /// Instantaneous velocity (px/ms), calculated from successive timestamps.
  final double velocity;

  /// Epoch timestamp in milliseconds.
  final int timestamp;

  PointData copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tilt,
    double? velocity,
    int? timestamp,
  }) =>
      PointData(
        x: x ?? this.x,
        y: y ?? this.y,
        pressure: pressure ?? this.pressure,
        tilt: tilt ?? this.tilt,
        velocity: velocity ?? this.velocity,
        timestamp: timestamp ?? this.timestamp,
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
        'tilt': tilt,
        'velocity': velocity,
        'timestamp': timestamp,
      };

  factory PointData.fromJson(Map<String, dynamic> json) => PointData(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['pressure'] as num).toDouble(),
        tilt: (json['tilt'] as num).toDouble(),
        velocity: (json['velocity'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
      );

  @override
  List<Object?> get props => [x, y, pressure, tilt, velocity, timestamp];
}
