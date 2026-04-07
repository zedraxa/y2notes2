import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';
import 'package:y2notes2/features/scanner/domain/models/scanner_options.dart';

/// The processing phase of the scanner workflow.
enum ScannerPhase {
  /// Idle — no active scan session.
  idle,

  /// Camera is active, ready to capture.
  capturing,

  /// Image has been captured; showing edge detection
  /// overlay for manual adjustment.
  adjusting,

  /// Image is being processed (perspective, filter, etc.).
  processing,

  /// Showing the processed result for review.
  reviewing,

  /// OCR is running.
  ocrInProgress,

  /// Scan session complete — results ready to import.
  completed,

  /// An error occurred during processing.
  error,
}

/// Immutable state for the document scanner.
class ScannerState extends Equatable {
  const ScannerState({
    this.phase = ScannerPhase.idle,
    this.options = const ScannerOptions(),
    this.currentPage,
    this.confirmedPages = const [],
    this.processingProgress = 0.0,
    this.scanResult,
    this.errorMessage,
  });

  final ScannerPhase phase;
  final ScannerOptions options;

  /// The page currently being processed or reviewed.
  final ScannedPage? currentPage;

  /// Pages that the user has already confirmed.
  final List<ScannedPage> confirmedPages;

  /// Progress of the current processing operation (0–1).
  final double processingProgress;

  /// Final scan result when session is completed.
  final ScanResult? scanResult;

  /// Error message when [phase] is [ScannerPhase.error].
  final String? errorMessage;

  int get totalPages => confirmedPages.length;

  bool get hasCurrentPage => currentPage != null;

  bool get isProcessing =>
      phase == ScannerPhase.processing ||
      phase == ScannerPhase.ocrInProgress;

  ScannerState copyWith({
    ScannerPhase? phase,
    ScannerOptions? options,
    ScannedPage? currentPage,
    bool clearCurrentPage = false,
    List<ScannedPage>? confirmedPages,
    double? processingProgress,
    ScanResult? scanResult,
    bool clearScanResult = false,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        options: options ?? this.options,
        currentPage: clearCurrentPage
            ? null
            : (currentPage ?? this.currentPage),
        confirmedPages:
            confirmedPages ?? this.confirmedPages,
        processingProgress:
            processingProgress ?? this.processingProgress,
        scanResult: clearScanResult
            ? null
            : (scanResult ?? this.scanResult),
        errorMessage: clearError
            ? null
            : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        phase,
        options,
        currentPage,
        confirmedPages,
        processingProgress,
        scanResult,
        errorMessage,
      ];
}
