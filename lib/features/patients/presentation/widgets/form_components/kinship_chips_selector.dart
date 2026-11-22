import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/kinship_relations.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class KinshipChipsSelector extends StatefulWidget {
  final String? selectedRelation;
  final List<KinshipOptionModel> options;
  final ValueChanged<String?> onChanged;
  final String? header;
  final String? otherHintText;

  const KinshipChipsSelector({
    super.key,
    required this.selectedRelation,
    required this.options,
    required this.onChanged,
    this.header,
    this.otherHintText,
  });

  @override
  State<KinshipChipsSelector> createState() => _KinshipChipsSelectorState();
}

class _KinshipChipsSelectorState extends State<KinshipChipsSelector> {
  late final TextEditingController _customController;
  bool _isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    _initSelection();
    _customController = TextEditingController(
      text: _isOtherSelected ? widget.selectedRelation : '',
    );
  }

  void _initSelection() {
    final rel = widget.selectedRelation;
    if (rel == null || rel.isEmpty) {
      _isOtherSelected = false;
      return;
    }
    final isPreset = widget.options
        .where((o) => o.key != KinshipRelations.otherKey)
        .any((o) => o.key == rel);

    _isOtherSelected = !isPreset || rel == KinshipRelations.otherKey;
  }

  @override
  void didUpdateWidget(covariant KinshipChipsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRelation != oldWidget.selectedRelation) {
      _initSelection();
      if (_isOtherSelected &&
          widget.selectedRelation != KinshipRelations.otherKey) {
        _customController.text = widget.selectedRelation ?? '';
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.header != null) ...[
          Text(
            widget.header!,
            style: CustomAppFontStyle.medium14.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.options.map((option) {
            final isOtherOption = option.key == KinshipRelations.otherKey;
            final isSelected = isOtherOption
                ? _isOtherSelected
                : (!_isOtherSelected && widget.selectedRelation == option.key);

            return InkWell(
              onTap: () {
                if (isOtherOption) {
                  setState(() {
                    _isOtherSelected = true;
                  });
                  widget.onChanged(_customController.text.trim().isNotEmpty
                      ? _customController.text.trim()
                      : KinshipRelations.otherKey);
                } else {
                  setState(() {
                    _isOtherSelected = false;
                  });
                  widget.onChanged(option.key);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option.localizedLabel,
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_isOtherSelected) ...[
          const SizedBox(height: 10),
          CustomTextFormField(
            controller: _customController,
            hintText: widget.otherHintText ?? 'enter_custom_relation_hint'.tr(),
            prefixWidget: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.edit_note, size: 18, color: AppColors.gray71717A),
            ),
            onChanged: (val) {
              widget.onChanged(val?.trim().isNotEmpty == true
                  ? val!.trim()
                  : KinshipRelations.otherKey);
            },
          ),
        ],
      ],
    );
  }
}

