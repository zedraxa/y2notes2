import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:biscuits/features/scanner/domain/entities/scanned_document.dart';
import 'package:biscuits/features/scanner/domain/models/scanner_options.dart';

/// Base class for scanner events.
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new scan session.
class ScannerSessionStarted extends ScannerEvent {
  const ScannerSessionStarted({
    this.options = const ScannerOptions(),
  });
  final ScannerOptions options;

  @override
  List<Object?> get props => [options];
}

/// An image was captured from the camera or picked from
/// gallery.
class ImageCaptured extends ScannerEvent {
  const ImageCaptured({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  List<Object?> get props => [imageBytes];
}

/// User manually adjusted the document corner positions.
class CornersAdjusted extends ScannerEvent {
  const CornersAdjusted({required this.corners});
  final List<ui.Offset> corners;

  @override
  List<Object?> get props => [corners];
}

/// Apply a colour/contrast filter to the current page.
class FilterChanged extends ScannerEvent {
  const FilterChanged({required this.filter});
  final ScannerFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Re-process the current page (after corner adjustment or
/// filter change).
class ReprocessCurrentPage extends ScannerEvent {
  const ReprocessCurrentPage();
}

/// Run OCR on the current page.
class OcrRequested extends ScannerEvent {
  const OcrRequested();
}

/// Confirm the current page and add it to the scan batch.
class PageConfirmed extends ScannerEvent {
  const PageConfirmed();
}

/// Remove a page from the scan batch.
class PageRemoved extends ScannerEvent {
  const PageRemoved({required this.pageIndex});
  final int pageIndex;

  @override
  List<Object?> get props => [pageIndex];
}

/// Finish the scan session and return results.
class ScannerSessionCompleted extends ScannerEvent {
  const ScannerSessionCompleted({this.title});
  final String? title;

  @override
  List<Object?> get props => [title];
}

/// Discard the scan session.
class ScannerSessionCancelled extends ScannerEvent {
  const ScannerSessionCancelled();
}
