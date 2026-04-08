import 'package:equatable/equatable.dart';
import 'package:biscuits/features/widgets/domain/entities/smart_widget.dart';

class WidgetState extends Equatable {
  const WidgetState({
    this.widgets = const [],
    this.selectedWidgetId,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  final List<SmartWidget> widgets;
  final String? selectedWidgetId;
  final List<List<SmartWidget>> undoStack;
  final List<List<SmartWidget>> redoStack;

  SmartWidget? get selectedWidget => selectedWidgetId == null
      ? null
      : widgets.where((w) => w.id == selectedWidgetId).firstOrNull;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  WidgetState copyWith({
    List<SmartWidget>? widgets,
    Object? selectedWidgetId = _sentinel,
    List<List<SmartWidget>>? undoStack,
    List<List<SmartWidget>>? redoStack,
  }) =>
      WidgetState(
        widgets: widgets ?? this.widgets,
        selectedWidgetId: selectedWidgetId == _sentinel
            ? this.selectedWidgetId
            : selectedWidgetId as String?,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
      );

  @override
  List<Object?> get props => [widgets, selectedWidgetId, undoStack, redoStack];
}

const _sentinel = Object();
