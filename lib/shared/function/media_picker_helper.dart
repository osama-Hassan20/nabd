import 'dart:io';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/shared/widgets/custom_media_picker.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

class MediaPickerHelper {
  static Future<void> pickMedia({
    required BuildContext context,
    required MediaCategory category,
    required ValueChanged<List<MediaModel>> onMediaPicked,
    bool enableMultiple = false,
    ValueChanged<bool>? onLoadingChanged,
    double maxImageSizeMB = 5,
    double maxVideoSizeMB = 5,
    bool openGalleryDirectly = false,
  }) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        openGalleryDirectly) {
      await _pickFromFilePicker(
        category: category,
        enableMultiple: enableMultiple,
        onMediaPicked: onMediaPicked,
        onLoadingChanged: onLoadingChanged,
        context: context,
        maxImageSizeMB: maxImageSizeMB,
        maxVideoSizeMB: maxVideoSizeMB,
      );
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return CustomMediaPicker(
            mediaCategory: category,
            enableMultiple: enableMultiple,
            pickMultiMedia: (value) async {
              if (value.isNotEmpty) {
                dialogContext.pop();
                await _handleMultiMediaResult(
                  value: value,
                  onMediaPicked: onMediaPicked,
                  onLoadingChanged: onLoadingChanged,
                  context: context,
                  maxImageSizeMB: maxImageSizeMB,
                  maxVideoSizeMB: maxVideoSizeMB,
                );
              }
            },
            pickMedia: (value) async {
              if (value != null) {
                dialogContext.pop();
                await _handleMediaResult(
                  value: value,
                  onMediaPicked: onMediaPicked,
                  onLoadingChanged: onLoadingChanged,
                  context: context,
                  maxImageSizeMB: maxImageSizeMB,
                  maxVideoSizeMB: maxVideoSizeMB,
                );
              }
            },
          );
        },
      );
    }
  }

  static Future<void> _pickFromFilePicker({
    required MediaCategory category,
    required bool enableMultiple,
    required ValueChanged<List<MediaModel>> onMediaPicked,
    required BuildContext context,
    ValueChanged<bool>? onLoadingChanged,
    required double maxImageSizeMB,
    required double maxVideoSizeMB,
  }) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      debugPrint('[MediaPickerHelper] Starting pickFromFilePicker');

      if (category == MediaCategory.video) {
        debugPrint('[MediaPickerHelper] Picking single video...');
        final XFile? video = await imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        debugPrint('[MediaPickerHelper] Picked video: ${video?.path}');
        if (video != null) {
          final model = MediaModel(
            type: MediaSourceType.file,
            path: video.path,
            category: MediaCategory.video,
            fileName: video.name,
            fileSize: await video.length(),
          );
          if (!context.mounted) return;
          await _handleMediaResult(
            value: model,
            onMediaPicked: onMediaPicked,
            onLoadingChanged: onLoadingChanged,
            context: context,
            maxImageSizeMB: maxImageSizeMB,
            maxVideoSizeMB: maxVideoSizeMB,
          );
        }
        return;
      }

      if (enableMultiple) {
        debugPrint('[MediaPickerHelper] Picking multi image...');
        final List<XFile> images = await imagePicker.pickMultiImage(
          maxWidth: kIsWeb ? 1920 : null,
          maxHeight: kIsWeb ? 1080 : null,
          imageQuality: kIsWeb ? 75 : null,
        );
        debugPrint('[MediaPickerHelper] Picked ${images.length} images');
        if (images.isNotEmpty) {
          final mediaList = <MediaModel>[];
          for (final img in images) {
            final model = await xFileToMediaModel(img, MediaCategory.image);
            mediaList.add(model);
          }
          if (!context.mounted) return;
          await _handleMultiMediaResult(
            value: mediaList,
            onMediaPicked: onMediaPicked,
            onLoadingChanged: onLoadingChanged,
            context: context,
            maxImageSizeMB: maxImageSizeMB,
            maxVideoSizeMB: maxVideoSizeMB,
          );
        }
      } else {
        debugPrint('[MediaPickerHelper] Picking single image...');
        final XFile? image = await imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: kIsWeb ? 1920 : null,
          maxHeight: kIsWeb ? 1080 : null,
          imageQuality: kIsWeb ? 75 : null,
        );
        debugPrint('[MediaPickerHelper] Picked image: ${image?.path}');
        if (image != null) {
          final model = await xFileToMediaModel(image, MediaCategory.image);
          if (!context.mounted) return;
          await _handleMediaResult(
            value: model,
            onMediaPicked: onMediaPicked,
            onLoadingChanged: onLoadingChanged,
            context: context,
            maxImageSizeMB: maxImageSizeMB,
            maxVideoSizeMB: maxVideoSizeMB,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[MediaPickerHelper] Error picking file: $e');
      debugPrint('[MediaPickerHelper] StackTrace: $stackTrace');
    }
  }

  static Future<void> _handleMediaResult({
    required MediaModel value,
    required ValueChanged<List<MediaModel>> onMediaPicked,
    required BuildContext context,
    ValueChanged<bool>? onLoadingChanged,
    required double maxImageSizeMB,
    required double maxVideoSizeMB,
  }) async {
    final int sizeInBytes = value.fileSize ?? 0;
    if (sizeInBytes > 0 &&
        !validateFileSize(
          fileSizeBytes: sizeInBytes,
          category: value.category,
          context: context,
          maxImageSizeMB: maxImageSizeMB,
          maxVideoSizeMB: maxVideoSizeMB,
        )) {
      return;
    }

    onLoadingChanged?.call(true);
    final compressed = await compressImage(value);
    onLoadingChanged?.call(false);
    onMediaPicked([compressed]);
  }

  static Future<void> _handleMultiMediaResult({
    required List<MediaModel> value,
    required ValueChanged<List<MediaModel>> onMediaPicked,
    required BuildContext context,
    ValueChanged<bool>? onLoadingChanged,
    required double maxImageSizeMB,
    required double maxVideoSizeMB,
  }) async {
    for (final item in value) {
      final int sizeInBytes = item.fileSize ?? 0;
      if (sizeInBytes > 0 &&
          !validateFileSize(
            fileSizeBytes: sizeInBytes,
            category: item.category,
            context: context,
            maxImageSizeMB: maxImageSizeMB,
            maxVideoSizeMB: maxVideoSizeMB,
          )) {
        return;
      }
    }

    onLoadingChanged?.call(true);
    final compressedMedia = <MediaModel>[];
    for (var item in value) {
      compressedMedia.add(await compressImage(item));
    }
    onLoadingChanged?.call(false);
    onMediaPicked(compressedMedia);
  }

  static Future<MediaModel> xFileToMediaModel(
    XFile file,
    MediaCategory category,
  ) async {
    final bytes = await file.readAsBytes();
    debugPrint(
      '[MediaPickerHelper] Picked file size (after picker compression): ${(bytes.length / (1024 * 1024)).toStringAsFixed(3)} MB',
    );
    return MediaModel(
      type: MediaSourceType.file,
      path: file.path,
      category: category,
      fileName: file.name,
      fileSize: bytes.length,
      fileBytes: bytes,
    );
  }

  static bool validateFileSize({
    required int fileSizeBytes,
    required MediaCategory category,
    required BuildContext context,
    required double maxImageSizeMB,
    required double maxVideoSizeMB,
  }) {
    final double sizeInMB = fileSizeBytes / (1024 * 1024);
    final bool isImage = category == MediaCategory.image;
    final double maxMB = isImage ? maxImageSizeMB : maxVideoSizeMB;

    if (sizeInMB > maxMB) {
      if (context.mounted) {
        CustomToast(
          context: context,
          header: isImage
              ? "حجم الصورة يجب أن لا يتجاوز $maxMB ميجابايت"
              : "حجم الفيديو يجب أن لا يتجاوز $maxMB ميجابايت",
          type: ToastificationType.error,
        ).showTopToast();
      }
      return false;
    }
    return true;
  }

  static Future<MediaModel> compressImage(MediaModel media) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return media;
    if (media.category != MediaCategory.image) return media;
    if (media.fileBytes == null && media.path.isEmpty) return media;

    final Uint8List? originalBytes = media.fileBytes;
    if (originalBytes == null) {
      if (media.path.isEmpty || kIsWeb) return media;
      try {
        final bytes = await File(media.path).readAsBytes();
        return await _runCompression(media, bytes);
      } catch (_) {
        return media;
      }
    }

    return _runCompression(media, originalBytes);
  }

  static Future<MediaModel> _runCompression(
    MediaModel media,
    Uint8List inputBytes,
  ) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        inputBytes,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      return media.copyWith(
        fileBytes: compressedBytes,
        fileSize: compressedBytes.length,
        mimeType: 'image/jpeg',
        fileName: media.fileName != null
            ? '${media.fileName!.replaceAll(RegExp(r'\.[^.]+$'), '')}_compressed.jpg'
            : 'compressed_image.jpg',
      );
    } catch (e) {
      return media;
    }
  }
}
