import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../manager/hr_cubit.dart';
import '../manager/hr_state.dart';
import 'settlements_filter_bar.dart';
import 'settlements_table.dart';

class DoctorSettlementsTab extends StatelessWidget {
  final VoidCallback? onPrintSettlement;

  const DoctorSettlementsTab({
    super.key,
    this.onPrintSettlement,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrCubit, HrState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettlementsFilterBar(),
              const SizedBox(height: 20),
              SettlementsTable(
                settlements: state.settlements,
                onPrintSettlement: onPrintSettlement,
              ),
            ],
          ),
        );
      },
    );
  }
}

