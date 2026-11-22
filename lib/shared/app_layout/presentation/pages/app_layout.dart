import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/shared/cubit/basic_cubit.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_side_bar.dart';
import 'package:eyadty/core/layout_adaptive/widgets/screen_adaptive_layout.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/core/utils/constants/app_list.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/shared/app_layout/presentation/widgets/header_layout.dart';
import 'package:eyadty/shared/widgets/custom_full_screen_loading.dart';
import 'package:eyadty/shared/widgets/error_page.dart';
import 'package:eyadty/shared/widgets/local_passcode_lock_screen.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:flutter/material.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key, required this.child, this.title, this.subtitle});
  final Widget child;
  final String? title;
  final String? subtitle;
  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool isLogin = false;
  bool isCollapsed = false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    isLogin = AppSharedPreferences.getString(key: AppConstants.userId) != null;
    // Load profile once for the app session
    context.read<BasicCubit>().loadSharedData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passcodeCubit = getIt.isRegistered<LocalPasscodeCubit>()
        ? getIt<LocalPasscodeCubit>()
        : null;

    return BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
      bloc: passcodeCubit,
      builder: (context, passcodeState) {
        if (passcodeState.isLocked) {
          return const LocalPasscodeLockScreen();
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => passcodeCubit?.recordActivity(),
          onPointerHover: (_) => passcodeCubit?.recordActivity(),
          child: BlocBuilder<BasicCubit, BasicState>(
            builder: (context, state) {
              if (state.profileStatus == RequestStatusEnum.loading) {
                return const Scaffold(
                  body: CustomFullScreenLoading(
                    isLoading: true,
                    typedText: "جار تحميل صلاحياتك",
                    child: SizedBox.expand(),
                  ),
                );
              }

              if (state.profileStatus == RequestStatusEnum.failure) {
                return Scaffold(
                  body: Center(
                    child: ErrorPage(
                      errorMessage: state.errMessage ?? 'فشل في تحميل البيانات',
                      onPressed: () => context.read<BasicCubit>().getProfile(),
                    ),
                  ),
                );
              }

              return BlocBuilder<SessionCubit, SessionState>(
                bloc: getIt.isRegistered<SessionCubit>()
                    ? getIt<SessionCubit>()
                    : null,
                builder: (context, sessionState) {
                  return Scaffold(
                    key: scaffoldKey,
                    backgroundColor: context.themeColors.scaffoldBackground,
                    drawer: CustomDrawer(
                      scaffoldKey: scaffoldKey,
                      items: layoutItems(context),
                    ),
                    body: SafeArea(
                      bottom: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScreenAdaptiveLayout(
                            mobileLayout: (context) => const SizedBox.shrink(),
                            tabletLayout: (context) => const SizedBox.shrink(),
                            desktopLayout: (context) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isCollapsed ? 100 : 270,
                              child: CustomSideBarList(
                                scaffoldKey: scaffoldKey,
                                isMobile: false,
                                isTablet: isCollapsed,
                                items: layoutItems(context),
                                onToggle: () {
                                  setState(() {
                                    isCollapsed = !isCollapsed;
                                  });
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              spacing: 16,
                              children: [
                                SizedBox(
                                  height: AdaptiveLayout.getResponsiveValue(
                                    context: context,
                                    mobile: 82,
                                    tablet: 82,
                                    desktop: 75,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: CustomHeaderLayout(
                                      isLogin: isLogin,
                                      scaffoldKey: scaffoldKey,
                                      title: widget.title,
                                      subtitle: widget.subtitle,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: widget.child,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
