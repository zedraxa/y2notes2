import 'dart:math';

import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

/// Weather widget with simulated data and interactive controls.
class WeatherWidget extends SmartWidget {
  WeatherWidget({
    super.id,
    super.position = Offset.zero,
    super.size = const Size(200, 180),
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) : super(
          type: SmartWidgetType.weather,
          config: config ??
              const {
                'location': 'Istanbul',
                'unit': 'C',
              },
          state: state ??
              const {
                'temp': 22,
                'high': 26,
                'low': 18,
                'condition': 'Sunny',
                'icon': '☀️',
                'humidity': 55,
                'forecast': <Map<String, dynamic>>[
                  {'day': 'Tue', 'icon': '⛅', 'high': 24, 'low': 17},
                  {'day': 'Wed', 'icon': '🌧️', 'high': 20, 'low': 15},
                  {'day': 'Thu', 'icon': '☀️', 'high': 27, 'low': 19},
                ],
              },
        );

  @override
  String get label => 'Weather';
  @override
  String get iconEmoji => '🌤️';

  @override
  SmartWidget copyWith({
    Offset? position,
    Size? size,
    Map<String, dynamic>? config,
    Map<String, dynamic>? state,
  }) =>
      WeatherWidget(
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
      _WeatherOverlay(
        widget: this,
        onStateChanged: onStateChanged,
      );
}

class _WeatherOverlay extends StatefulWidget {
  const _WeatherOverlay({
    required this.widget,
    required this.onStateChanged,
  });
  final WeatherWidget widget;
  final ValueChanged<Map<String, dynamic>> onStateChanged;

  @override
  State<_WeatherOverlay> createState() =>
      _WeatherOverlayState();
}

class _WeatherOverlayState
    extends State<_WeatherOverlay> {
  late String _unit;
  late int _temp;
  late int _high;
  late int _low;
  late String _condition;
  late String _icon;
  late int _humidity;
  late int _windSpeed;
  late int _feelsLike;
  late List<Map<String, dynamic>> _forecast;
  late String _location;
  bool _editingLocation = false;
  final _locationCtrl = TextEditingController();

  static const _conditions = [
    {'condition': 'Sunny', 'icon': '☀️'},
    {'condition': 'Partly Cloudy', 'icon': '⛅'},
    {'condition': 'Cloudy', 'icon': '☁️'},
    {'condition': 'Rainy', 'icon': '🌧️'},
    {'condition': 'Stormy', 'icon': '⛈️'},
    {'condition': 'Snowy', 'icon': '🌨️'},
    {'condition': 'Windy', 'icon': '💨'},
    {'condition': 'Foggy', 'icon': '🌫️'},
  ];

  static const _forecastDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.widget.state;
    final c = widget.widget.config;
    _unit = c['unit'] as String? ?? 'C';
    _location = c['location'] as String? ?? 'Istanbul';
    _temp = s['temp'] as int? ?? 22;
    _high = s['high'] as int? ?? 26;
    _low = s['low'] as int? ?? 18;
    _condition =
        s['condition'] as String? ?? 'Sunny';
    _icon = s['icon'] as String? ?? '☀️';
    _humidity = s['humidity'] as int? ?? 55;
    _windSpeed = s['windSpeed'] as int? ?? 12;
    _feelsLike = s['feelsLike'] as int? ?? _temp;
    _locationCtrl.text = _location;
    final rawForecast = s['forecast'] as List?;
    _forecast = rawForecast
            ?.map(
              (e) =>
                  Map<String, dynamic>.from(e as Map),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onStateChanged({
      'temp': _temp,
      'high': _high,
      'low': _low,
      'condition': _condition,
      'icon': _icon,
      'humidity': _humidity,
      'windSpeed': _windSpeed,
      'feelsLike': _feelsLike,
      'forecast': _forecast,
      '_config_unit': _unit,
      '_config_location': _location,
    });
  }

  void _refresh() {
    final rng = Random();
    final cond =
        _conditions[rng.nextInt(_conditions.length)];
    setState(() {
      _temp = rng.nextInt(20) + 10;
      _high = _temp + rng.nextInt(6) + 2;
      _low = _temp - rng.nextInt(6) - 2;
      _humidity = rng.nextInt(60) + 30;
      _windSpeed = rng.nextInt(40) + 5;
      _feelsLike = _temp + rng.nextInt(5) - 2;
      _condition = cond['condition']!;
      _icon = cond['icon']!;

      final todayIdx =
          DateTime.now().weekday - 1;
      _forecast = List.generate(3, (i) {
        final dayIdx =
            (todayIdx + i + 1) % 7;
        final fc = _conditions[
            rng.nextInt(_conditions.length)];
        return {
          'day': _forecastDays[dayIdx],
          'icon': fc['icon'],
          'high': rng.nextInt(15) + 15,
          'low': rng.nextInt(10) + 5,
        };
      });
    });
    _notify();
  }

  void _toggleUnit() {
    setState(() {
      if (_unit == 'C') {
        _unit = 'F';
        _temp = (_temp * 9 / 5 + 32).round();
        _high = (_high * 9 / 5 + 32).round();
        _low = (_low * 9 / 5 + 32).round();
        _feelsLike =
            (_feelsLike * 9 / 5 + 32).round();
        for (final f in _forecast) {
          f['high'] =
              ((f['high'] as int) * 9 / 5 + 32)
                  .round();
          f['low'] =
              ((f['low'] as int) * 9 / 5 + 32)
                  .round();
        }
      } else {
        _unit = 'C';
        _temp = ((_temp - 32) * 5 / 9).round();
        _high = ((_high - 32) * 5 / 9).round();
        _low = ((_low - 32) * 5 / 9).round();
        _feelsLike =
            ((_feelsLike - 32) * 5 / 9).round();
        for (final f in _forecast) {
          f['high'] =
              (((f['high'] as int) - 32) * 5 / 9)
                  .round();
          f['low'] =
              (((f['low'] as int) - 32) * 5 / 9)
                  .round();
        }
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              // Location + controls row
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 2),
                  if (_editingLocation)
                    SizedBox(
                      width: 80,
                      height: 18,
                      child: TextField(
                        controller: _locationCtrl,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey.shade600,
                        ),
                        decoration:
                            const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.zero,
                        ),
                        onSubmitted: (v) {
                          setState(() {
                            _location = v.isNotEmpty
                                ? v
                                : _location;
                            _editingLocation =
                                false;
                          });
                          _notify();
                          _refresh();
                        },
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(
                        () =>
                            _editingLocation = true,
                      ),
                      child: Text(
                        _location,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Unit toggle
                  GestureDetector(
                    onTap: _toggleUnit,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Text(
                        '°$_unit',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _refresh,
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Main weather display
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    _icon,
                    style: const TextStyle(
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_temp°$_unit',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        _condition,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Details row: High/Low/Humidity/Wind
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'H:$_high°',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'L:$_low°',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '💧$_humidity%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '💨$_windSpeed km/h',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              // Feels like
              if ((_feelsLike - _temp).abs() >= 2)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                  ),
                  child: Text(
                    'Feels like $_feelsLike°$_unit',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              // Forecast row
              if (_forecast.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: _forecast.map((f) {
                    return Column(
                      children: [
                        Text(
                          f['day'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                        Text(
                          f['icon']
                                  as String? ??
                              '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${f['high']}°'
                          '/${f['low']}°',
                          style: const TextStyle(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
}
