/// Configuration options for import operations.
///
/// Used by [ImportPdf], [ImportImage], and [ImportMultipleImages] events
/// to control how files are imported into the notebook.
class ImportOptions {
  const ImportOptions({
    this.mode = ImportMode.newNotebook,
    this.scale = 2.0,
    this.maxWidth,
    this.maxHeight,
    this.pageRange,
    this.maxFileSizeBytes,
  });

  /// Whether to create a new notebook or append pages to the current one.
  final ImportMode mode;

  /// Pixel density multiplier for PDF rasterisation (default 2.0).
  final double scale;

  /// Maximum width constraint for imported images.
  final double? maxWidth;

  /// Maximum height constraint for imported images.
  final double? maxHeight;

  /// Optional page range for PDF imports (1-based, inclusive).
  /// When `null`, all pages are imported.
  final PageRange? pageRange;

  /// Optional maximum file size in bytes. Files exceeding this limit
  /// will be rejected with a [FileTooLargeException].
  final int? maxFileSizeBytes;

  ImportOptions copyWith({
    ImportMode? mode,
    double? scale,
    double? maxWidth,
    double? maxHeight,
    PageRange? pageRange,
    bool clearPageRange = false,
    int? maxFileSizeBytes,
    bool clearMaxFileSize = false,
  }) =>
      ImportOptions(
        mode: mode ?? this.mode,
        scale: scale ?? this.scale,
        maxWidth: maxWidth ?? this.maxWidth,
        maxHeight: maxHeight ?? this.maxHeight,
        pageRange: clearPageRange ? null : (pageRange ?? this.pageRange),
        maxFileSizeBytes:
            clearMaxFileSize ? null : (maxFileSizeBytes ?? this.maxFileSizeBytes),
      );
}

/// Determines how imported pages are added.
enum ImportMode {
  /// Create a brand new notebook from the imported content.
  newNotebook,

  /// Append imported pages to the currently open notebook.
  appendToCurrentNotebook,
}

/// Inclusive, 1-based page range for selective PDF imports.
class PageRange {
  const PageRange({required this.start, required this.end});

  /// First page to import (1-based).
  final int start;

  /// Last page to import (1-based, inclusive).
  final int end;

  /// Number of pages in this range.
  int get count => (end - start + 1).clamp(0, 9999);

  /// Returns `true` if [pageNumber] (1-based) falls within this range.
  bool contains(int pageNumber) => pageNumber >= start && pageNumber <= end;

  @override
  String toString() => 'PageRange($start–$end)';
}

/// Thrown when an import file exceeds [ImportOptions.maxFileSizeBytes].
class FileTooLargeException implements Exception {
  const FileTooLargeException(this.fileSize, this.maxSize);

  final int fileSize;
  final int maxSize;

  @override
  String toString() =>
      'FileTooLargeException: File is ${_humanSize(fileSize)}, '
      'max allowed is ${_humanSize(maxSize)}.';

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Thrown when an import file has an unsupported format.
class UnsupportedImportFormatException implements Exception {
  const UnsupportedImportFormatException(this.extension, this.supportedExtensions);

  final String extension;
  final List<String> supportedExtensions;

  @override
  String toString() =>
      'UnsupportedImportFormatException: ".$extension" is not supported. '
      'Supported formats: ${supportedExtensions.map((e) => '.$e').join(', ')}.';
}
