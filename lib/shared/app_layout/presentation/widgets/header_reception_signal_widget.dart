import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:popover/popover.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:toastification/toastification.dart';

class HeaderReceptionSignalWidget extends StatefulWidget {
  const HeaderReceptionSignalWidget({super.key});

  @override
  State<HeaderReceptionSignalWidget> createState() =>
      _HeaderReceptionSignalWidgetState();
}

class _HeaderReceptionSignalWidgetState
    extends State<HeaderReceptionSignalWidget> {
  int _selectedTarget = 0; // 0: All, 1: Reception, 2: Assistants

  String get _targetAudienceText {
    switch (_selectedTarget) {
      case 1:
        return 'موظفو الاستقبال فقط';
      case 2:
        return 'المساعدون فقط';
      default:
        return 'كل الموظفين';
    }
  }

  void _sendSignal({
    required BuildContext popoverContext,
    required String actionKey,
    required String title,
    required String body,
  }) {
    // 1. Play audible feedback tone
    SystemSound.play(SystemSoundType.alert);

    // 2. Dispatch to NotificationsCubit
    final session = getIt<SessionCubit>();
    final senderName =
        session.currentUser?.fullName ?? session.state.userName ?? 'الطبيب';

    if (getIt.isRegistered<NotificationsCubit>()) {
      getIt<NotificationsCubit>().sendReceptionSignal(
        title: title,
        body: body,
        targetAudience: _targetAudienceText,
        actionKey: actionKey,
        senderName: senderName,
      );
    }

    // 3. Close the popover
    final parentContext = context;
    Navigator.of(popoverContext).pop();

    // 4. Show success toast notification
    if (parentContext.mounted) {
      CustomToast(
        context: parentContext,
        header: 'تم إرسال إشارة: $title',
        description: 'تم إشعار $_targetAudienceText بصوت وتنبيه فوري',
        type: ToastificationType.success,
      ).showTopToast();
    }
  }

  void _showSignalPopover(BuildContext buttonContext) {
    final isDark = buttonContext.isDarkMode;

    showPopover(
      context: buttonContext,
      direction: PopoverDirection.bottom,
      width: 320,
      height: 420,
      arrowHeight: 10,
      arrowWidth: 20,
      radius: 16,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      barrierColor: Colors.black26,
      bodyBuilder: (popoverCtx) => StatefulBuilder(
        builder: (ctx, setPopoverState) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Status: الاستقبال
              Text(
                'الاستقبال',
                textAlign: TextAlign.start,
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '0 موظف متصل',
                textAlign: TextAlign.start,
                style: CustomAppFontStyle.bold16.copyWith(
                  color: isDark ? AppColors.white : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'لا يوجد موظفون متصلون الآن – سيصل الإشعار للموظفين الذين لديهم التطبيق.',
                textAlign: TextAlign.start,
                style: CustomAppFontStyle.regular11.copyWith(
                  color: const Color(0xFFD97706), // Warm Orange
                  height: 1.4,
                ),
              ),
              const Divider(color: AppColors.grayE2E8F0, height: 22),

              // Section: إرسال إلى
              Text(
                'إرسال إلى',
                textAlign: TextAlign.start,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 6),

              _buildRadioRow(
                label: 'كل الموظفين',
                value: 0,
                isDark: isDark,
                setPopoverState: setPopoverState,
              ),
              _buildRadioRow(
                label: 'موظفو الاستقبال فقط',
                value: 1,
                isDark: isDark,
                setPopoverState: setPopoverState,
              ),
              _buildRadioRow(
                label: 'المساعدون فقط',
                value: 2,
                isDark: isDark,
                setPopoverState: setPopoverState,
              ),

              const Divider(color: AppColors.grayE2E8F0, height: 22),

              // Action 1: استدعاء الموظف
              _buildActionRow(
                icon: Icons.front_hand_outlined,
                label: 'استدعاء الموظف',
                isDark: isDark,
                onTap: () {
                  _sendSignal(
                    popoverContext: popoverCtx,
                    actionKey: 'CALL_STAFF',
                    title: 'استدعاء موظف للعيادة',
                    body: 'الطبيب يطلب حضور الموظف فوراً إلى غرفة الكشف.',
                  );
                },
              ),
              const Divider(color: AppColors.grayE2E8F0, height: 8),

              // Action 2: تعليق المريض التالي
              _buildActionRow(
                icon: Icons.pause_circle_outline_rounded,
                label: 'تعليق المريض التالي',
                isDark: isDark,
                onTap: () {
                  _sendSignal(
                    popoverContext: popoverCtx,
                    actionKey: 'HOLD_NEXT_PATIENT',
                    title: 'تعليق المريض التالي مؤقتاً',
                    body: 'يرجى الانتظار وعدم إدخال المريض التالي حتى إشعار آخر.',
                  );
                },
              ),
              const Divider(color: AppColors.grayE2E8F0, height: 8),

              // Action 3: السماح بالمريض التالي
              _buildActionRow(
                icon: Icons.play_circle_outline_rounded,
                label: 'السماح بالمريض التالي',
                isDark: isDark,
                onTap: () {
                  _sendSignal(
                    popoverContext: popoverCtx,
                    actionKey: 'ALLOW_NEXT_PATIENT',
                    title: 'جاهز لاستقبال المريض التالي',
                    body: 'يرجى توجيه المريض التالي للدخول إلى غرفة الكشف الآن.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioRow({
    required String label,
    required int value,
    required bool isDark,
    required StateSetter setPopoverState,
  }) {
    final isSelected = _selectedTarget == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setPopoverState(() {
          _selectedTarget = value;
        });
        setState(() {
          _selectedTarget = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray7A828E,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: CustomAppFontStyle.medium13.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.white : AppColors.darkText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.white : AppColors.darkText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: isDark ? AppColors.white : AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'إشارة لموظف الاستقبال',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          _showSignalPopover(context);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3E8FF), // Soft Purple / Lilac
            border: Border.all(
              color: const Color(0xFFC084FC).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.campaign_outlined,
              color: Color(0xFF7C3AED), // Vibrant Megaphone Purple
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
