import 'package:equatable/equatable.dart';

/// Type of file that was imported.
enum ImportFileType { pdf, image }

/// A record of a completed import operation, used for import history tracking.
class ImportHistoryEntry extends Equatable {
  const ImportHistoryEntry({
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.importedAt,
    required this.pageCount,
    this.fileSizeBytes,
    this.thumbnailPath,
  });

  /// Display name of the imported file.
  final String fileName;

  /// Full path to the original imported file.
  final String filePath;

  /// Type of imported file.
  final ImportFileType fileType;

  /// Timestamp when the import completed.
  final DateTime importedAt;

  /// Number of pages created from the import.
  final int pageCount;

  /// Size of the original file in bytes, if known.
  final int? fileSizeBytes;

  /// Optional thumbnail path for quick preview.
  final String? thumbnailPath;

  /// Human-readable elapsed-time description (e.g. "2 min ago").
  String get timeAgo {
    final diff = DateTime.now().difference(importedAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${importedAt.month}/${importedAt.day}/${importedAt.year}';
  }

  @override
  List<Object?> get props => [
        fileName,
        filePath,
        fileType,
        importedAt,
        pageCount,
        fileSizeBytes,
      ];
}
