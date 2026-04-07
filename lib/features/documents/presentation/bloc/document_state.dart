import 'package:equatable/equatable.dart';
import 'package:biscuitse/features/documents/domain/entities/notebook.dart';

/// Status of an ongoing or completed export/import operation.
enum DocumentOperationStatus {
  idle,
  inProgress,
  success,
  error,
}

/// Immutable snapshot of the document feature state.
class DocumentState extends Equatable {
  const DocumentState({
    this.notebook,
    this.currentPageIndex = 0,
    this.status = DocumentOperationStatus.idle,
    this.exportProgress = 0.0,
    this.importProgress = 0.0,
    this.lastExportPath,
    this.errorMessage,
    this.isExporting = false,
    this.isImporting = false,
  });

  /// The currently open notebook, or `null` when none is open.
  final Notebook? notebook;

  /// Zero-based index of the visible page.
  final int currentPageIndex;

  /// Status of the latest export/import operation.
  final DocumentOperationStatus status;

  /// Progress value 0.0–1.0 during an export.
  final double exportProgress;

  /// Progress value 0.0–1.0 during an import.
  final double importProgress;

  /// File path of the most recently saved export.
  final String? lastExportPath;

  /// Human-readable error message if [status] is [DocumentOperationStatus.error].
  final String? errorMessage;

  final bool isExporting;
  final bool isImporting;

  bool get hasNotebook => notebook != null;

  int get pageCount => notebook?.pageCount ?? 0;

  bool get canGoBack => currentPageIndex > 0;
  bool get canGoForward => currentPageIndex < pageCount - 1;

  DocumentState copyWith({
    Notebook? notebook,
    bool clearNotebook = false,
    int? currentPageIndex,
    DocumentOperationStatus? status,
    double? exportProgress,
    double? importProgress,
    String? lastExportPath,
    bool clearLastExportPath = false,
    String? errorMessage,
    bool clearError = false,
    bool? isExporting,
    bool? isImporting,
  }) =>
      DocumentState(
        notebook: clearNotebook ? null : (notebook ?? this.notebook),
        currentPageIndex: currentPageIndex ?? this.currentPageIndex,
        status: status ?? this.status,
        exportProgress: exportProgress ?? this.exportProgress,
        importProgress: importProgress ?? this.importProgress,
        lastExportPath: clearLastExportPath
            ? null
            : (lastExportPath ?? this.lastExportPath),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isExporting: isExporting ?? this.isExporting,
        isImporting: isImporting ?? this.isImporting,
      );

  @override
  List<Object?> get props => [
        notebook,
        currentPageIndex,
        status,
        exportProgress,
        importProgress,
        lastExportPath,
        errorMessage,
        isExporting,
        isImporting,
      ];
}
