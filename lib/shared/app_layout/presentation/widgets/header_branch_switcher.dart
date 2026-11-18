import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:eyadty/core/animation/hover_scale_animation.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/domain/repo/branches_repo.dart';
import 'package:eyadty/shared/services/app_branch_service.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class BranchItemInfo {
  final String id;
  final String? name;
  final String? nameKey;
  final String roomsInfo;
  final bool isOpen;

  const BranchItemInfo({
    required this.id,
    this.name,
    this.nameKey,
    required this.roomsInfo,
    this.isOpen = true,
  });

  String get displayName =>
      (nameKey != null && nameKey!.isNotEmpty) ? nameKey!.tr() : (name ?? id);
}

class HeaderBranchSwitcher extends StatefulWidget {
  const HeaderBranchSwitcher({super.key});

  @override
  State<HeaderBranchSwitcher> createState() => _HeaderBranchSwitcherState();
}

class _HeaderBranchSwitcherState extends State<HeaderBranchSwitcher> {
  static const List<BranchItemInfo> _branches = [
    BranchItemInfo(
      id: 'branch_1',
      nameKey: 'branch_main',
      roomsInfo: '4 عيادات نشطة • طاقم العمل متاح',
      isOpen: true,
    ),
    BranchItemInfo(
      id: 'branch_2',
      nameKey: 'branch_second',
      roomsInfo: '3 عيادات نشطة • مواعيد مسائية',
      isOpen: true,
    ),
    BranchItemInfo(
      id: 'branch_3',
      nameKey: 'branch_third',
      roomsInfo: 'عيادتان نشطتان • حجز مسبق',
      isOpen: false,
    ),
  ];

  String _selectedBranchId = 'branch_1';
  List<BranchItemInfo> _dynamicBranches = [];

  @override
  void initState() {
    super.initState();
    _selectedBranchId = AppBranchService.instance.currentBranchId;
    AppBranchService.instance.selectedBranchNotifier
        .addListener(_onServiceBranchChanged);
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    if (getIt.isRegistered<BranchesRepo>()) {
      final result = await getIt<BranchesRepo>().getBranches();
      result.fold((_) {}, (branches) {
        if (mounted) {
          setState(() {
            _dynamicBranches = branches.map(_fromModel).toList();
          });
        }
      });
    }
  }

  BranchItemInfo _fromModel(BranchModel b) {
    final rooms = b.activeRoomsCount ?? 0;
    final staff = b.staffMembersCount ?? 0;
    final roomsInfo = rooms > 0
        ? '$rooms عيادات نشطة • $staff أعضاء طاقم'
        : (b.isBranchActive ? 'متاح للعمل' : 'معطل مؤقتاً');
    return BranchItemInfo(
      id: b.id ?? '',
      name: b.name,
      nameKey: b.nameKey,
      roomsInfo: roomsInfo,
      isOpen: b.isBranchActive,
    );
  }

  void _onServiceBranchChanged() {
    if (mounted &&
        _selectedBranchId != AppBranchService.instance.currentBranchId) {
      setState(() {
        _selectedBranchId = AppBranchService.instance.currentBranchId;
      });
    }
  }

  @override
  void dispose() {
    AppBranchService.instance.selectedBranchNotifier
        .removeListener(_onServiceBranchChanged);
    super.dispose();
  }

  List<BranchItemInfo> get _availableBranches {
    final source =
        _dynamicBranches.isNotEmpty ? _dynamicBranches : _branches;
    if (!getIt.isRegistered<SessionCubit>()) return source;
    final user = getIt<SessionCubit>().state.currentUser;
    if (user == null || user.isOwner == true) return source;
    final userBranchIds =
        user.branchAssignments?.map((b) => b.branchId).toSet() ?? {};
    final filtered =
        source.where((b) => userBranchIds.contains(b.id)).toList();
    return filtered.isNotEmpty ? filtered : source;
  }

  bool get _canSwitchBranches => _availableBranches.length > 1;

  BranchItemInfo get _activeBranch => _availableBranches.firstWhere(
        (b) => b.id == _selectedBranchId,
        orElse: () => _availableBranches.first,
      );

  void _onSelectBranch(BranchItemInfo branch) {
    if (branch.id == _selectedBranchId) return;
    setState(() {
      _selectedBranchId = branch.id;
    });
    if (getIt.isRegistered<SessionCubit>()) {
      getIt<SessionCubit>().switchBranch(branch.id);
    }
    AppBranchService.instance.selectBranch(branch.id);

    CustomToast(
      context: context,
      header: '${'switch_branch'.tr()}: ${branch.displayName}',
    ).showTopToast();
  }

  void _showBranchPopover(BuildContext buttonContext) {
    if (!_canSwitchBranches) return;
    final isDark = buttonContext.isDarkMode;
    final popoverHeight = (_availableBranches.length * 68.0) + 16.0;

    showPopover(
      context: buttonContext,
      direction: PopoverDirection.bottom,
      width: 290,
      height: popoverHeight.clamp(120.0, 360.0),
      arrowHeight: 10,
      arrowWidth: 20,
      radius: 16,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      barrierColor: Colors.black26,
      bodyBuilder: (popoverCtx) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _availableBranches.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
                ),
              _buildBranchRowItem(
                popoverCtx: popoverCtx,
                branch: _availableBranches[i],
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBranchRowItem({
    required BuildContext popoverCtx,
    required BranchItemInfo branch,
    required bool isDark,
  }) {
    final isSelected = branch.id == _selectedBranchId;
    return InkWell(
      onTap: () {
        Navigator.of(popoverCtx).pop();
        _onSelectBranch(branch);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Status Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: branch.isOpen
                    ? const Color(0xFF10B981) // Active Green
                    : AppColors.gray7A828E,
              ),
            ),
            const SizedBox(width: 12),

            // Branch Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    branch.displayName,
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.white : AppColors.darkText),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    branch.roomsInfo,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark Icon if Selected
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fillDisableColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              _activeBranch.displayName,
              style: CustomAppFontStyle.medium13.copyWith(
                color: AppColors.darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_canSwitchBranches) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.gray7A828E,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canSwitchBranches) {
      return _buildPillContent();
    }

    return HoverScaleAnimation(
      hoverScale: 1.02,
      tapScale: 0.98,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => _showBranchPopover(context),
        child: _buildPillContent(),
      ),
    );
  }
}
