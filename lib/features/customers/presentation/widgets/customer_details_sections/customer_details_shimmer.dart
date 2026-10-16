import 'package:flutter/material.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

class CustomerDetailsShimmer extends StatelessWidget {
  const CustomerDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile card shimmer
        const CustomShimmerContainer(
          borderRadius: 16,
          height: 180,
          width: double.infinity,
        ),
        const SizedBox(height: 16),

        // KPI cards shimmer
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 96,
          ),
          itemBuilder: (_, _) => const CustomShimmerContainer(
            borderRadius: 12,
            height: 96,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 16),

        // Bookings table shimmer
        const CustomShimmerContainer(
          borderRadius: 16,
          height: 350,
          width: double.infinity,
        ),
      ],
    );
  }
}
