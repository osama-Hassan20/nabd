import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_empty_widget.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../../../shared/widgets/error_page.dart';
import '../../data/models/staff_user_model.dart';
import '../cubit/staff_users_cubit.dart';
import '../cubit/staff_users_state.dart';
import '../widgets/staff_users_filter_bar.dart';
import '../widgets/staff_users_table.dart';
import 'dialogs/add_edit_staff_user_dialog.dart';
import 'dialogs/delete_staff_user_dialog.dart';
import 'dialogs/reset_password_dialog.dart';
import 'dialogs/role_permissions_matrix_dialog.dart';
import 'dialogs/toggle_user_status_dialog.dart';

class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StaffUsersCubit>()..loadData(),
      child: const _UsersManagementView(),
    );
  }
}

class _UsersManagementView extends StatelessWidget {
  const _UsersManagementView();

  @override
  Widget build(BuildContext context) {
    final sessionCubit = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>()
        : null;

    return BlocBuilder<SessionCubit, SessionState>(
      bloc: sessionCubit,
      builder: (context, sessionState) {
        final currentUser = sessionState.currentUser;
        final isOwner = currentUser?.isOwner == true;
        final colors = context.themeColors;

        return Scaffold(
          backgroundColor: colors.scaffoldBackground,
          body: BlocConsumer<StaffUsersCubit, StaffUsersState>(
        listener: (context, state) {
          if (state.errMessage != null && state.errMessage!.isNotEmpty) {
            CustomToast(
              context: context,
              header: state.errMessage!.tr(),
            ).showErrorToast();
          } else if (state.successMessage != null &&
              state.successMessage!.isNotEmpty) {
            CustomToast(
              context: context,
              header: state.successMessage!.tr(),
            ).showTopToast();
          }
        },
        builder: (context, state) {
          final cubit = context.read<StaffUsersCubit>();

          return RefreshIndicator(
            onRefresh: () async => cubit.loadData(showLoading: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header ─────────────────────────────────────────────
                  _buildHeader(context, isOwner: isOwner),
                  const SizedBox(height: 20),

                  // ─── Filter Bar ──────────────────────────────────────────
                  StaffUsersFilterBar(cubit: cubit, state: state),
                  const SizedBox(height: 20),

                  // ─── Main Content Table ──────────────────────────────────
                  _buildTableContent(context, cubit, state),
                ],
              ),
            ),
          );
        },
      ),
    );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isOwner}) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final colors = context.themeColors;

    return Row(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'users_management'.tr(),
                style: CustomAppFontStyle.bold24.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'users_management_desc'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              CustomPushButton(
                height: 44,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: colors.surfaceLevel1,
                borderRadius: BorderRadius.circular(10),
                boxBorder: Border.all(color: const Color(0xFF6366F1), width: 1),
                onTap: () => _openRolesMatrixDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'role_permissions_matrix'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            CustomPushButton(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: colors.primary,
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openAddEditUserDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'add_new_user'.tr(),
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableContent(
    BuildContext context,
    StaffUsersCubit cubit,
    StaffUsersState state,
  ) {
    final colors = context.themeColors;

    if (state.status == RequestStatusEnum.loading) {
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        padding: const EdgeInsets.all(16),
        child: CustomTableShimmer(
          headers: StaffUsersTable.defaultHeaders.map((h) => h.tr()).toList(),
          columnWidths: StaffUsersTable.columnWidths,
          minWidth: 990,
          rowCount: 6,
        ),
      );
    }

    if (state.status == RequestStatusEnum.failure) {
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: ErrorPage(
          errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
          onPressed: () => cubit.loadData(),
        ),
      );
    }

    final filtered = state.filteredUsers;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: CustomEmptyWidget(
          title: 'no_users_found'.tr(),
          subtitle: Text(
            'no_users_found_desc'.tr(),
            style: CustomAppFontStyle.regular13.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StaffUsersTable(
          users: filtered,
          roles: state.roles,
          onEdit: (user) => _openAddEditUserDialog(context, user: user),
          onToggleStatus: (user) => _openToggleStatusDialog(context, user: user),
          onResetPassword: (user) => _openResetPasswordDialog(context, user: user),
          onDelete: (user) => _openDeleteUserDialog(context, user: user),
        ),
      ),
    );
  }

  void _openAddEditUserDialog(BuildContext context, {StaffUserModel? user}) {
    final cubit = context.read<StaffUsersCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AddEditStaffUserDialog(user: user),
      ),
    );
  }

  void _openToggleStatusDialog(BuildContext context, {required StaffUserModel user}) {
    final cubit = context.read<StaffUsersCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: ToggleUserStatusDialog(user: user),
      ),
    );
  }

  void _openResetPasswordDialog(BuildContext context, {required StaffUserModel user}) {
    final cubit = context.read<StaffUsersCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: ResetPasswordDialog(user: user),
      ),
    );
  }

  void _openDeleteUserDialog(BuildContext context, {required StaffUserModel user}) {
    final cubit = context.read<StaffUsersCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: DeleteStaffUserDialog(user: user),
      ),
    );
  }

  void _openRolesMatrixDialog(BuildContext context) {
    final cubit = context.read<StaffUsersCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const RolePermissionsMatrixDialog(),
      ),
    );
  }
}
