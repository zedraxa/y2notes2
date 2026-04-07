import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// A single captured pointer sample from a stylus or finger.
///
/// Extended with full stylus axis data required for the cross-platform stylus
/// engine (PR 7).  All new fields are optional with sensible defaults so that
/// existing code that constructs [PointData] without them continues to compile.
class PointData extends Equatable {
  const PointData({
    required this.x,
    required this.y,
    required this.pressure,
    required this.tilt,
    required this.velocity,
    required this.timestamp,
    this.azimuth = 0.0,
    this.altitude = math.pi / 2,
    this.hoverDistance = 0.0,
  });

  final double x;
  final double y;

  /// Normalized pressure value in range [0.0, 1.0].
  final double pressure;

  /// Stylus tilt / altitude angle in radians (0 = flat, π/2 = perpendicular).
  final double tilt;

  /// Instantaneous velocity (px/ms), calculated from successive timestamps.
  final double velocity;

  /// Epoch timestamp in milliseconds.
  final int timestamp;

  /// Azimuth — pen rotation around its own axis, in radians [0, 2π).
  /// 0 = pointing towards top of screen.  Defaults to 0.0.
  final double azimuth;

  /// Altitude angle — same as [tilt] but kept separately to avoid ambiguity.
  /// 0 = pen lying flat, π/2 = pen perpendicular to screen.  Defaults to π/2.
  final double altitude;

  /// Hover distance in logical pixels.  0.0 = pen is touching the screen.
  /// Values > 0 indicate the pen is hovering above the surface.
  final double hoverDistance;

  PointData copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tilt,
    double? velocity,
    int? timestamp,
    double? azimuth,
    double? altitude,
    double? hoverDistance,
  }) =>
      PointData(
        x: x ?? this.x,
        y: y ?? this.y,
        pressure: pressure ?? this.pressure,
        tilt: tilt ?? this.tilt,
        velocity: velocity ?? this.velocity,
        timestamp: timestamp ?? this.timestamp,
        azimuth: azimuth ?? this.azimuth,
        altitude: altitude ?? this.altitude,
        hoverDistance: hoverDistance ?? this.hoverDistance,
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
        'tilt': tilt,
        'velocity': velocity,
        'timestamp': timestamp,
        'azimuth': azimuth,
        'altitude': altitude,
        'hoverDistance': hoverDistance,
      };

  factory PointData.fromJson(Map<String, dynamic> json) => PointData(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['pressure'] as num).toDouble(),
        tilt: (json['tilt'] as num).toDouble(),
        velocity: (json['velocity'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
        azimuth: (json['azimuth'] as num?)?.toDouble() ?? 0.0,
        altitude:
            (json['altitude'] as num?)?.toDouble() ?? math.pi / 2,
        hoverDistance:
            (json['hoverDistance'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props =>
      [x, y, pressure, tilt, velocity, timestamp, azimuth, altitude, hoverDistance];
}
