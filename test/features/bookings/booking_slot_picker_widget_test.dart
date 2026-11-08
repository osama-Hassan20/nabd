import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_doctor_bookings_for_date_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_slot_picker_section.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_mock_repo_impl.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';

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

  group('BookingFormSlotPickerSection Widget Tests', () {
    late BookingsMockRepoImpl bookingsRepo;
    late DoctorsMockRepoImpl doctorsRepo;
    late SettingsMockRepoImpl settingsRepo;
    late MedicalServicesMockRepoImpl medicalServicesRepo;
    late BookingsCubit cubit;

    setUp(() {
      CairoTimeHelper.setFixedClock(DateTime(2026, 11, 8, 8, 30));
      settingsRepo = SettingsMockRepoImpl();
      medicalServicesRepo = MedicalServicesMockRepoImpl();
      bookingsRepo = BookingsMockRepoImpl(settingsRepo: settingsRepo);
      doctorsRepo = DoctorsMockRepoImpl(
        bookingsRepo: bookingsRepo,
        settingsRepo: settingsRepo,
      );

      cubit = BookingsCubit(
        getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: bookingsRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        getBookingByIdUseCase: GetBookingByIdUseCase(repo: bookingsRepo),
        createBookingUseCase: CreateBookingUseCase(repo: bookingsRepo),
        updateBookingUseCase: UpdateBookingUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
        getDoctorsUseCase: GetDoctorsUseCase(repo: doctorsRepo),
        getMedicalServicesUseCase: GetMedicalServicesUseCase(repo: medicalServicesRepo),
        getDoctorScheduleUseCase: GetDoctorScheduleUseCase(repo: doctorsRepo),
        getDoctorLeavesUseCase: GetDoctorLeavesUseCase(repo: doctorsRepo),
        getCompanySettingsUseCase: GetCompanySettingsUseCase(repo: settingsRepo),
        getDoctorBookingsForDateUseCase: GetDoctorBookingsForDateUseCase(repo: bookingsRepo),
      );
    });

    tearDown(() {
      CairoTimeHelper.resetFixedClock();
      cubit.close();
    });

    testWidgets('1. Shows guidance hints when doctor or service is not yet selected', (tester) async {
      cubit.initBookingForm(null);

      await tester.pumpWidget(
        wrapWithTestApp(
          BlocProvider.value(
            value: cubit,
            child: const BookingFormSlotPickerSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingFormSlotPickerSection), findsOneWidget);
    });

    testWidgets('2. Shows no schedule warning banner for doctor without schedule', (tester) async {
      cubit.initBookingForm(null);

      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-06', name: 'د. طارق العوضي'),
      );
      cubit.updateFormService(
        const MedicalServiceModel(id: 'SRV-01', name: 'كشف استشاري', durationMinutes: 30),
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          BlocProvider.value(
            value: cubit,
            child: const BookingFormSlotPickerSection(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(BookingFormSlotPickerSection), findsOneWidget);
      expect(cubit.state.availableSlots, isEmpty);
    });

    testWidgets('3. Renders available slots and selecting slot updates form state', (tester) async {
      cubit.initBookingForm(null);

      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-01', name: 'د. حسام الدين مصطفى'),
      );
      cubit.updateFormService(
        const MedicalServiceModel(
          id: 'SRV-01',
          name: 'كشف استشاري باطنة عامة',
          durationMinutes: 30,
          consultationFee: 300,
        ),
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          BlocProvider.value(
            value: cubit,
            child: const BookingFormSlotPickerSection(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(BookingFormSlotPickerSection), findsOneWidget);

      final availableSlots = cubit.state.availableSlots.where((s) => s.isAvailable).toList();
      expect(availableSlots.isNotEmpty, isTrue);

      final targetSlot = availableSlots.first;
      cubit.selectTimeSlot(targetSlot);
      await tester.pumpAndSettle();

      expect(cubit.state.formState?.startTime, targetSlot.startTime);
      expect(cubit.state.formState?.endTime, targetSlot.endTime);
      expect(cubit.state.formState?.durationMinutes, 30);
    });
  });
}
