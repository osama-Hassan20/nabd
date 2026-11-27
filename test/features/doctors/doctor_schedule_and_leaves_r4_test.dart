import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_by_id_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/save_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/update_doctor_use_case.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/widgets/doctor_details_sections/doctor_schedule_card_section.dart';
import 'package:eyadty/features/doctors/presentation/widgets/doctor_details_sections/doctor_stats_cards_section.dart';
import 'package:eyadty/features/settings/data/repo/settings_repo_impl.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

Widget wrapWithTestApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ar_EG', null);
    await EasyLocalization.ensureInitialized();
  });

  group('R-4: F-00 Audit & UI Verification Tests', () {
    late DoctorsRepoImpl doctorsRepo;
    late BookingsRepoImpl bookingsRepo;
    late SettingsRepoImpl settingsRepo;
    late DoctorsCubit cubit;

    setUp(() {
      CairoTimeHelper.setFixedClock(DateTime(2026, 11, 8, 8, 30));
      settingsRepo = SettingsRepoImpl();
      bookingsRepo = BookingsRepoImpl(settingsRepo: settingsRepo);
      doctorsRepo = DoctorsRepoImpl(
        bookingsRepo: bookingsRepo,
        settingsRepo: settingsRepo,
      );

      cubit = DoctorsCubit(
        getDoctorsUseCase: GetDoctorsUseCase(repo: doctorsRepo),
        getDoctorByIdUseCase: GetDoctorByIdUseCase(repo: doctorsRepo),
        addDoctorUseCase: AddDoctorUseCase(repo: doctorsRepo),
        updateDoctorUseCase: UpdateDoctorUseCase(repo: doctorsRepo),
        deleteDoctorUseCase: DeleteDoctorUseCase(repo: doctorsRepo),
        getDoctorLeavesUseCase: GetDoctorLeavesUseCase(repo: doctorsRepo),
        addDoctorLeaveUseCase: AddDoctorLeaveUseCase(repo: doctorsRepo),
        deleteDoctorLeaveUseCase: DeleteDoctorLeaveUseCase(repo: doctorsRepo),
        getDoctorScheduleUseCase: GetDoctorScheduleUseCase(repo: doctorsRepo),
        saveDoctorScheduleUseCase: SaveDoctorScheduleUseCase(repo: doctorsRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
      );
    });

    tearDown(() {
      CairoTimeHelper.resetFixedClock();
      cubit.close();
    });

    testWidgets('1. Doctor without schedule displays prominent "تحديد الجدول" button in schedule card', (tester) async {
      // Doctor with no working days defined
      const doc = DoctorModel(
        id: 'DOC-06',
        name: 'د. طارق العوضي',
        phone: '+20 11 6677 8899',
        specialty: 'أنف وأذن وحنجرة',
      );

      cubit.emit(
        cubit.state.copyWith(
          selectedDoctor: doc,
          selectedDoctorSchedule: const DoctorScheduleModel(workDays: []),
        ),
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<DoctorsCubit>.value(value: cubit),
              RepositoryProvider<CurrentRoleProvider?>.value(
                value: SessionCubit(SessionState.initial()),
              ),
            ],
            child: const DoctorScheduleCardSection(doctor: doc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "تحديد الجدول" button should appear both in the banner and in the header
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'تحديد الجدول' || w.data == 'set_schedule'),
        ),
        findsWidgets,
      );
      expect(find.byType(CustomPushButton), findsWidgets);
    });

    testWidgets('2. DoctorStatsCardsSection leaves card has InkWell and is tappable', (tester) async {
      const doc = DoctorModel(
        id: 'DOC-01',
        name: 'د. حسام الدين مصطفى',
        phone: '+20 10 1122 3344',
      );

      cubit.emit(
        cubit.state.copyWith(
          selectedDoctor: doc,
        ),
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          BlocProvider<DoctorsCubit>.value(
            value: cubit,
            child: const DoctorStatsCardsSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify InkWell is present for the tappable cards
      expect(find.byType(InkWell), findsWidgets);
    });

    test('3. EgyptianPhoneHelper validates standard Egyptian mobile prefixes (010, 011, 012, 015)', () {
      expect(EgyptianPhoneHelper.isValid('01012345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('01112345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('01212345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('01512345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('+201012345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('01312345678'), isFalse); // Invalid prefix 013
      expect(EgyptianPhoneHelper.isValid('0101234567'), isFalse); // 10 digits
      expect(EgyptianPhoneHelper.isValid('010123456789'), isFalse); // 12 digits
    });
  });
}
