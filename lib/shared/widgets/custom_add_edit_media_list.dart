import 'dart:io';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/image_preview.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_box_validator.dart';
import 'package:eyadty/shared/widgets/custom_cached_image.dart'
    show CustomCachedImage;
import 'package:eyadty/shared/function/media_picker_helper.dart';

class CustomAddMediaList extends StatefulWidget {
  const CustomAddMediaList({
    super.key,
    this.initialMedia = const [],
    this.onChanged,
    this.headerText,
    this.enableMultiple = false,
    this.headerTextStyle,
    this.enableValidation = false,
    this.hintTitle,
    this.subtitle,
    this.iconWidget,
    this.mediaCategory = MediaCategory.image,
    this.isReadOnly = false,

    /// Max size in MB for images. Defaults to 50 MB.
    this.maxImageSizeMB = 50,

    /// Max size in MB for video files. Defaults to 500 MB.
    this.maxVideoSizeMB = 5,
  });

  final List<MediaModel> initialMedia;
  final String? headerText;
  final bool enableMultiple;
  final TextStyle? headerTextStyle;
  final ValueChanged<List<MediaModel>>? onChanged;
  final bool enableValidation;
  final String? hintTitle;
  final String? subtitle;
  final Widget? iconWidget;
  final MediaCategory mediaCategory;
  final bool isReadOnly;
  final double maxImageSizeMB;
  final double maxVideoSizeMB;

  @override
  State<CustomAddMediaList> createState() => _CustomAddMediaListState();
}

class _CustomAddMediaListState extends State<CustomAddMediaList> {
  late List<MediaModel> mediaItems;
  int _currentIndex = 0;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    mediaItems = List.from(widget.initialMedia);
  }

  // ─── Pick handling ─────────────────────────────────────────────────────────

  void _pickMedia() async {
    await MediaPickerHelper.pickMedia(
      context: context,
      category: widget.mediaCategory,
      enableMultiple: widget.enableMultiple,
      maxImageSizeMB: widget.maxImageSizeMB,
      maxVideoSizeMB: widget.maxVideoSizeMB,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _isCompressing = loading);
      },
      onMediaPicked: (newMedia) {
        if (mounted) {
          setState(() {
            if (widget.enableMultiple) {
              mediaItems.addAll(newMedia);
            } else {
              mediaItems = newMedia;
            }
          });
          widget.onChanged?.call(mediaItems);
        }
      },
    );
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  void _deleteMedia(int index) {
    setState(() {
      mediaItems.removeAt(index);
    });
    widget.onChanged?.call(mediaItems);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.headerText != null)
          Text(
            widget.headerText!,
            style:
                widget.headerTextStyle ??
                CustomAppFontStyle.semiBold16.copyWith(),
          ),
        const SizedBox(height: 8),

        if (_isCompressing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('جارٍ المعالجة...'),
                ],
              ),
            ),
          )
        else if (mediaItems.isEmpty)
          CustomBoxValidator(
            validator: (value) {
              if (mediaItems.isEmpty && widget.enableValidation) {
                return widget.mediaCategory == MediaCategory.video
                    ? "add_video_validator".tr()
                    : "add_image_validator".tr();
              }
              return null;
            },
            builder: (context) {
              return InkWell(
                onTap: widget.isReadOnly ? null : _pickMedia,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    dashPattern: [6, 3],
                    radius: const Radius.circular(12),
                    strokeWidth: 1,
                    color: isDark
                        ? AppColors.gray334155.withValues(alpha: 0.4)
                        : AppColors.gray334155.withValues(alpha: 0.1),
                  ),
                  child: CustomContainer(
                    borderRaduis: 12,
                    height: 150,
                    padding: EdgeInsets.zero,
                    backGroundColor: AppColors.fillDisableColor,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            widget.iconWidget ??
                                CustomAssetImage(path: AppIcons.upload),
                            // Text(
                            //   widget.hintTitle ??
                            //       (widget.mediaCategory == MediaCategory.video
                            //           ? "add_video_hint".tr()
                            //           : "add_image_hint".tr()),
                            //   style: CustomAppFontStyle.semiBold14,
                            // ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.gray334155,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          Column(
            children: [
              SizedBox(
                height: 150,
                child: PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: mediaItems.length,
                  physics: const BouncingScrollPhysics(),
                  controller: mediaItems.length > 1
                      ? PageController(viewportFraction: 0.9)
                      : null,
                  padEnds: false,
                  itemBuilder: (context, index) {
                    final item = mediaItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageWidget(item),
                          ),
                          if (!widget.isReadOnly)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => _deleteMedia(index),
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (mediaItems.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaItems.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentIndex == index
                            ? AppColors.primary
                            : AppColors.gray334155,
                      ),
                    ),
                  ),
                ),
              if (!widget.isReadOnly)
                TextButton.icon(
                  onPressed: _pickMedia,
                  icon: SvgPicture.asset(
                    AppIcons.gallery,
                    colorFilter: ColorFilter.mode(
                      isDark ? AppColors.white : AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text(
                    widget.enableMultiple
                        ? "add_more".tr()
                        : (widget.mediaCategory == MediaCategory.video
                              ? "change_video".tr()
                              : "change_image".tr()),
                    style: CustomAppFontStyle.regular14.copyWith(
                      color: isDark ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageWidget(MediaModel item) {
    // Priority: in-memory bytes (web picks + compressed images)
    if (item.fileBytes != null) {
      return Image.memory(
        item.fileBytes!,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return const SizedBox(
              width: double.infinity,
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return child;
        },
      );
    }

    // Network image
    if (item.isNetwork) {
      return GestureDetector(
        onTap: !widget.isReadOnly
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePreview(
                      networkUrls: [item.path],
                      title: 'image_preview'.tr(),
                    ),
                  ),
                );
              },
        child: CustomCachedImage(
          imagePath: item.path,
          width: double.infinity,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }

    // Native file path (non-web)
    return Image.file(
      File(item.path),
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
    );
  }
}
