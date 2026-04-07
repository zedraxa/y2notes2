import 'package:equatable/equatable.dart';
import 'package:y2notes2/features/canvas/domain/entities/stroke.dart';
import 'package:y2notes2/features/canvas/domain/models/canvas_config.dart';
import 'package:y2notes2/features/documents/domain/models/export_options.dart';
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';

/// Base class for all document-feature events.
abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

// ── Notebook lifecycle ─────────────────────────────────────────────────────

/// Create a new blank notebook with the given title.
class CreateNotebook extends DocumentEvent {
  const CreateNotebook({required this.title});
  final String title;
  @override
  List<Object?> get props => [title];
}

/// Open an existing notebook by ID.
class OpenNotebook extends DocumentEvent {
  const OpenNotebook({required this.notebookId});
  final String notebookId;
  @override
  List<Object?> get props => [notebookId];
}

/// Close the current notebook.
class CloseNotebook extends DocumentEvent {
  const CloseNotebook();
}

// ── Page management ────────────────────────────────────────────────────────

/// Navigate to a specific page index.
class NavigateToPage extends DocumentEvent {
  const NavigateToPage({required this.pageIndex});
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

/// Insert a new blank page at [insertAfterIndex].
class AddPage extends DocumentEvent {
  const AddPage({this.insertAfterIndex});
  final int? insertAfterIndex;
  @override
  List<Object?> get props => [insertAfterIndex];
}

/// Remove the page at [pageIndex].
class DeletePage extends DocumentEvent {
  const DeletePage({required this.pageIndex});
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

/// Duplicate the page at [pageIndex].
class DuplicatePage extends DocumentEvent {
  const DuplicatePage({required this.pageIndex});
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

/// Move a page from [fromIndex] to [toIndex].
class MovePage extends DocumentEvent {
  const MovePage({required this.fromIndex, required this.toIndex});
  final int fromIndex;
  final int toIndex;
  @override
  List<Object?> get props => [fromIndex, toIndex];
}

/// Update the strokes for the current page.
class UpdatePageStrokes extends DocumentEvent {
  const UpdatePageStrokes({
    required this.pageIndex,
    required this.strokes,
  });
  final int pageIndex;
  final List<Stroke> strokes;
  @override
  List<Object?> get props => [pageIndex, strokes];
}

/// Update canvas config for a specific page.
class UpdatePageConfig extends DocumentEvent {
  const UpdatePageConfig({
    required this.pageIndex,
    required this.config,
  });
  final int pageIndex;
  final CanvasConfig config;
  @override
  List<Object?> get props => [pageIndex, config];
}

// ── PDF export ─────────────────────────────────────────────────────────────

/// Export the current page as PDF.
class ExportCurrentPageAsPdf extends DocumentEvent {
  const ExportCurrentPageAsPdf({this.options = const PdfExportOptions()});
  final PdfExportOptions options;
  @override
  List<Object?> get props => [options];
}

/// Export all pages of the notebook as a multi-page PDF.
class ExportNotebookAsPdf extends DocumentEvent {
  const ExportNotebookAsPdf({this.options = const PdfExportOptions()});
  final PdfExportOptions options;
  @override
  List<Object?> get props => [options];
}

/// Share the current page as PDF via the system share sheet.
class ShareCurrentPageAsPdf extends DocumentEvent {
  const ShareCurrentPageAsPdf({this.options = const PdfExportOptions()});
  final PdfExportOptions options;
  @override
  List<Object?> get props => [options];
}

// ── Image export ───────────────────────────────────────────────────────────

/// Export the current page as a PNG/JPEG image.
class ExportCurrentPageAsImage extends DocumentEvent {
  const ExportCurrentPageAsImage({
    this.options = const ImageExportOptions(),
  });
  final ImageExportOptions options;
  @override
  List<Object?> get props => [options];
}

// ── PDF import ─────────────────────────────────────────────────────────────

/// Open the file picker to select and import a PDF file.
class ImportPdf extends DocumentEvent {
  const ImportPdf({this.scale = 2.0});
  final double scale;
  @override
  List<Object?> get props => [scale];
}

/// Open the file picker to select and import an image.
class ImportImage extends DocumentEvent {
  const ImportImage({this.maxWidth, this.maxHeight});
  final double? maxWidth;
  final double? maxHeight;
  @override
  List<Object?> get props => [maxWidth, maxHeight];
}

/// Import pages from a completed document scan session.
class ImportScannedDocument extends DocumentEvent {
  const ImportScannedDocument({required this.scanResult});
  final ScanResult scanResult;
  @override
  List<Object?> get props => [scanResult];
}

// ── UI events ──────────────────────────────────────────────────────────────

/// Dismiss any active error or progress state.
class ClearDocumentStatus extends DocumentEvent {
  const ClearDocumentStatus();
}

// ── Notebook metadata ──────────────────────────────────────────────────────

/// Rename the current notebook.
class RenameNotebook extends DocumentEvent {
  const RenameNotebook({required this.title});
  final String title;
  @override
  List<Object?> get props => [title];
}

/// Update the notebook description.
class UpdateNotebookDescription extends DocumentEvent {
  const UpdateNotebookDescription({this.description});
  final String? description;
  @override
  List<Object?> get props => [description];
}

// ── Page metadata ──────────────────────────────────────────────────────────

/// Set or clear the title of the page at [pageIndex].
class UpdatePageTitle extends DocumentEvent {
  const UpdatePageTitle({required this.pageIndex, this.title});
  final int pageIndex;
  final String? title;
  @override
  List<Object?> get props => [pageIndex, title];
}

/// Toggle the bookmark state of the page at [pageIndex].
class TogglePageBookmark extends DocumentEvent {
  const TogglePageBookmark({required this.pageIndex});
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

// ── Page gesture navigation ────────────────────────────────────────────────

/// Navigate to the next page (if available).
class GoToNextPage extends DocumentEvent {
  const GoToNextPage();
}

/// Navigate to the previous page (if available).
class GoToPreviousPage extends DocumentEvent {
  const GoToPreviousPage();
}

// ── Outline panel ──────────────────────────────────────────────────────────

/// Toggle the outline/table-of-contents panel visibility.
class ToggleOutlinePanel extends DocumentEvent {
  const ToggleOutlinePanel();
}
