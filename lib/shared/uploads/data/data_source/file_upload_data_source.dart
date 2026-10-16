import 'dart:io';

import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/end_points.dart';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/shared/uploads/data/models/file_upload_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

abstract class FileUploadDataSource {
  /// Upload a single file to server with optional compression for images
  Future<FileUploadResult> uploadFile(
    MediaModel file, {
    int maxWidth = 1920,
    int quality = 85,
  });

  /// Upload multiple files to server
  Future<MultiFileUploadResult> uploadMultipleFiles(
    List<MediaModel> files, {
    int maxWidth = 1920,
    int quality = 85,
  });
}

class FileUploadDataSourceImpl implements FileUploadDataSource {
  final ApiConsumer apiServices;

  FileUploadDataSourceImpl({required this.apiServices});

  @override
  Future<FileUploadResult> uploadFile(
    MediaModel file, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      if (!file.isValid) {
        return FileUploadResult.failure('Invalid file: no path or bytes');
      }

      MediaModel fileToUpload = file;

      // Compress if it's an image and it's a file type
      if (file.category == MediaCategory.image && file.isFile) {
        final compressed = await _processImage(file, maxWidth, quality);
        if (compressed != null) {
          fileToUpload = compressed;
        }
      }

      late MultipartFile multipartFile;

      if (fileToUpload.fileBytes != null) {
        multipartFile = MultipartFile.fromBytes(
          fileToUpload.fileBytes!,
          filename: fileToUpload.fileName,
          contentType: MediaType.parse(_getMimeType(fileToUpload)),
        );
      } else if (fileToUpload.path.isNotEmpty) {
        multipartFile = await MultipartFile.fromFile(
          fileToUpload.path,
          filename: fileToUpload.fileName,
          contentType: MediaType.parse(_getMimeType(fileToUpload)),
        );
      } else {
        return FileUploadResult.failure('No file data available');
      }

      String key = 'image';
      String endPoint = EndPoints.uploadImage;

      final formData = FormData.fromMap({key: multipartFile});

      final response = await apiServices.post(path: endPoint, body: formData);

      final url = response['fileName'] ?? response['path'];
      return FileUploadResult.success(
        url: url.toString(),
        fileName: fileToUpload.fileName,
      );
    } catch (e) {
      return FileUploadResult.failure(e.toString());
    }
  }

  @override
  Future<MultiFileUploadResult> uploadMultipleFiles(
    List<MediaModel> files, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    final List<FileUploadResult> results = [];

    for (final file in files) {
      final result = await uploadFile(
        file,
        maxWidth: maxWidth,
        quality: quality,
      );
      results.add(result);
    }

    return MultiFileUploadResult(results: results);
  }

  /// Process and compress image data
  Future<MediaModel?> _processImage(
    MediaModel mediaModel,
    int maxWidth,
    int quality,
  ) async {
    try {
      Uint8List? imageBytes;
      String? filePath;

      Uint8List? originalBytes;
      if (mediaModel.fileBytes != null) {
        originalBytes = mediaModel.fileBytes;
      } else if (mediaModel.path.isNotEmpty) {
        originalBytes = await File(mediaModel.path).readAsBytes();
      }

      if (originalBytes == null) return null;

      debugPrint(
        'Original image size: ${(originalBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Resolve mime type before compressing
      final resolvedMime = mediaModel.mimeType ?? _getMimeType(mediaModel);

      final compressed = await _compressImageBytes(
        originalBytes,
        maxWidth,
        quality,
        resolvedMime,
      );
      if (compressed == null) return null;

      debugPrint(
        'Compressed image size: ${(compressed.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      imageBytes = compressed;

      // Determine output format info
      final isPng = resolvedMime == 'image/png';
      final isGif = resolvedMime == 'image/gif';
      final ext = isPng
          ? 'png'
          : isGif
          ? 'gif'
          : 'jpg';
      final outputMime = isPng
          ? 'image/png'
          : isGif
          ? 'image/gif'
          : 'image/jpeg';
      final fileName =
          'image_${DateTime.now().millisecondsSinceEpoch}_compressed.$ext';

      if (!kIsWeb) {
        // Save compressed file to temp directory for non-web platforms
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(imageBytes);
        filePath = tempFile.path;
      }

      return mediaModel.copyWith(
        path: filePath ?? mediaModel.path,
        fileBytes: imageBytes,
        fileName: fileName,
        mimeType: outputMime,
      );
    } catch (e) {
      debugPrint('Error processing image for upload: $e');
      return null;
    }
  }

  /// Compress image bytes
  Future<Uint8List?> _compressImageBytes(
    Uint8List bytes,
    int maxWidth,
    int quality,
    String mimeType,
  ) async {
    try {
      return await compute(
        _isolateCompress,
        _CompressionParams(bytes, maxWidth, quality, mimeType),
      );
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  String _getMimeType(MediaModel file) {
    if (file.mimeType != null) return file.mimeType!;

    final ext = file.extension;
    switch (file.category) {
      case MediaCategory.image:
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
      case MediaCategory.video:
        switch (ext) {
          case 'mp4':
            return 'video/mp4';
          case 'mov':
            return 'video/quicktime';
          case 'avi':
            return 'video/x-msvideo';
          default:
            return 'video/mp4';
        }
      case MediaCategory.audio:
        switch (ext) {
          case 'mp3':
            return 'audio/mpeg';
          case 'wav':
            return 'audio/wav';
          case 'aac':
            return 'audio/aac';
          case 'm4a':
            return 'audio/mp4';
          default:
            return 'audio/mpeg';
        }
      case MediaCategory.document:
        switch (ext) {
          case 'pdf':
            return 'application/pdf';
          case 'doc':
          case 'docx':
            return 'application/msword';
          case 'xls':
          case 'xlsx':
            return 'application/vnd.ms-excel';
          case 'txt':
            return 'text/plain';
          default:
            return 'application/octet-stream';
        }
    }
  }
}

class _CompressionParams {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
  final String mimeType;

  _CompressionParams(this.bytes, this.maxWidth, this.quality, this.mimeType);
}

Future<Uint8List?> _isolateCompress(_CompressionParams params) async {
  try {
    final decoded = img.decodeImage(params.bytes);
    if (decoded == null) return null;

    img.Image imageToProcess = decoded;
    if (decoded.width > params.maxWidth) {
      imageToProcess = img.copyResize(
        decoded,
        width: params.maxWidth,
        interpolation: img.Interpolation.linear,
      );
    }

    // Preserve original format to avoid white background on transparent images
    switch (params.mimeType) {
      case 'image/png':
        return Uint8List.fromList(img.encodePng(imageToProcess));
      case 'image/gif':
        return Uint8List.fromList(img.encodeGif(imageToProcess));
      case 'image/webp':
      case 'image/jpeg':
      case 'image/jpg':
      default:
        return Uint8List.fromList(
          img.encodeJpg(imageToProcess, quality: params.quality),
        );
    }
  } catch (e) {
    debugPrint('Error in isolate compression: $e');
    return null;
  }
}

