import 'dart:io';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/shared/widgets/custom_cached_image.dart';
import 'package:eyadty/shared/function/media_picker_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomCircularImagePicker extends StatefulWidget {
  const CustomCircularImagePicker({
    super.key,
    this.initialImage,
    required this.onChanged,
    this.size = 100,
  });

  final MediaModel? initialImage;
  final ValueChanged<MediaModel?> onChanged;
  final double size;

  @override
  State<CustomCircularImagePicker> createState() =>
      _CustomCircularImagePickerState();
}

class _CustomCircularImagePickerState extends State<CustomCircularImagePicker> {
  MediaModel? _selectedImage;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  void _pickImage() async {
    await MediaPickerHelper.pickMedia(
      context: context,
      category: MediaCategory.image,
      enableMultiple: false,
      openGalleryDirectly: true,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _isCompressing = loading);
      },
      onMediaPicked: (newMedia) {
        if (newMedia.isNotEmpty) {
          if (mounted) {
            setState(() {
              _selectedImage = newMedia.first;
            });
            widget.onChanged(_selectedImage);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: _isCompressing
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImage == null
                      ? Center(
                          child: SvgPicture.asset(
                            AppIcons.studentUser,
                            width: widget.size * 0.75,
                            colorFilter: ColorFilter.mode(
                              AppColors.gray334155,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      : _selectedImage!.isFile
                      ? Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          width: widget.size,
                          height: widget.size,
                        )
                      : CustomCachedImage(
                          imagePath: _selectedImage!.path,
                          fit: BoxFit.cover,
                          width: widget.size,
                          height: widget.size,
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppIcons.camera,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Text(
        //   widget.initialImage == null
        //       ? "add_profile_image".tr()
        //       : "edit_profile_image".tr(),
        //   style: CustomAppFontStyle.regular14.copyWith(
        //     color: context.isDarkMode ? AppColors.white : AppColors.black,
        //   ),
        // ),
      ],
    );
  }
}
