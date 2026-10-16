import 'package:eyadty/core/models/media_model.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

/// Returns a safe image filename that always has a valid extension.
/// On web, [MediaModel.path] may be a blob URL or empty — this handles that.
String resolveImageFileName(MediaModel media) {
  // 1. Prefer stored fileName if it has a recognised image extension
  if (media.fileName != null && media.fileName!.isNotEmpty) {
    final ext = media.fileName!.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return media.fileName!;
    }
  }
  // 2. Try path (works on native; blob URLs start with 'blob:')
  final pathName = media.path.split('/').last;
  if (pathName.isNotEmpty && !pathName.startsWith('blob:')) {
    final ext = pathName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return pathName;
    }
  }
  // 3. Derive from mimeType
  if (media.mimeType != null) {
    final ext = media.mimeType!.split('/').last.toLowerCase();
    return 'image_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }
  // 4. Safe fallback
  return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
}

/// Returns the MIME subtype string for a given filename (e.g. 'jpeg', 'png').
String imageSubtype(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'png';
    case 'gif':
      return 'gif';
    case 'webp':
      return 'webp';
    default:
      return 'jpeg';
  }
}

/// Builds a [MultipartFile] from a [MediaModel] with the correct filename
/// and explicit Content-Type so the server's MIME filter accepts it on all
/// platforms including web.
Future<MultipartFile> buildImageMultipartFile(MediaModel media) async {
  final filename = resolveImageFileName(media);
  final contentType = MediaType('image', imageSubtype(filename));

  if (media.fileBytes != null) {
    return MultipartFile.fromBytes(
      media.fileBytes!,
      filename: filename,
      contentType: contentType,
    );
  }

  return MultipartFile.fromFile(
    media.path,
    filename: filename,
    contentType: contentType,
  );
}
