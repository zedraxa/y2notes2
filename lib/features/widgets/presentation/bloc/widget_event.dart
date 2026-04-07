import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:y2notes2/features/widgets/domain/entities/smart_widget.dart';

abstract class WidgetEvent extends Equatable {
  const WidgetEvent();
}

class WidgetsLoaded extends WidgetEvent {
  const WidgetsLoaded();
  @override
  List<Object?> get props => [];
}

class WidgetAdded extends WidgetEvent {
  const WidgetAdded(this.widget);
  final SmartWidget widget;
  @override
  List<Object?> get props => [widget];
}

class WidgetRemoved extends WidgetEvent {
  const WidgetRemoved(this.widgetId);
  final String widgetId;
  @override
  List<Object?> get props => [widgetId];
}

class WidgetUpdated extends WidgetEvent {
  const WidgetUpdated(this.widget);
  final SmartWidget widget;
  @override
  List<Object?> get props => [widget];
}

class WidgetMoved extends WidgetEvent {
  const WidgetMoved(this.widgetId, this.position);
  final String widgetId;
  final Offset position;
  @override
  List<Object?> get props => [widgetId, position];
}

class WidgetResized extends WidgetEvent {
  const WidgetResized(this.widgetId, this.size);
  final String widgetId;
  final Size size;
  @override
  List<Object?> get props => [widgetId, size];
}

class WidgetTapped extends WidgetEvent {
  const WidgetTapped(this.widgetId);
  final String widgetId;
  @override
  List<Object?> get props => [widgetId];
}

class WidgetLongPressed extends WidgetEvent {
  const WidgetLongPressed(this.widgetId);
  final String widgetId;
  @override
  List<Object?> get props => [widgetId];
}

class WidgetStateChanged extends WidgetEvent {
  const WidgetStateChanged(this.widgetId, this.newState);
  final String widgetId;
  final Map<String, dynamic> newState;
  @override
  List<Object?> get props => [widgetId, newState];
}

class WidgetDeselected extends WidgetEvent {
  const WidgetDeselected();
  @override
  List<Object?> get props => [];
}

class WidgetUndoRequested extends WidgetEvent {
  const WidgetUndoRequested();
  @override
  List<Object?> get props => [];
}

class WidgetRedoRequested extends WidgetEvent {
  const WidgetRedoRequested();
  @override
  List<Object?> get props => [];
}
