import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/animation/hover_scale_animation.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
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

  void _showBranchPickerModal(BuildContext context) {
    if (!_canSwitchBranches) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const CustomAssetImage(
                      path: AppIcons.location,
                      color: AppColors.primary,
                      width: 18,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'switch_branch'.tr(),
                          style: CustomAppFontStyle.bold18.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'select_branch_desc'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Branch options list
              ..._availableBranches.map((branch) {
                final isSelected = branch.id == _selectedBranchId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).pop();
                      _onSelectBranch(branch);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withValues(alpha: 0.6)
                            : AppColors.fillDisableColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grayE2E8F0,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: branch.isOpen
                                  ? AppColors.secondary
                                  : AppColors.gray,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.displayName,
                                  style: CustomAppFontStyle.semiBold15.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  branch.roomsInfo,
                                  style: CustomAppFontStyle.regular12.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
      },
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

    final isDesktop = AdaptiveLayout.isDesktop(context);

    if (!isDesktop) {
      return HoverScaleAnimation(
        hoverScale: 1.02,
        tapScale: 0.98,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => _showBranchPickerModal(context),
          child: _buildPillContent(),
        ),
      );
    }

    return HoverScaleAnimation(
      hoverScale: 1.02,
      tapScale: 0.98,
      child: PopupMenuButton<BranchItemInfo>(
        tooltip: 'switch_branch'.tr(),
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        color: AppColors.white,
        onSelected: _onSelectBranch,
        itemBuilder: (context) {
          return _availableBranches.map((branch) {
            final isSelected = branch.id == _selectedBranchId;
            return PopupMenuItem<BranchItemInfo>(
              value: branch,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: branch.isOpen
                          ? AppColors.secondary
                          : AppColors.gray,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                                : AppColors.darkText,
                          ),
                        ),
                        Text(
                          branch.roomsInfo,
                          style: CustomAppFontStyle.regular11.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: _buildPillContent(),
      ),
    );
  }
}
