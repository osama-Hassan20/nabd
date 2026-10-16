import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/core/utils/theme/app_images.dart';

enum TechnicianGenderEnum {
  male(
    value: 'male',
    labelKey: 'gender_male',
    defaultAvatar: AppImages.cleanerMan,
  ),
  female(
    value: 'female',
    labelKey: 'gender_female',
    defaultAvatar: AppImages.cleanerWomen,
  );

  final String value;
  final String labelKey;
  final String defaultAvatar;

  const TechnicianGenderEnum({
    required this.value,
    required this.labelKey,
    required this.defaultAvatar,
  });

  String get label => labelKey.tr();

  static TechnicianGenderEnum? fromValue(String? val) {
    if (val == null) return null;
    return TechnicianGenderEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => TechnicianGenderEnum.male,
    );
  }
}
