import 'package:flutter/material.dart';
import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import 'customer_card.dart';
import 'customers_table.dart';

class AdaptiveCustomersView extends StatelessWidget {
  final List<CustomerModel> customers;

  const AdaptiveCustomersView({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      // Desktop (width >= 1000): Render full Data Table
      desktopLayout: (context) => CustomersTable(customers: customers),

      // Tablet (700 < width < 1000): Render 2-Column Responsive Card Grid
      tabletLayout: (context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 270,
        ),
        itemBuilder: (context, index) =>
            CustomerCard(customer: customers[index]),
      ),

      // Mobile (width <= 700): Render 1-Column Vertical Card List
      mobileLayout: (context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            CustomerCard(customer: customers[index]),
      ),
    );
  }
}
