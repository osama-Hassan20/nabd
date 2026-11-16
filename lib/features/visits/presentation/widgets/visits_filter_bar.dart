import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_stack_selector.dart';
import '../manager/visits_cubit.dart';
import '../manager/visits_state.dart';

class VisitsFilterBar extends StatefulWidget {
  final VisitsCubit cubit;
  final VisitsState state;
  final bool isAdminOrOwner;

  const VisitsFilterBar({
    super.key,
    required this.cubit,
    required this.state,
    this.isAdminOrOwner = false,
  });

  static const List<(String id, String name)> knownDoctors = [
    ('DOC-01', 'د. حسام الدين مصطفى'),
    ('DOC-02', 'د. أحمد الشافعي'),
    ('DOC-03', 'د. سارة عبد الرحمن'),
  ];

  @override
  State<VisitsFilterBar> createState() => _VisitsFilterBarState();
}

class _VisitsFilterBarState extends State<VisitsFilterBar> {
  late final TextEditingController _doctorController;

  @override
  void initState() {
    super.initState();
    _doctorController = TextEditingController(text: _getDoctorLabel(widget.state.filterDoctorId));
  }

  @override
  void didUpdateWidget(covariant VisitsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.filterDoctorId != widget.state.filterDoctorId) {
      _doctorController.text = _getDoctorLabel(widget.state.filterDoctorId);
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    super.dispose();
  }

  String _getDoctorLabel(String? doctorId) {
    if (doctorId == null) return 'visits_queue_all_doctors'.tr();
    final match = VisitsFilterBar.knownDoctors.where((d) => d.$1 == doctorId);
    if (match.isNotEmpty) return match.first.$2;
    return doctorId;
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = widget.state.filterDate ?? CairoTimeHelper.now();
    final isToday = CairoTimeHelper.isSameDay(currentDate, CairoTimeHelper.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // ─── Left Group: Date Navigation & Picker ─────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  final prevDay = currentDate.subtract(const Duration(days: 1));
                  widget.cubit.loadDoctorQueue(date: prevDay);
                },
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: 'previous_day'.tr(),
                color: AppColors.gray,
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: currentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    widget.cubit.loadDoctorQueue(date: picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isToday
                            ? '${'today'.tr()} (${DateFormat('d MMM', 'ar').format(currentDate)})'
                            : DateFormat('EEEE d MMMM y', 'ar').format(currentDate),
                        style: CustomAppFontStyle.bold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final nextDay = currentDate.add(const Duration(days: 1));
                  widget.cubit.loadDoctorQueue(date: nextDay);
                },
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: 'next_day'.tr(),
                color: AppColors.gray,
              ),
            ],
          ),

          // ─── Right Group: Status Filter & Doctor Filter (Admin) ───
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doctor Filter (Admin/Owner only)
              if (widget.isAdminOrOwner) ...[
                SizedBox(
                  width: 190,
                  child: CustomStackSelector<(String, String)?>(
                    controller: _doctorController,
                    hintText: 'visits_queue_all_doctors'.tr(),
                    list: const [null, ...VisitsFilterBar.knownDoctors],
                    itemAsString: (item) =>
                        item != null ? item.$2 : 'visits_queue_all_doctors'.tr(),
                    changeValue: (val) {
                      setState(() {
                        _doctorController.text = val != null
                            ? val.$2
                            : 'visits_queue_all_doctors'.tr();
                      });
                      widget.cubit.setFilterDoctorId(val?.$1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Refresh Button
              IconButton(
                onPressed: () => widget.cubit.loadDoctorQueue(),
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'refresh'.tr(),
                color: AppColors.gray,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
