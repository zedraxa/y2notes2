import 'package:equatable/equatable.dart';

enum LanguageModelStatus { available, downloading, notDownloaded, error }

class LanguageModel extends Equatable {
  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    this.status = LanguageModelStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.sizeBytes = 0,
  });

  final String code; // BCP 47 code, e.g., 'en-US'
  final String name; // English name
  final String nativeName; // Native name
  final LanguageModelStatus status;
  final double downloadProgress; // 0.0–1.0
  final int sizeBytes;

  bool get isReady => status == LanguageModelStatus.available;

  LanguageModel copyWith({
    LanguageModelStatus? status,
    double? downloadProgress,
  }) =>
      LanguageModel(
        code: code,
        name: name,
        nativeName: nativeName,
        status: status ?? this.status,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        sizeBytes: sizeBytes,
      );

  static const builtIn = LanguageModel(
    code: 'en-US',
    name: 'English (US)',
    nativeName: 'English',
    status: LanguageModelStatus.available,
    sizeBytes: 0,
  );

  @override
  List<Object?> get props => [code, name, status, downloadProgress];
}
