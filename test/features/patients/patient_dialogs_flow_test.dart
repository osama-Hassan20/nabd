import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/kinship_relations.dart';
import 'package:eyadty/features/patients/data/repo/medical_catalog_mock_repo_impl.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_medical_catalog_item_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/archive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/delete_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/find_patients_by_phone_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_medical_catalog_items_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patient_by_id_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patients_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/unarchive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/update_patient_use_case.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/widgets/add_edit_patient_dialog.dart';
import 'package:eyadty/features/patients/presentation/widgets/form_components/blood_group_selector.dart';
import 'package:eyadty/features/patients/presentation/widgets/form_components/kinship_chips_selector.dart';
import 'package:eyadty/features/patients/presentation/widgets/quick_add_patient_dialog.dart';

PatientsCubit createTestPatientsCubit() {
  final bookingsRepo = BookingsMockRepoImpl();
  final patientsRepo = PatientsMockRepoImpl(bookingsRepo: bookingsRepo);
  final catalogRepo = MedicalCatalogMockRepoImpl();

  return PatientsCubit(
    getPatientsUseCase: GetPatientsUseCase(repo: patientsRepo),
    getPatientByIdUseCase: GetPatientByIdUseCase(repo: patientsRepo),
    addPatientUseCase: AddPatientUseCase(repo: patientsRepo),
    updatePatientUseCase: UpdatePatientUseCase(repo: patientsRepo),
    deletePatientUseCase: DeletePatientUseCase(repo: patientsRepo),
    archivePatientUseCase: ArchivePatientUseCase(repo: patientsRepo),
    unarchivePatientUseCase: UnarchivePatientUseCase(repo: patientsRepo),
    findPatientsByPhoneUseCase: FindPatientsByPhoneUseCase(repo: patientsRepo),
    getMedicalCatalogItemsUseCase: GetMedicalCatalogItemsUseCase(repo: catalogRepo),
    addMedicalCatalogItemUseCase: AddMedicalCatalogItemUseCase(repo: catalogRepo),
    getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
    deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
    changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
    reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
  );
}

