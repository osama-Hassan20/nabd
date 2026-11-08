import 'package:flutter/material.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

class DoctorsScheduleShimmer extends StatelessWidget {
  const DoctorsScheduleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomShimmerContainer(
            height: 64,
            width: double.infinity,
            borderRadius: 12,
          ),
        ),
      ),
    );
  }
}
