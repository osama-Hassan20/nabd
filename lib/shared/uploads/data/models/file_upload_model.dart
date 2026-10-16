import 'dart:typed_data';

enum FileUploadType { image, video, audio, custom }

/// Model representing a file to be uploaded
class FileUploadModel {
  final String? filePath;
  final Uint8List? fileBytes;
  final String fileName;
  final FileUploadType fileType;
  final String? mimeType;

  FileUploadModel({
    this.filePath,
    this.fileBytes,
    required this.fileName,
    required this.fileType,
    this.mimeType,
  });

  /// Check if the file is valid (has either path or bytes)
  bool get isValid => filePath != null || fileBytes != null;

  /// Get the file extension from the file name
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Get default mime type based on file type and extension
  String get resolvedMimeType {
    if (mimeType != null) return mimeType!;

    switch (fileType) {
      case FileUploadType.image:
        return _getImageMimeType(extension);
      case FileUploadType.video:
        return _getVideoMimeType(extension);
      case FileUploadType.audio:
        return _getAudioMimeType(extension);
      case FileUploadType.custom:
        return 'application/octet-stream';
    }
  }

  String _getImageMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _getVideoMimeType(String ext) {
    switch (ext) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  String _getAudioMimeType(String ext) {
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }
}

/// Result model for file upload
class FileUploadResult {
  final String? url;
  final String? fileName;
  final bool success;
  final String? errorMessage;

  FileUploadResult({
    this.url,
    this.fileName,
    this.success = false,
    this.errorMessage,
  });

  factory FileUploadResult.success({required String url, String? fileName}) {
    return FileUploadResult(url: url, fileName: fileName, success: true);
  }

  factory FileUploadResult.failure(String errorMessage) {
    return FileUploadResult(success: false, errorMessage: errorMessage);
  }
}

/// Result model for multiple file uploads
class MultiFileUploadResult {
  final List<FileUploadResult> results;
  final bool allSuccess;
  final int successCount;
  final int failureCount;

  MultiFileUploadResult({required this.results})
    : allSuccess = results.every((r) => r.success),
      successCount = results.where((r) => r.success).length,
      failureCount = results.where((r) => !r.success).length;

  List<String> get successUrls =>
      results.where((r) => r.success).map((r) => r.url!).toList();
}
