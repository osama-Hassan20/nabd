import 'package:easy_localization/easy_localization.dart';

class KinshipOptionModel {
  final String key;
  final String arabicLabel;
  final String englishLabel;

  const KinshipOptionModel({
    required this.key,
    required this.arabicLabel,
    required this.englishLabel,
  });

  String get localizedLabel {
    final trValue = key.tr();
    if (trValue.isNotEmpty && trValue != key) return trValue;
    return arabicLabel;
  }
}

class KinshipRelations {
  KinshipRelations._();

  static const String otherKey = 'relation_other';

  /// Emergency contact options:
  /// أب، أم، زوج/زوجة، أخ/أخت، ابن/ابنة، صديق، أخرى
  static const List<KinshipOptionModel> emergencyContactOptions = [
    KinshipOptionModel(
      key: 'relation_father',
      arabicLabel: 'أب',
      englishLabel: 'Father',
    ),
    KinshipOptionModel(
      key: 'relation_mother',
      arabicLabel: 'أم',
      englishLabel: 'Mother',
    ),
    KinshipOptionModel(
      key: 'relation_spouse',
      arabicLabel: 'زوج / زوجة',
      englishLabel: 'Spouse',
    ),
    KinshipOptionModel(
      key: 'relation_sibling',
      arabicLabel: 'أخ / أخت',
      englishLabel: 'Sibling',
    ),
    KinshipOptionModel(
      key: 'relation_child',
      arabicLabel: 'ابن / ابنة',
      englishLabel: 'Child',
    ),
    KinshipOptionModel(
      key: 'relation_friend',
      arabicLabel: 'صديق',
      englishLabel: 'Friend',
    ),
    KinshipOptionModel(
      key: otherKey,
      arabicLabel: 'أخرى',
      englishLabel: 'Other',
    ),
  ];

  /// Guardian options (for minors under 18):
  /// أب، أم، جد/جدة، عم/خال، وصي قانوني، أخرى
  static const List<KinshipOptionModel> guardianOptions = [
    KinshipOptionModel(
      key: 'relation_father',
      arabicLabel: 'أب',
      englishLabel: 'Father',
    ),
    KinshipOptionModel(
      key: 'relation_mother',
      arabicLabel: 'أم',
      englishLabel: 'Mother',
    ),
    KinshipOptionModel(
      key: 'relation_grandfather',
      arabicLabel: 'جد / جدة',
      englishLabel: 'Grandparent',
    ),
    KinshipOptionModel(
      key: 'relation_uncle',
      arabicLabel: 'عم / خال',
      englishLabel: 'Uncle / Aunt',
    ),
    KinshipOptionModel(
      key: 'relation_legal_guardian',
      arabicLabel: 'وصي قانوني',
      englishLabel: 'Legal Guardian',
    ),
    KinshipOptionModel(
      key: otherKey,
      arabicLabel: 'أخرى',
      englishLabel: 'Other',
    ),
  ];

  /// Translates relation if it matches a preset key, or returns the raw text if custom/legacy.
  static String displayRelation(String? relation) {
    if (relation == null || relation.trim().isEmpty) return '-';
    final all = [...emergencyContactOptions, ...guardianOptions];
    final match = all.where((o) => o.key == relation).firstOrNull;
    if (match != null) {
      return match.localizedLabel;
    }
    return relation;
  }
}

