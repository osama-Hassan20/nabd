import 'dart:typed_data';

enum MediaSourceType { file, network }

enum MediaCategory { image, video, audio, document }

class MediaModel {
  final MediaSourceType type;
  final String path;
  final MediaCategory category;
  final String? fileName;
  final int? fileSize; // in bytes
  final Uint8List? fileBytes;
  final String? mimeType;
  final bool isDeleted;

  MediaModel({
    required this.type,
    required this.path,
    required this.category,
    this.fileName,
    this.fileSize,
    this.fileBytes,
    this.mimeType,
    this.isDeleted = false,
  });

  factory MediaModel.fromNetwork(
    String path, {
    required MediaCategory category,
    String? fileName,
    int? fileSize,
  }) {
    return MediaModel(
      type: MediaSourceType.network,
      path: path,
      category: category,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  MediaModel copyWith({
    MediaSourceType? type,
    String? path,
    MediaCategory? category,
    String? fileName,
    int? fileSize,
    Uint8List? fileBytes,
    String? mimeType,
    bool? isDeleted,
  }) {
    return MediaModel(
      type: type ?? this.type,
      path: path ?? this.path,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileBytes: fileBytes ?? this.fileBytes,
      mimeType: mimeType ?? this.mimeType,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String get displayName {
    if (fileName != null) return fileName!;
    return path.split('/').last;
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool get isFile => type == MediaSourceType.file;
  bool get isNetwork => type == MediaSourceType.network;

  bool get isValid => path.isNotEmpty || fileBytes != null;

  String get extension {
    final name = fileName ?? path;
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
