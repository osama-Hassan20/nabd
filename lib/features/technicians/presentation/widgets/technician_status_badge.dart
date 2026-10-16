import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import '../../data/models/enums/technician_status_enum.dart';

class TechnicianStatusBadge extends StatelessWidget {
  final TechnicianStatusEnum status;

  const TechnicianStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomAssetImage(
            path: status.icon,
            width: 12,
            height: 12,
            color: status.color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              style: CustomAppFontStyle.regular14.copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
