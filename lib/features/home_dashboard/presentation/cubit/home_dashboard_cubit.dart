import 'package:eyadty/core/base/safe_cubit.dart';
import 'home_dashboard_state.dart';

class HomeDashboardCubit extends SafeCubit<HomeDashboardState> {
  HomeDashboardCubit() : super(const HomeDashboardState());

  void init() {
    // Ready for future dashboard data loading
  }
}
