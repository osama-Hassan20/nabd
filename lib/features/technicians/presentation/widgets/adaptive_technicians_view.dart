import 'package:flutter/material.dart';
import 'package:purexo/features/technicians/data/models/technician_model.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'technician_card.dart';
import 'technicians_table.dart';

class AdaptiveTechniciansView extends StatelessWidget {
  final List<TechnicianModel> technicians;

  const AdaptiveTechniciansView({super.key, required this.technicians});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      // Desktop: Render full data table
      desktopLayout: (context) => TechniciansTable(technicians: technicians),

      // Tablet: 2-Column Responsive Card Grid
      tabletLayout: (context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: technicians.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        itemBuilder: (context, index) =>
            TechnicianCard(technician: technicians[index]),
      ),

      // Mobile: 1-Column Card List
      mobileLayout: (context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: technicians.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            TechnicianCard(technician: technicians[index]),
      ),
    );
  }
}