Widget wrapWithTestApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: true,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('PatientsCubit Form Flow & Multi-tab Validation Tests', () {
    late PatientsCubit cubit;

    setUp(() {
      cubit = createTestPatientsCubit();
      cubit.initPatientForm(null);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial form state defaults: phoneHasWhatsapp is true, activeTab is 0', () {
      final form = cubit.state.formState;
      expect(form, isNotNull);
      expect(form!.phoneHasWhatsapp, isTrue);
      expect(cubit.state.activeFormTab, 0);
      expect(cubit.state.formTabsWithErrors, isEmpty);
    });

    test('Manual DateOfBirth update recalculates age and toggles child status', () {
      // 8 years old
      cubit.updateFormDateOfBirth(DateTime(2018, 5, 1));
      expect(cubit.state.formState?.isChild, isTrue);
      expect(cubit.state.formState?.ageYears, greaterThanOrEqualTo(7));

      // 30 years old
      cubit.updateFormDateOfBirth(DateTime(1996, 5, 1));
      expect(cubit.state.formState?.isChild, isFalse);
    });

    test('Switching gender resets female-specific fields (isPregnant, isNursing, LMP)', () {
      // Set to female and set pregnant/nursing/LMP
      cubit.updateFormGender(GenderEnum.female);
      cubit.updateFormIsPregnant(true);
      cubit.updateFormIsNursing(true);
      cubit.updateFormLastMenstrualPeriodDate(DateTime(2026, 10, 1));

      expect(cubit.state.formState?.isPregnant, isTrue);
      expect(cubit.state.formState?.isNursing, isTrue);
      expect(cubit.state.formState?.lastMenstrualPeriodDate, isNotNull);

      // Change gender to male -> female fields are cleared
      cubit.updateFormGender(GenderEnum.male);
      expect(cubit.state.formState?.isPregnant, isFalse);
      expect(cubit.state.formState?.isNursing, isFalse);
      expect(cubit.state.formState?.lastMenstrualPeriodDate, isNull);
    });

    test('Tags management: adds and removes allergies and chronic diseases', () {
      cubit.addAllergy('حساسية سلفا');
      expect(cubit.state.formState?.allergies, contains('حساسية سلفا'));

      // Adding duplicate doesn't create duplicate
      cubit.addAllergy('حساسية سلفا');
      expect(cubit.state.formState?.allergies.length, 1);

      cubit.removeAllergy('حساسية سلفا');
      expect(cubit.state.formState?.allergies, isEmpty);

      cubit.addChronicDisease('ضغط الدم المرتفع');
      expect(cubit.state.formState?.chronicDiseases, contains('ضغط الدم المرتفع'));

      cubit.removeChronicDisease('ضغط الدم المرتفع');
      expect(cubit.state.formState?.chronicDiseases, isEmpty);
    });

    test('Height and weight changes compute live BMI', () {
      cubit.updateFormHeight(175);
      cubit.updateFormWeight(70);

      // BMI = 70 / (1.75 * 1.75) = 70 / 3.0625 = 22.86
      final bmi = cubit.state.formState?.calculatedBmi;
      expect(bmi, isNotNull);
      expect(bmi, closeTo(22.85, 0.05));
    });

    test('Multi-tab validation: detects error in tab 0 for empty form and switches tab', () async {
      // Empty form has errors in tab 0 (name, phone)
      final errorTabs = cubit.validateAllTabs();
      expect(errorTabs, contains(0));

      // Attempt to save -> blocks save and highlights tab
      await cubit.savePatient();
      expect(cubit.state.formTabsWithErrors, contains(0));
      expect(cubit.state.activeFormTab, 0);
    });

    test('Multi-tab validation: detects missing guardian for child in tab 0', () {
      // Fill name and phone
      cubit.updateFormName('الطفل خالد');
      cubit.updateFormPhone('01011223344');
      // Set child DOB without guardian
      cubit.updateFormDateOfBirth(DateTime(2020, 1, 1)); // 6 years old

      final errorTabs = cubit.validateAllTabs();
      expect(errorTabs, contains(0)); // Guardian name and phone required
    });
  });

  group('Patient Form Components Widget Tests', () {
    testWidgets('BloodGroupSelector renders 8 chips with LTR directionality', (tester) async {
      BloodGroupEnum? selectedGroup = BloodGroupEnum.oPositive;

      await tester.pumpWidget(
        wrapWithTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return BloodGroupSelector(
                selectedGroup: selectedGroup,
                onSelected: (group) {
                  setState(() {
                    selectedGroup = group;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Renders all 8 blood groups
      expect(find.text('O+'), findsOneWidget);
      expect(find.text('O-'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);
      expect(find.text('A-'), findsOneWidget);
      expect(find.text('B+'), findsOneWidget);
      expect(find.text('B-'), findsOneWidget);
      expect(find.text('AB+'), findsOneWidget);
      expect(find.text('AB-'), findsOneWidget);

      // Verify Directionality widget is LTR
      final ltrFinders = find.byWidgetPredicate((widget) =>
          widget is Directionality && widget.textDirection == TextDirection.ltr);
      expect(ltrFinders, findsWidgets);

      // Tap on B+
      await tester.tap(find.text('B+'));
      await tester.pumpAndSettle();
      expect(selectedGroup, BloodGroupEnum.bPositive);
    });

    testWidgets('KinshipChipsSelector displays preset options and shows custom text field on "other"', (tester) async {
      String? currentRelation = 'relation_father';

      await tester.pumpWidget(
        wrapWithTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return KinshipChipsSelector(
                selectedRelation: currentRelation,
                options: KinshipRelations.emergencyContactOptions,
                onChanged: (val) {
                  setState(() {
                    currentRelation = val;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "أب" should be rendered
      expect(find.text('أب'), findsOneWidget);
      // "أخرى" chip should be rendered
      expect(find.text('أخرى'), findsOneWidget);

      // Tap "أخرى"
      await tester.tap(find.text('أخرى'));
      await tester.pumpAndSettle();

      // Custom relation text field appears
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Patient Dialogs Widget Tests', () {
    late PatientsCubit cubit;

    setUp(() {
      cubit = createTestPatientsCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('QuickAddPatientDialog renders correctly with WhatsApp checkbox', (tester) async {
      cubit.initPatientForm(null);

      await tester.pumpWidget(
        wrapWithTestApp(
          QuickAddPatientDialog(
            cubit: cubit,
            isFullScreen: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddPatientDialog), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('AddEditPatientDialog renders and shows female section dynamically', (tester) async {
      cubit.initPatientForm(null);

      await tester.pumpWidget(
        wrapWithTestApp(
          AddEditPatientDialog(
            patientsCubit: cubit,
            isFullScreen: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddEditPatientDialog), findsOneWidget);

      // Switch to tab 1 (Medical info)
      cubit.updateFormActiveTab(1);
      await tester.pumpAndSettle();

      // By default no female section since gender is unknown
      expect(find.text('female_health_details'.tr()), findsNothing);

      // Switch to female gender
      cubit.updateFormGender(GenderEnum.female);
      await tester.pumpAndSettle();

      // Female section appears
      expect(find.text('female_health_details'.tr()), findsOneWidget);

      // Switch back to male gender
      cubit.updateFormGender(GenderEnum.male);
      await tester.pumpAndSettle();

      // Female section disappears
      expect(find.text('female_health_details'.tr()), findsNothing);
    });
  });
}
