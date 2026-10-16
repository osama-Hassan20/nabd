import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/app_icons.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

class CustomMediaPicker extends StatefulWidget {
  const CustomMediaPicker({
    super.key,
    required this.pickMedia,
    this.pickMultiMedia,
    this.onDelete,
    this.enableMultiple = false,
    this.mediaCategory = MediaCategory.image,
  });

  final void Function(MediaModel? media) pickMedia;
  final void Function(List<MediaModel> media)? pickMultiMedia;
  final VoidCallback? onDelete;
  final bool enableMultiple;
  final MediaCategory mediaCategory;

  @override
  State<CustomMediaPicker> createState() => _CustomMediaPickerState();
}

class _CustomMediaPickerState extends State<CustomMediaPicker> {
  final ImagePicker imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    String title = widget.mediaCategory == MediaCategory.video
        ? "choose_video".tr()
        : "choose_image".tr();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ).copyWith(bottom: 24),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CloseButton(color: Colors.transparent),
                Text(title, style: CustomAppFontStyle.regular14),
                const CloseButton(),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: AppIcons.camera,
                  label: "camera".tr(),
                  source: ImageSource.camera,
                ),
                Container(
                  width: 3,
                  height: 60,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: AppColors.gray334155,
                  ),
                ),
                _buildPickerOption(
                  icon: AppIcons.gallery,
                  label: "gallery".tr(),
                  source: ImageSource.gallery,
                ),
              ],
            ),
            if (widget.onDelete != null) ...[
              InkWell(
                onTap: () {
                  widget.onDelete!();
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.delete,
                      width: 20,
                      height: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.mediaCategory == MediaCategory.video
                          ? "delete_video".tr()
                          : "delete_image".tr(),
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required String icon,
    required String label,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () async {
        if (widget.mediaCategory == MediaCategory.video) {
          final XFile? video = await imagePicker.pickVideo(source: source);
          if (video != null) {
            final media = MediaModel(
              type: MediaSourceType.file,
              path: video.path,
              category: MediaCategory.video,
              fileName: video.name,
              fileSize: await video.length(),
            );
            widget.pickMedia(media);
          }
        } else {
          if (widget.enableMultiple && source == ImageSource.gallery) {
            final List<XFile> images = await imagePicker.pickMultiImage();
            if (images.isNotEmpty) {
              final mediaList = <MediaModel>[];
              for (var img in images) {
                mediaList.add(
                  MediaModel(
                    type: MediaSourceType.file,
                    path: img.path,
                    category: MediaCategory.image,
                    fileName: img.name,
                    fileSize: await img.length(),
                  ),
                );
              }
              widget.pickMultiMedia?.call(mediaList);
            }
          } else {
            final XFile? image = await imagePicker.pickImage(source: source);
            if (image != null) {
              final media = MediaModel(
                type: MediaSourceType.file,
                path: image.path,
                category: MediaCategory.image,
                fileName: image.name,
                fileSize: await image.length(),
              );
              widget.pickMedia(media);
            }
          }
        }
      },
      child: Column(
        spacing: 5,
        children: [
          SvgPicture.asset(
            icon,
            width: 50,
            colorFilter: ColorFilter.mode(
              context.isDarkMode ? AppColors.white : AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          Text(label, style: CustomAppFontStyle.regular14),
        ],
      ),
    );
  }
}
