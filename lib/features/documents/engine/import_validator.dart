import 'dart:io';

import 'package:y2notes2/features/documents/domain/models/import_options.dart';

/// Shared validation utilities for import engines.
class ImportValidator {
  const ImportValidator._();

  /// Supported PDF file extensions.
  static const pdfExtensions = ['pdf'];

  /// Supported image file extensions.
  static const imageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tiff',
    'tif',
  ];

  /// All supported import file extensions.
  static const allExtensions = [...pdfExtensions, ...imageExtensions];

  /// Validates a file at [filePath] against the given [options].
  ///
  /// Throws [FileTooLargeException] if the file exceeds the size limit.
  /// Throws [UnsupportedImportFormatException] if the extension is not
  /// in [allowedExtensions].
  /// Throws [FileSystemException] if the file doesn't exist.
  static Future<void> validate(
    String filePath, {
    required List<String> allowedExtensions,
    int? maxFileSizeBytes,
  }) async {
    final file = File(filePath);

    // Existence check.
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    // Extension check.
    final ext = _extension(filePath);
    if (!allowedExtensions.contains(ext)) {
      throw UnsupportedImportFormatException(ext, allowedExtensions);
    }

    // Size check.
    if (maxFileSizeBytes != null) {
      final size = await file.length();
      if (size > maxFileSizeBytes) {
        throw FileTooLargeException(size, maxFileSizeBytes);
      }
    }
  }

  /// Extracts the lowercase file extension without the leading dot.
  static String _extension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }

  /// Returns a human-readable file size string.
  static String humanFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
