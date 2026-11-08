import 'package:flutter/material.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

class MedicalServicesShimmer extends StatelessWidget {
  const MedicalServicesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                flex: 3,
                child: CustomShimmerContainer(
                  height: 44,
                  width: double.infinity,
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomShimmerContainer(
                  height: 44,
                  width: double.infinity,
                  borderRadius: 8,
                ),
              ),
              SizedBox(width: 12),
              CustomShimmerContainer(
                height: 44,
                width: 130,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CustomShimmerContainer(
            height: 400,
            width: double.infinity,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}
