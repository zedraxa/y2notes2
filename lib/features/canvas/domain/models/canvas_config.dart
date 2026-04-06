import 'package:equatable/equatable.dart';
import 'package:y2notes2/core/constants/app_constants.dart';

/// Page background template types.
enum PageTemplate { blank, lined, grid, dotted, chalkboard }

/// Immutable configuration for a canvas page.
class CanvasConfig extends Equatable {
  const CanvasConfig({
    this.width = AppConstants.defaultPageWidth,
    this.height = AppConstants.defaultPageHeight,
    this.template = PageTemplate.lined,
    this.lineSpacing = 32.0,
    this.gridSpacing = 32.0,
    this.dotSpacing = 32.0,
    this.showMargin = true,
  });

  final double width;
  final double height;
  final PageTemplate template;
  final double lineSpacing;
  final double gridSpacing;
  final double dotSpacing;
  final bool showMargin;

  CanvasConfig copyWith({
    double? width,
    double? height,
    PageTemplate? template,
    double? lineSpacing,
    double? gridSpacing,
    double? dotSpacing,
    bool? showMargin,
  }) =>
      CanvasConfig(
        width: width ?? this.width,
        height: height ?? this.height,
        template: template ?? this.template,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        gridSpacing: gridSpacing ?? this.gridSpacing,
        dotSpacing: dotSpacing ?? this.dotSpacing,
        showMargin: showMargin ?? this.showMargin,
      );

  @override
  List<Object?> get props => [
        width,
        height,
        template,
        lineSpacing,
        gridSpacing,
        dotSpacing,
        showMargin,
      ];
}
