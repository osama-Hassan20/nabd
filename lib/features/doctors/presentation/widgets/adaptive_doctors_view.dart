import 'package:flutter/material.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'doctor_card.dart';
import 'doctors_table.dart';

class AdaptiveDoctorsView extends StatelessWidget {
  final List<DoctorModel> doctors;

  const AdaptiveDoctorsView({super.key, required this.doctors});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      // Desktop: Render full data table
      desktopLayout: (context) => DoctorsTable(doctors: doctors),

      // Tablet: 2-Column Responsive Card Grid
      tabletLayout: (context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doctors.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 190,
        ),
        itemBuilder: (context, index) =>
            DoctorCard(doctor: doctors[index]),
      ),

      // Mobile: 1-Column Card List
      mobileLayout: (context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doctors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            DoctorCard(doctor: doctors[index]),
      ),
    );
  }
}

