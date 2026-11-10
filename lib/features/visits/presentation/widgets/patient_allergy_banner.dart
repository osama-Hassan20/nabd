import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';

class PatientAllergyBanner extends StatelessWidget {
  final List<String> allergies;

  const PatientAllergyBanner({
    super.key,
    required this.allergies,
  });

  @override
  Widget build(BuildContext context) {
    if (allergies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2), // Rose 50
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFECDD3), // Rose 200
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFBE123C), // Rose 700
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'visits_allergy_warning'.tr(),
                  style: CustomAppFontStyle.bold14.copyWith(
                    color: const Color(0xFF9F1239), // Rose 800
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allergies.map((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6), // Rose 100
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFDA4AF), // Rose 300
                    width: 0.8,
                  ),
                ),
                child: Text(
                  allergy,
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: const Color(0xFF881337), // Rose 900
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

