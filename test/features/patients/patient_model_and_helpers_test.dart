import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/patients/data/models/egyptian_governorates.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/kinship_relations.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/data/repo/medical_catalog_mock_repo_impl.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRoleProvider implements CurrentRoleProvider {
  @override
  UserRoleEnum currentRole;

  MockRoleProvider(this.currentRole);
}

void main() {
  group('ArabicTextHelper Tests', () {
    test('Normalizes alefs, teh marbuta, alef maksura, diacritics, and tatweel', () {
      expect(ArabicTextHelper.normalize('أحمد'), 'احمد');
      expect(ArabicTextHelper.normalize('إبراهيم'), 'ابراهيم');
      expect(ArabicTextHelper.normalize('آمنة'), 'امنه');
      expect(ArabicTextHelper.normalize('فاطمة'), 'فاطمه');
      expect(ArabicTextHelper.normalize('مستشفى'), 'مستشفي');
      expect(ArabicTextHelper.normalize('مُحَمَّدٌ'), 'محمد');
      expect(ArabicTextHelper.normalize('عــــادل'), 'عادل');
      expect(ArabicTextHelper.normalize(null), '');
    });

    test('containsNormalized correctly matches Arabic variations', () {
      expect(ArabicTextHelper.containsNormalized('إبراهيم أحمد علي', 'ابراهيم'), isTrue);
      expect(ArabicTextHelper.containsNormalized('منى كمال', 'مني'), isTrue);
      expect(ArabicTextHelper.containsNormalized('حساسية سلفا شديدة', 'السلفا'), isFalse);
      expect(ArabicTextHelper.containsNormalized('حساسية سلفا', 'سلفا'), isTrue);
      expect(ArabicTextHelper.containsNormalized('محمد', ''), isTrue);
      expect(ArabicTextHelper.containsNormalized(null, 'محمد'), isFalse);
      expect(ArabicTextHelper.containsNormalized('محمد', null), isFalse);
    });
  });

  group('EgyptianGovernorates Tests', () {
    test('Cairo, Giza, and Alexandria are first 3 governorates', () {
      expect(EgyptianGovernorates.list.length, 28);
      expect(EgyptianGovernorates.list[0].key, 'gov_cairo');
      expect(EgyptianGovernorates.list[1].key, 'gov_giza');
      expect(EgyptianGovernorates.list[2].key, 'gov_alexandria');
    });

    test('All keys are accessible and unique', () {
      final keys = EgyptianGovernorates.keys;
      expect(keys.length, 28);
      expect(keys.toSet().length, 28);
    });

    test('getDisplayName returns key if not found or returns null for null', () {
      expect(EgyptianGovernorates.getDisplayName(null), isNull);
      expect(EgyptianGovernorates.getDisplayName('non_existent_key'), 'non_existent_key');
    });
  });

  group('KinshipRelations Tests', () {
    test('Contains standard emergency contact and guardian preset keys', () {
      final emergencyKeys = KinshipRelations.emergencyContactOptions.map((o) => o.key).toList();
      expect(emergencyKeys, containsAll(['relation_father', 'relation_mother', 'relation_spouse', 'relation_other']));

      final guardianKeys = KinshipRelations.guardianOptions.map((o) => o.key).toList();
      expect(guardianKeys, containsAll(['relation_father', 'relation_mother', 'relation_grandfather', 'relation_other']));
    });

    test('displayRelation displays custom relation if not found in preset', () {
      expect(KinshipRelations.displayRelation(null), '-');
      expect(KinshipRelations.displayRelation(''), '-');
      expect(KinshipRelations.displayRelation('ابن عم'), 'ابن عم');
    });
  });

  group('MedicalCatalogItemModel and MockRepo Tests', () {
    late MedicalCatalogMockRepoImpl catalogRepo;

    setUp(() {
      catalogRepo = MedicalCatalogMockRepoImpl();
    });

    test('Initializes with seed allergies and chronic diseases', () async {
      final allergiesRes = await catalogRepo.getCatalogItems(type: 'allergy');
      expect(allergiesRes.isRight(), isTrue);
      allergiesRes.fold((l) => fail(l.errMessage), (items) {
        expect(items.length, greaterThanOrEqualTo(10));
        expect(items.any((i) => i.name == 'بنسلين'), isTrue);
        expect(items.any((i) => i.name == 'سلفا'), isTrue);
      });

      final chronicRes = await catalogRepo.getCatalogItems(type: 'chronic_disease');
      expect(chronicRes.isRight(), isTrue);
      chronicRes.fold((l) => fail(l.errMessage), (items) {
        expect(items.length, greaterThanOrEqualTo(10));
        expect(items.any((i) => i.name == 'سكري النوع الأول'), isTrue);
        expect(items.any((i) => i.name == 'ارتفاع ضغط الدم'), isTrue);
      });
    });

    test('Searches items with Arabic normalization', () async {
      final res = await catalogRepo.getCatalogItems(type: 'allergy', query: 'اسبرين');
      expect(res.isRight(), isTrue);
      res.fold((l) => fail(l.errMessage), (items) {
        // Matches 'أسبرين' via normalization
        expect(items.any((i) => i.name?.contains('أسبرين') ?? false), isTrue);
      });
    });

    test('addCatalogItem adds new item and avoids duplicate insertions', () async {
      final addRes = await catalogRepo.addCatalogItem(name: 'حساسية فراولة', type: 'allergy');
      expect(addRes.isRight(), isTrue);
      addRes.fold((l) => fail(l.errMessage), (item) {
        expect(item.name, 'حساسية فراولة');
        expect(item.type, 'allergy');
      });

      // Adding identical or normalized item returns existing item
      final dupRes = await catalogRepo.addCatalogItem(name: '  حساسية فراولة  ', type: 'allergy');
      expect(dupRes.isRight(), isTrue);
      dupRes.fold((l) => fail(l.errMessage), (item) {
        expect(item.name, 'حساسية فراولة');
      });

      // Empty name validation
      final emptyRes = await catalogRepo.addCatalogItem(name: '   ', type: 'allergy');
      expect(emptyRes.isLeft(), isTrue);
    });
  });

  group('EgyptianPhoneHelper Tests', () {
    test('Normalizes Egyptian mobile variations to +20XXXXXXXXXX', () {
      expect(EgyptianPhoneHelper.normalize('01012345678'), '+201012345678');
      expect(EgyptianPhoneHelper.normalize('1012345678'), '+201012345678');
      expect(EgyptianPhoneHelper.normalize('+201012345678'), '+201012345678');
      expect(EgyptianPhoneHelper.normalize('+20 10 1234 5678'), '+201012345678');
      expect(EgyptianPhoneHelper.normalize('00201012345678'), '+201012345678');
    });

    test('Validates Egyptian mobile prefixes (010, 011, 012, 015)', () {
      expect(EgyptianPhoneHelper.isValid('+201012345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('+201112345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('+201212345678'), isTrue);
      expect(EgyptianPhoneHelper.isValid('+201512345678'), isTrue);

      // Invalid prefixes
      expect(EgyptianPhoneHelper.isValid('+201312345678'), isFalse);
      expect(EgyptianPhoneHelper.isValid('+201412345678'), isFalse);
      expect(EgyptianPhoneHelper.isValid('0101234'), isFalse);
    });

    test('Formats for display correctly', () {
      expect(EgyptianPhoneHelper.formatDisplay('+201012345678'), '010 1234 5678');
      expect(EgyptianPhoneHelper.formatDisplayWithCode('+201012345678'), '+20 10 1234 5678');
    });
  });

  group('PatientModel Helpers & Calculations', () {
    test('Contains exactly 44 fields', () {
      final now = DateTime(2026, 11, 7);
      final lmp = DateTime(2026, 10, 15);
      final p = PatientModel(
        id: 'PAT-000101',
        fileNumber: 'PAT-000101',
        name: 'سارة أحمد عبد الله',
        phone: '+201012345678',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1995, 5, 12),
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.oPositive,
        allergies: const ['حساسية بنسلين'],
        chronicDiseases: const ['ربو شعبي'],
        heightCm: 165,
        weightKg: 62,
        isPregnant: true,
        isNursing: false,
        lastMenstrualPeriodDate: lmp,
        governorate: 'gov_cairo',
        city: 'مدينة نصر',
        detailedAddress: 'شارع عباس العقاد',
        emergencyContactName: 'أحمد عبد الله',
        emergencyContactPhone: '+201099887766',
        emergencyContactRelation: 'relation_father',
        guardianName: null,
        guardianPhone: null,
        guardianRelation: null,
        insuranceCompany: 'بوبا مصر',
        insurancePolicyNumber: 'BUP-12345',
        insuranceCoveragePercent: 80,
        internalNotes: 'ملاحظات سريرية داخلية',
        isArchived: false,
        archivedAt: null,
        archiveReason: null,
        totalVisitsCount: 5,
        outstandingBalance: 150,
        totalPaidAmount: 850,
        lastVisitDate: now.subtract(const Duration(days: 7)),
        nextAppointmentDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      );

      // Verify all 44 fields are assigned
      expect(p.props.length, 44);
      expect(p.phoneHasWhatsapp, isTrue);
      expect(p.lastMenstrualPeriodDate, lmp);
      expect(p.detailedAddress, 'شارع عباس العقاد');
      expect(p.internalNotes, 'ملاحظات سريرية داخلية');

      // Verify copyWith works for new fields
      final copy = p.copyWith(
        phoneHasWhatsapp: false,
        clearLmpDate: true,
      );
      expect(copy.phoneHasWhatsapp, isFalse);
      expect(copy.lastMenstrualPeriodDate, isNull);

      // Verify JSON serialization roundtrip
      final json = p.toJson();
      final fromJson = PatientModel.fromJson(json);
      expect(fromJson.id, p.id);
      expect(fromJson.phoneHasWhatsapp, p.phoneHasWhatsapp);
      expect(fromJson.detailedAddress, p.detailedAddress);
      expect(fromJson.internalNotes, p.internalNotes);
    });

    test('Calculates age and child status correctly with customNow', () {
      final dobAdult = DateTime(1995, 5, 12);
      final pAdult = PatientModel(dateOfBirth: dobAdult);
      final now = DateTime(2026, 11, 7);

      expect(pAdult.calculateAgeYears(customNow: now), 31);
      expect(pAdult.isChild(customNow: now), isFalse);

      final dobChild = DateTime(2016, 2, 15);
      final pChild = PatientModel(dateOfBirth: dobChild);
      expect(pChild.calculateAgeYears(customNow: now), 10);
      expect(pChild.isChild(customNow: now), isTrue);

      // Boundary: Exactly turns 18 today (not a child)
      final dob18Today = DateTime(2008, 11, 7);
      final p18Today = PatientModel(dateOfBirth: dob18Today);
      expect(p18Today.calculateAgeYears(customNow: now), 18);
      expect(p18Today.isChild(customNow: now), isFalse);

      // Boundary: Exactly 17 years and 364 days (born tomorrow 18 years ago -> still child)
      final dobAlmost18 = DateTime(2008, 11, 8);
      final pAlmost18 = PatientModel(dateOfBirth: dobAlmost18);
      expect(pAlmost18.calculateAgeYears(customNow: now), 17);
      expect(pAlmost18.isChild(customNow: now), isTrue);
    });

    test('Calculates BMI correctly', () {
      const p = PatientModel(heightCm: 180, weightKg: 81);
      // BMI = 81 / (1.8 * 1.8) = 81 / 3.24 = 25.0
      expect(p.calculatedBmi, closeTo(25.0, 0.01));
    });

    test('Enums defensive parsing', () {
      expect(GenderEnum.fromValue(null), GenderEnum.unknown);
      expect(GenderEnum.fromValue('invalid'), GenderEnum.unknown);
      expect(GenderEnum.fromValue('male'), GenderEnum.male);
      expect(GenderEnum.fromValue('female'), GenderEnum.female);

      expect(BloodGroupEnum.fromValue(null), BloodGroupEnum.unknown);
      expect(BloodGroupEnum.fromValue('O+'), BloodGroupEnum.oPositive);
      expect(BloodGroupEnum.fromValue('b-'), BloodGroupEnum.bNegative);
      expect(BloodGroupEnum.fromValue('invalid'), BloodGroupEnum.unknown);
    });

    test('hasIncompleteProfile flag is true ONLY when DOB or gender are missing or unknown', () {
      // DOB missing
      const noDob = PatientModel(
        dateOfBirth: null,
        gender: GenderEnum.female,
      );
      expect(noDob.hasIncompleteProfile, isTrue);

      // Gender missing
      final noGender = PatientModel(
        dateOfBirth: DateTime(1990, 1, 1),
        gender: null,
      );
      expect(noGender.hasIncompleteProfile, isTrue);

      // Gender unknown
      final unknownGender = PatientModel(
        dateOfBirth: DateTime(1990, 1, 1),
        gender: GenderEnum.unknown,
      );
      expect(unknownGender.hasIncompleteProfile, isTrue);

      // Complete profile: has DOB and known gender, even if all other fields are null
      final minimalComplete = PatientModel(
        dateOfBirth: DateTime(1990, 1, 1),
        gender: GenderEnum.male,
        bloodGroup: null,
        detailedAddress: null,
        emergencyContactName: null,
      );
      expect(minimalComplete.hasIncompleteProfile, isFalse);
    });
  });

  group('PatientsMockRepoImpl Tests', () {
    test('Initializes with seed patients, correctly separates active vs archived', () async {
      final repo = PatientsMockRepoImpl();

      final activeRes = await repo.getPatients(params: const PaginationParams(page: 1, limit: 10));
      expect(activeRes.isRight(), isTrue);
      activeRes.fold((l) => fail(l.errMessage), (r) {
        expect(r.items?.length, 8); // PAT-000101 to PAT-000105 + PAT-000107, 108, 109
        expect(r.items?.any((p) => p.id == 'PAT-000106'), isFalse);
      });

      final archivedRes = await repo.getPatients(
        params: const PaginationParams(page: 1, limit: 10),
        isArchived: true,
      );
      expect(archivedRes.isRight(), isTrue);
      archivedRes.fold((l) => fail(l.errMessage), (r) {
        expect(r.items?.length, 1);
        expect(r.items?.first.id, 'PAT-000106');
        expect(r.items?.first.isArchived, isTrue);
      });
    });

    test('Data consistency between BookingsMockRepoImpl and PatientsMockRepoImpl', () async {
      final bookingsRepo = BookingsMockRepoImpl();
      final patientsRepo = PatientsMockRepoImpl(bookingsRepo: bookingsRepo);

      final activeRes = await patientsRepo.getPatients(
        params: const PaginationParams(page: 1, limit: 10),
      );
      expect(activeRes.isRight(), isTrue);

      final allPatients = await patientsRepo.getPatients(
        params: const PaginationParams(page: 1, limit: 20),
        isArchived: false,
      );
      final archivedPatients = await patientsRepo.getPatients(
        params: const PaginationParams(page: 1, limit: 20),
        isArchived: true,
      );

      final combinedIds = [
        ...allPatients.getOrElse(() => throw 'error').items!.map((p) => p.id),
        ...archivedPatients.getOrElse(() => throw 'error').items!.map((p) => p.id),
      ];

      // 1. Every patientId in bookings exists in patients
      for (final b in bookingsRepo.bookings) {
        if (b.patientId != null) {
          expect(
            combinedIds.contains(b.patientId),
            isTrue,
            reason: 'Booking ${b.id} references patient ${b.patientId} which should exist in patients list',
          );
        }
      }

      // 2. PAT-000105 debt is derived strictly from completed bookings (0 EGP, MED-105 not completed)
      final pat105Res = await patientsRepo.getPatientById(id: 'PAT-000105');
      pat105Res.fold((l) => fail(l.errMessage), (pat105) {
        expect(pat105.outstandingBalance, 0);
      });

      // 3. PAT-000102 debt is derived strictly from completed bookings (150 EGP from MED-107)
      final pat102Res = await patientsRepo.getPatientById(id: 'PAT-000102');
      pat102Res.fold((l) => fail(l.errMessage), (pat102) {
        expect(pat102.outstandingBalance, 150);
      });
    });

    test('Duplicate phone emits warning by default and allows bypass via allowDuplicatePhone', () async {
      final repo = PatientsMockRepoImpl();

      // Duplicate phone without flag -> Returns DuplicatePhoneWarningFailure
      final dupPhoneRes = await repo.addPatient(
        patient: const PatientModel(
          name: 'مريض تجريبي مكرر',
          phone: '01012345678', // Same as PAT-000101
        ),
      );
      expect(dupPhoneRes.isLeft(), isTrue);

      // Duplicate phone with allowDuplicatePhone: true -> Succeeds
      final allowedRes = await repo.addPatient(
        patient: const PatientModel(
          name: 'مريض تجريبي مكرر مسموح',
          phone: '01012345678',
        ),
        allowDuplicatePhone: true,
      );
      expect(allowedRes.isRight(), isTrue);
    });

    test('findPatientsByPhone finds all non-archived matching patients', () async {
      final repo = PatientsMockRepoImpl();

      final searchRes = await repo.findPatientsByPhone(phone: '01012345678');
      expect(searchRes.isRight(), isTrue);
      searchRes.fold((l) => fail(l.errMessage), (matches) {
        expect(matches.isNotEmpty, isTrue);
        expect(matches.any((p) => p.id == 'PAT-000101'), isTrue);
      });
    });

    test('Enforces child guardian requirement on add', () async {
      final repo = PatientsMockRepoImpl();

      final childWithoutGuardian = await repo.addPatient(
        patient: PatientModel(
          name: 'طفل تجريبي',
          phone: '01099112233',
          dateOfBirth: DateTime(2018, 5, 1), // 8 years old
        ),
      );
      expect(childWithoutGuardian.isLeft(), isTrue);

      final childWithGuardian = await repo.addPatient(
        patient: PatientModel(
          name: 'طفل تجريبي 2',
          phone: '01099112244',
          dateOfBirth: DateTime(2018, 5, 1),
          guardianName: 'الأب التجريبي',
          guardianPhone: '01099112255',
        ),
      );
      expect(childWithGuardian.isRight(), isTrue);
    });

    test('Rejects archiving a patient with debt balance', () async {
      final repo = PatientsMockRepoImpl();

      // PAT-000102 has 150 EGP debt
      final debtArchive = await repo.archivePatient(id: 'PAT-000102');
      expect(debtArchive.isLeft(), isTrue);
      debtArchive.fold((failure) {
        expect(failure.errMessage.contains('مديونية'), isTrue);
      }, (_) => fail('Should have failed'));
    });

    test('Rejects archiving a patient with upcoming appointments', () async {
      final repo = PatientsMockRepoImpl();

      // PAT-000101 has upcoming appointment today
      final upcomingArchive = await repo.archivePatient(id: 'PAT-000101');
      expect(upcomingArchive.isLeft(), isTrue);
      upcomingArchive.fold((failure) {
        expect(failure.errMessage.contains('كشوفات قادمة') || failure.errMessage.contains('حجوزات'), isTrue);
      }, (_) => fail('Should have failed'));
    });

    test('Allows valid unarchive of archived patient', () async {
      final repo = PatientsMockRepoImpl();

      // PAT-000106 is archived -> unarchive it
      final unarchiveRes = await repo.unarchivePatient(id: 'PAT-000106');
      expect(unarchiveRes.isRight(), isTrue);

      final verify = await repo.getPatientById(id: 'PAT-000106');
      verify.fold((l) => fail(l.errMessage), (p) {
        expect(p.isArchived, isFalse);
      });
    });
  });
}
