// ignore_for_file: one_member_abstracts
// Stub implementations of dart:io types used in this project.
//
// This file is imported via conditional imports on platforms where dart:io
// is unavailable (e.g. web). All operations are no-ops or return safe
// default values so the code compiles and the relevant features degrade
// gracefully.

import 'dart:typed_data';

/// Stub for [dart:io File].
class File {
  const File(this.path);

  final String path;

  Future<bool> exists() async => false;

  Future<int> length() async => 0;

  int lengthSync() => 0;

  Future<Uint8List> readAsBytes() async => Uint8List(0);

  Uint8List readAsBytesSync() => Uint8List(0);

  Future<File> writeAsBytes(
    List<int> bytes, {
    bool flush = false,
  }) async =>
      this;

  Future<File> delete({bool recursive = false}) async => this;
}

/// Stub for [dart:io Directory].
class Directory {
  const Directory(this.path);

  final String path;
}

/// Stub for [dart:io Platform] — only the subset used in this project.
abstract class Platform {
  Platform._();

  /// On web paths always use forward slash.
  static const String pathSeparator = '/';
}

/// Stub for [dart:io FileSystemException].
class FileSystemException implements Exception {
  const FileSystemException([this.message = '', this.path]);

  final String message;
  final String? path;

  @override
  String toString() =>
      'FileSystemException: $message${path != null ? ', path: $path' : ''}';
}
