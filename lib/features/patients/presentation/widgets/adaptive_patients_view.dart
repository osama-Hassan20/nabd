import 'package:flutter/material.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import 'patient_card.dart';
import 'patients_table.dart';

class AdaptivePatientsView extends StatelessWidget {
  final List<PatientModel> patients;

  const AdaptivePatientsView({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      // Desktop (width >= 1000): Render full Data Table
      desktopLayout: (context) => PatientsTable(patients: patients),

      // Tablet (700 < width < 1000): Render 2-Column Responsive Card Grid
      tabletLayout: (context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patients.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 250,
        ),
        itemBuilder: (context, index) =>
            PatientCard(patient: patients[index]),
      ),

      // Mobile (width <= 700): Render 1-Column Vertical Card List
      mobileLayout: (context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patients.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            PatientCard(patient: patients[index]),
      ),
    );
  }
}

