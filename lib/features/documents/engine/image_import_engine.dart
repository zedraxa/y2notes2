import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:biscuitse/features/documents/domain/entities/import_result.dart';

/// Handles importing image files (PNG, JPEG, HEIC) from the device and
/// converting them into canvas-ready [ImportedPage] objects.
class ImageImportEngine {
  const ImageImportEngine();

  // ── File picking ────────────────────────────────────────────────────────────

  /// Opens the system file picker for image files and returns the selected
  /// path, or `null` if the user cancelled.
  Future<String?> pickImageFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.singleOrNull?.path;
  }

  /// Opens the file picker allowing multiple images to be selected.
  Future<List<String>> pickMultipleImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    return result?.files
            .map((f) => f.path)
            .whereType<String>()
            .toList() ??
        [];
  }

  // ── Image loading & resizing ────────────────────────────────────────────────

  /// Loads an image from [filePath] and optionally resizes it to fit within
  /// [maxWidth] × [maxHeight] while preserving aspect ratio.
  Future<ui.Image> loadImage(
    String filePath, {
    double? maxWidth,
    double? maxHeight,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw FormatException('Cannot decode image: $filePath');
    }

    // Optionally scale down to fit the canvas.
    if (maxWidth != null || maxHeight != null) {
      final targetW = maxWidth ?? decoded.width.toDouble();
      final targetH = maxHeight ?? decoded.height.toDouble();
      final scaleX = targetW / decoded.width;
      final scaleY = targetH / decoded.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      if (scale < 1.0) {
        decoded = img.copyResize(
          decoded,
          width: (decoded.width * scale).round(),
          height: (decoded.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // Convert to ui.Image via PNG bytes.
    final pngBytes = img.encodePng(decoded);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(pngBytes),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Crops the decoded image to [cropRect] before returning.
  Future<ui.Image> loadAndCrop(
    String filePath,
    Rect cropRect,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw FormatException('Cannot decode image: $filePath');
    }
    final cropped = img.copyCrop(
      decoded,
      x: cropRect.left.round(),
      y: cropRect.top.round(),
      width: cropRect.width.round(),
      height: cropRect.height.round(),
    );
    final pngBytes = img.encodePng(cropped);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(pngBytes),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ── Public import API ───────────────────────────────────────────────────────

  /// Imports an image from [filePath] as a single [ImportedPage].
  Future<ImportedPage> importImage(
    String filePath, {
    double? maxWidth,
    double? maxHeight,
  }) async {
    final image = await loadImage(
      filePath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    final fileName = filePath.split(Platform.pathSeparator).last;
    return ImportedPage(
      pageNumber: 1,
      width: image.width.toDouble(),
      height: image.height.toDouble(),
      renderedImage: image,
      sourcePath: filePath,
    );
  }

  /// Opens the file picker and imports the chosen image.
  /// Returns `null` if the user cancelled.
  Future<ImportResult?> pickAndImport({
    double? maxWidth,
    double? maxHeight,
  }) async {
    final path = await pickImageFile();
    if (path == null) return null;

    final page = await importImage(path, maxWidth: maxWidth, maxHeight: maxHeight);
    final fileName = path.split(Platform.pathSeparator).last;
    return ImportResult(
      pages: [page],
      sourcePath: path,
      importedAt: DateTime.now(),
      title: fileName,
    );
  }

  /// Saves image bytes to the application documents directory.
  Future<String> saveToFile({
    required Uint8List bytes,
    String fileName = 'biscuitse_import',
    String extension = 'png',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.$extension');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
