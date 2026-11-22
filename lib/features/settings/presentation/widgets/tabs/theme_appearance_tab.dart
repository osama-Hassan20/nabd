import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/theme/app_theme_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_theme_mode.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class ThemeAppearanceTab extends StatelessWidget {
  const ThemeAppearanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      bloc: getIt.isRegistered<AppThemeCubit>() ? getIt<AppThemeCubit>() : null,
      builder: (context, state) {
        final currentMode = state.themeMode;
        final colors = context.themeColors;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. Header Information Banner ──────────────────────────────
              _buildHeaderBanner(context, currentMode, colors),
              const SizedBox(height: 24),

              // ─── 2. Multi-Mode Cards Grid ──────────────────────────────────
              Text(
                'theme_mode_title'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'theme_mode_subtitle'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemesGrid(context, currentMode),
              const SizedBox(height: 32),

              // ─── 3. Live Interactive Preview Component ─────────────────────
              _buildLivePreviewCard(context, currentMode, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    AppThemeMode currentMode,
    AppThemeColors colors,
  ) {
    return CustomContainer(
      backGroundColor: colors.surfaceLevel1,
      border: Border.all(color: colors.borderSubtle),
      borderRaduis: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.palette_rounded,
                size: 28,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      'tab_theme_appearance'.tr(),
                      style: CustomAppFontStyle.bold18.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getThemeLabel(currentMode),
                            style: CustomAppFontStyle.bold12.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'tab_theme_appearance_desc'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesGrid(BuildContext context, AppThemeMode activeMode) {
    final cubit = getIt<AppThemeCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount = 1;
        if (availableWidth >= 900) {
          crossAxisCount = 3;
        } else if (availableWidth >= 560) {
          crossAxisCount = 2;
        }

        final itemWidth =
            ((availableWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount)
                .clamp(230.0, 360.0);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppThemeMode.values.map((mode) {
            final isSelected = mode == activeMode;
            final modeColors = AppThemeColors.forMode(mode);

            return SizedBox(
              width: itemWidth,
              child: _ThemeCardItem(
                mode: mode,
                isSelected: isSelected,
                colors: modeColors,
                onTap: () => cubit.setThemeMode(mode),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLivePreviewCard(
    BuildContext context,
    AppThemeMode currentMode,
    AppThemeColors colors,
  ) {
    return CustomContainer(
      backGroundColor: colors.cardBackground,
      border: Border.all(color: colors.borderSubtle, width: 1.5),
      borderRaduis: 20,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.remove_red_eye_rounded, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'theme_preview_card_title'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getThemeLabel(currentMode),
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'theme_preview_sample_text'.tr(),
            style: CustomAppFontStyle.regular13.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Component Sandbox Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Metric Mini-Card Simulation
              Container(
                width: 200,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كشوفات اليوم',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '24 مريضاً',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Primary Action Button
              CustomPushButton(
                height: 42,
                width: 140,
                backgroundColor: colors.primary,
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: colors.textInverse),
                      const SizedBox(width: 6),
                      Text(
                        'إجراء تجريبي',
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: colors.textInverse,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Status Badges
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'نشط ومكتمل',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.fillDisabled,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  'في الانتظار',
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getThemeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'theme_light'.tr();
      case AppThemeMode.dark:
        return 'theme_dark'.tr();
      case AppThemeMode.sunny:
        return 'theme_sunny'.tr();
      case AppThemeMode.night:
        return 'theme_night'.tr();
      case AppThemeMode.emerald:
        return 'theme_emerald'.tr();
    }
  }
}

class _ThemeCardItem extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _ThemeCardItem({
    required this.mode,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = isSelected ? colors.primary : colors.borderSubtle;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeBorderColor,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.activeGlow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Selected Checkmark
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTitle(mode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomAppFontStyle.bold14.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          'theme_active'.tr(),
                          style: CustomAppFontStyle.bold11.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _getDescription(mode),
              style: CustomAppFontStyle.regular12.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Color Swatches Bar
            Row(
              children: [
                _buildSwatch(colors.primary, 'رئيسي'),
                const SizedBox(width: 8),
                _buildSwatch(colors.scaffoldBackground, 'خلفية'),
                const SizedBox(width: 8),
                _buildSwatch(colors.surfaceLevel1, 'حاويات'),
                const SizedBox(width: 8),
                _buildSwatch(colors.textPrimary, 'نصوص'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: colors.borderSubtle,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  String _getTitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'theme_light'.tr();
      case AppThemeMode.dark:
        return 'theme_dark'.tr();
      case AppThemeMode.sunny:
        return 'theme_sunny'.tr();
      case AppThemeMode.night:
        return 'theme_night'.tr();
      case AppThemeMode.emerald:
        return 'theme_emerald'.tr();
    }
  }

  String _getDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'theme_light_desc'.tr();
      case AppThemeMode.dark:
        return 'theme_dark_desc'.tr();
      case AppThemeMode.sunny:
        return 'theme_sunny_desc'.tr();
      case AppThemeMode.night:
        return 'theme_night_desc'.tr();
      case AppThemeMode.emerald:
        return 'theme_emerald_desc'.tr();
    }
  }
}
