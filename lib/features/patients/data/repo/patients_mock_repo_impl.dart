import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import '../../domain/repo/patients_repo.dart';
import '../models/enums/blood_group_enum.dart';
import '../models/enums/gender_enum.dart';
import '../models/patient_model.dart';
import '../models/patients_response_model.dart';

class PatientsMockRepoImpl implements PatientsRepo {
  final ApiConsumer? apiConsumer;
  final CurrentRoleProvider? roleProvider;
  final BookingsRepo? bookingsRepo;

  PatientsMockRepoImpl({
    this.apiConsumer,
    this.roleProvider,
    this.bookingsRepo,
  }) {
    _initMockData();
  }

  final List<PatientModel> _patients = [];
  int _sequenceCounter = 109;

  late final BookingsRepo _fallbackBookingsRepo = BookingsMockRepoImpl();

  BookingsRepo get _effectiveBookingsRepo {
    if (bookingsRepo != null) return bookingsRepo!;
    if (getIt.isRegistered<BookingsRepo>()) {
      return getIt<BookingsRepo>();
    }
    return _fallbackBookingsRepo;
  }

  PatientModel _enrichWithBookingStats(PatientModel patient) {
    List<BookingModel> allBookings = const [];
    final repo = _effectiveBookingsRepo;
    if (repo is BookingsMockRepoImpl) {
      allBookings = repo.bookings;
    }

    final patientBookings = allBookings.where((b) {
      return (b.patientId != null && b.patientId == patient.id) ||
          (b.fileNumber != null && b.fileNumber == patient.fileNumber) ||
          (b.customer?.id != null && b.customer!.id == patient.id);
    }).toList();

    final nonCancelled = patientBookings
        .where((b) => b.status != BookingStatusEnum.cancelled)
        .toList();

    final visitsCount = nonCancelled.length;
    final totalPaid = nonCancelled.fold<num>(
      0,
      (sum, b) => sum + (b.paidAmount ?? 0),
    );
    final outstanding = nonCancelled.fold<num>(
      0,
      (sum, b) {
        final fee = b.consultationFee ?? b.totalPrice ?? 0;
        final paid = b.paidAmount ?? 0;
        final due = fee - paid;
        return sum + (due > 0 ? due : 0);
      },
    );

    final now = CairoTimeHelper.now();
    DateTime? lastVisit;
    DateTime? nextAppointment;

    for (final b in nonCancelled) {
      final apt = b.appointmentTime ?? b.date;
      if (apt != null) {
        if (!apt.isAfter(now)) {
          if (lastVisit == null || apt.isAfter(lastVisit)) {
            lastVisit = apt;
          }
        } else {
          if (nextAppointment == null || apt.isBefore(nextAppointment)) {
            nextAppointment = apt;
          }
        }
      }
    }

    return patient.copyWith(
      totalVisitsCount: visitsCount,
      totalPaidAmount: totalPaid,
      outstandingBalance: outstanding,
      lastVisitDate: lastVisit,
      nextAppointmentDate: nextAppointment,
    );
  }

  void _initMockData() {
    final now = CairoTimeHelper.now();

    _patients.addAll([
      // PAT-000101: سارة أحمد عبد الله (31 سنة, O+, حساسية بنسلين)
      PatientModel(
        id: 'PAT-000101',
        fileNumber: 'PAT-000101',
        name: 'سارة أحمد عبد الله',
        phone: '+201012345678',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1995, 5, 12),
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.oPositive,
        allergies: const ['حساسية بنسلين شديدة'],
        chronicDiseases: const [],
        heightCm: 165,
        weightKg: 62,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'المعادي',
        detailedAddress: 'شارع 9، عمارة 42، الدور الثالث',
        emergencyContactName: 'أحمد عبد الله (الوالد)',
        emergencyContactPhone: '+201001122334',
        emergencyContactRelation: 'relation_father',
        insuranceCompany: 'بوبا مصر',
        insurancePolicyNumber: 'BUP-2024-9812',
        insuranceCoveragePercent: 80,
        internalNotes: 'متابعة باطنة دورية وتاريخ عائلي للسكري',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // PAT-000102: يوسف إبراهيم المنصوري (38 سنة, A+, سكري وضغط, مديونية 300 ج.م)
      PatientModel(
        id: 'PAT-000102',
        fileNumber: 'PAT-000102',
        name: 'يوسف إبراهيم المنصوري',
        phone: '+201123456789',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1988, 9, 23),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.aPositive,
        allergies: const [],
        chronicDiseases: const ['سكري النوع الثاني', 'ارتفاع ضغط الدم'],
        heightCm: 178,
        weightKg: 86,
        isPregnant: false,
        isNursing: false,
        governorate: 'الجيزة',
        city: 'الدقي',
        detailedAddress: 'شارع مصدق، برج الأطباء، الدور السادس',
        emergencyContactName: 'منى المنصوري (الزوجة)',
        emergencyContactPhone: '+201144556677',
        emergencyContactRelation: 'relation_spouse',
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: 0,
        internalNotes: 'عليه مديونية سابقة قدرها 300 ج.م لكشف مستعجل',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 240)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),

      // PAT-000103: مريم محمود حسن (10 سنوات, طفل قاصر, B-, حساسية سلفا وأسبرين, ولي أمر)
      PatientModel(
        id: 'PAT-000103',
        fileNumber: 'PAT-000103',
        name: 'مريم محمود حسن',
        phone: '+201234567890',
        phoneHasWhatsapp: false,
        dateOfBirth: DateTime(2016, 2, 15),
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.bNegative,
        allergies: const ['حساسية سلفا', 'حساسية أسبرين'],
        chronicDiseases: const [],
        heightCm: 135,
        weightKg: 32,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'مدينة نصر',
        detailedAddress: 'حي السفارات، عمارة 14',
        emergencyContactName: 'محمود حسن (الأب)',
        emergencyContactPhone: '+201288990011',
        emergencyContactRelation: 'relation_father',
        guardianName: 'محمود حسن',
        guardianPhone: '+201288990011',
        guardianRelation: 'relation_father',
        insuranceCompany: 'مصر للتأمين التكافلي',
        insurancePolicyNumber: 'MISR-CH-7741',
        insuranceCoveragePercent: 90,
        internalNotes: 'طفلة قاصرة - التواصل حصراً عبر ولي الأمر المسجل',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),

      // PAT-000104: طارق عبد الرحمن علي (56 سنة, AB+, أمراض قلب وشرايين, بوبا مصر 80%)
      PatientModel(
        id: 'PAT-000104',
        fileNumber: 'PAT-000104',
        name: 'طارق عبد الرحمن علي',
        phone: '+201545678901',
        phoneHasWhatsapp: null,
        dateOfBirth: DateTime(1970, 11, 5),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.abPositive,
        allergies: const [],
        chronicDiseases: const ['أمراض قلب وشرايين', 'قصور الشريان التاجي'],
        heightCm: 172,
        weightKg: 79,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'التجمع الخامس',
        detailedAddress: 'شارع التسعين الشمالي، كمبوند الياسمين',
        emergencyContactName: 'كريم طارق (الابن)',
        emergencyContactPhone: '+201599887766',
        emergencyContactRelation: 'relation_child',
        insuranceCompany: 'بوبا مصر',
        insurancePolicyNumber: 'BUP-EG-99214',
        insuranceCoveragePercent: 80,
        internalNotes: 'يحتاج قياس دوري للضغط ورسم قلب قبل أي إجراء',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),

      // PAT-000105: منى فاروق الشناوي (ملف غير مكتمل, بدون تاريخ ميلاد)
      PatientModel(
        id: 'PAT-000105',
        fileNumber: 'PAT-000105',
        name: 'منى فاروق الشناوي',
        phone: '+201098765432',
        phoneHasWhatsapp: true,
        dateOfBirth: null,
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.unknown,
        allergies: const [],
        chronicDiseases: const [],
        heightCm: null,
        weightKg: null,
        isPregnant: null,
        isNursing: null,
        governorate: 'الجيزة',
        city: 'الشيخ زايد',
        detailedAddress: 'الحي الأول، مجاورة 2',
        emergencyContactName: null,
        emergencyContactPhone: null,
        emergencyContactRelation: null,
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: null,
        internalNotes: 'سجل مريض سابق من النظام القديم - يتطلب استكمال البيانات',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),

      // PAT-000106: خالد سعيد عبد الرازق (44 سنة, O-, ربو شعبي, مؤرشف)
      PatientModel(
        id: 'PAT-000106',
        fileNumber: 'PAT-000106',
        name: 'خالد سعيد عبد الرازق',
        phone: '+201187654321',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1982, 4, 18),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.oNegative,
        allergies: const [],
        chronicDiseases: const ['ربو شعبي مزمن'],
        heightCm: 175,
        weightKg: 74,
        isPregnant: false,
        isNursing: false,
        governorate: 'الإسكندرية',
        city: 'سموحة',
        detailedAddress: 'شارع فوزي معاذ، برج النور',
        emergencyContactName: 'سعيد عبد الرازق (أخ)',
        emergencyContactPhone: '+201133221100',
        emergencyContactRelation: 'relation_sibling',
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: null,
        internalNotes: 'انتقل للعيش بالإسكندرية وتمت أرشفة الملف بناء على طلبه',
        isArchived: true,
        archivedAt: now.subtract(const Duration(days: 60)),
        archiveReason: 'انتقل للعيش بمحافظة الإسكندرية',
        createdAt: now.subtract(const Duration(days: 400)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),

      // PAT-000107: كريم عادل الشريف (مسجل بالاسم والهاتف فقط - شارة بيانات ناقصة)
      PatientModel(
        id: 'PAT-000107',
        fileNumber: 'PAT-000107',
        name: 'كريم عادل الشريف',
        phone: '+201066778899',
        phoneHasWhatsapp: true,
        dateOfBirth: null,
        gender: null,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),

      // PAT-000108: نادية إبراهيم سالم (أم - هاتف عائلي مشترك)
      PatientModel(
        id: 'PAT-000108',
        fileNumber: 'PAT-000108',
        name: 'نادية إبراهيم سالم',
        phone: '+201555123456',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1990, 8, 14),
        gender: GenderEnum.female,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // PAT-000109: عمر شريف الدسوقي (طفل - يشترك في نفس هاتف الأم +201555123456)
      PatientModel(
        id: 'PAT-000109',
        fileNumber: 'PAT-000109',
        name: 'عمر شريف الدسوقي',
        phone: '+201555123456',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(2018, 3, 20),
        gender: GenderEnum.male,
        guardianName: 'نادية إبراهيم سالم',
        guardianPhone: '+201555123456',
        guardianRelation: 'relation_mother',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    for (int i = 0; i < _patients.length; i++) {
      _patients[i] = _enrichWithBookingStats(_patients[i]);
    }
  }

  @override
  Future<Either<Failures, PatientsResponseModel>> getPatients({
    required PaginationParams params,
    String? search,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    bool? hasDebt,
    bool isArchived = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final allEnriched = _patients.map(_enrichWithBookingStats).toList();
      List<PatientModel> filtered =
          allEnriched.where((p) => (p.isArchived ?? false) == isArchived).toList();

      // Search (by explicit param or filterList)
      String? searchQuery = search;
      if (searchQuery == null || searchQuery.isEmpty) {
        for (final f in params.filterList) {
          if (f.key == 'search' && f.value != null) {
            searchQuery = f.value.toString();
            break;
          }
        }
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final normalizedQuery = EgyptianPhoneHelper.normalize(query) ?? query;

        filtered = filtered.where((p) {
          final nameMatch = (p.name ?? '').toLowerCase().contains(query);
          final phoneClean = (p.phone ?? '').replaceAll(' ', '');
          final queryClean = normalizedQuery.replaceAll(' ', '');
          final phoneMatch =
              phoneClean.contains(queryClean) ||
              (p.phone ?? '').contains(query);
          final fileMatch = (p.fileNumber ?? '').toLowerCase().contains(query);
          return nameMatch || phoneMatch || fileMatch;
        }).toList();
      }

      // Gender filter
      if (gender != null && gender != GenderEnum.unknown) {
        filtered = filtered.where((p) => p.gender == gender).toList();
      }

      // Blood group filter
      if (bloodGroup != null && bloodGroup != BloodGroupEnum.unknown) {
        filtered = filtered.where((p) => p.bloodGroup == bloodGroup).toList();
      }

      // Debt filter
      if (hasDebt == true) {
        filtered =
            filtered.where((p) => (p.outstandingBalance ?? 0) > 0).toList();
      }

      final totalCount = filtered.length;
      final limit = (params.limit ?? 10) > 0 ? (params.limit ?? 10) : 10;
      final totalPages = (totalCount / limit).ceil().clamp(1, 999);
      final page = params.page ?? 1;
      final currentPage = page.clamp(1, totalPages);

      final startIndex = (currentPage - 1) * limit;
      final paginated = startIndex < totalCount
          ? filtered.skip(startIndex).take(limit).toList()
          : <PatientModel>[];

      return Right(
        PatientsResponseModel(
          items: paginated,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: currentPage,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب سجلات المرضى'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> getPatientById({
    required String id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      return Right(_enrichWithBookingStats(_patients[index]));
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب تفاصيل المريض'));
    }
  }

  @override
  Future<Either<Failures, List<PatientModel>>> findPatientsByPhone({
    required String phone,
    String? excludePatientId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final normalized = EgyptianPhoneHelper.normalize(phone.trim());
      if (normalized == null) {
        return const Right([]);
      }

      final matches = _patients.where((p) {
        if (p.isArchived ?? false) return false;
        if (excludePatientId != null && p.id == excludePatientId) return false;
        final pPhone = EgyptianPhoneHelper.normalize(p.phone);
        return pPhone == normalized;
      }).map(_enrichWithBookingStats).toList();

      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر البحث بالهاتف'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> addPatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      // 1. Phone validation & normalization
      final rawPhone = patient.phone?.trim();
      if (rawPhone == null || rawPhone.isEmpty) {
        return Left(ValidationFailure(errMessage: 'رقم الهاتف مطلوب'));
      }

      final normalizedPhone = EgyptianPhoneHelper.normalize(rawPhone);
      if (normalizedPhone == null || !EgyptianPhoneHelper.isValid(normalizedPhone)) {
        return Left(ValidationFailure(
            errMessage: 'رقم الهاتف غير صالح، يجب أن يكون رقم هاتف مصري صحيح'));
      }

      // Check duplicate phone against active patients (warning only if allowDuplicatePhone is false)
      if (!allowDuplicatePhone) {
        final matches = _patients.where((p) {
          if (p.isArchived ?? false) return false;
          final pPhone = EgyptianPhoneHelper.normalize(p.phone);
          return pPhone == normalizedPhone;
        }).toList();

        if (matches.isNotEmpty) {
          return Left(
            DuplicatePhoneWarningFailure(
              errMessage: 'duplicate_phone_warning',
              matchingPatients: matches
                  .map((p) => DuplicatePhonePatientInfo(
                        id: p.id,
                        name: p.name,
                        fileNumber: p.fileNumber,
                        phone: p.phone,
                      ))
                  .toList(),
            ),
          );
        }
      }

      // 2. Child guardian check (< 18 requires guardian)
      if (patient.isChild()) {
        final gName = patient.guardianName?.trim();
        final gPhone = patient.guardianPhone?.trim();
        if (gName == null || gName.isEmpty || gPhone == null || gPhone.isEmpty) {
          return Left(ValidationFailure(
              errMessage:
                  'بيانات ولي الأمر (الاسم ورقم الهاتف) إلزامية للأطفال دون 18 عامًا'));
        }
      }

      // 3. Generate sequential ID & fileNumber
      _sequenceCounter++;
      final seqStr = _sequenceCounter.toString().padLeft(6, '0');
      final newId = 'PAT-$seqStr';
      final now = CairoTimeHelper.now();

      final created = patient.copyWith(
        id: newId,
        fileNumber: newId,
        phone: normalizedPhone,
        phoneHasWhatsapp: patient.phoneHasWhatsapp,
        isArchived: false,
        totalVisitsCount: 0,
        outstandingBalance: 0,
        totalPaidAmount: 0,
        createdAt: now,
        updatedAt: now,
      );

      _patients.insert(0, created);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل إضافة المريض'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> updatePatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final existing = _patients[index];

      // 1. Phone validation & duplicate check (ignoring self)
      String updatedPhone = existing.phone ?? '';
      final candidatePhone = patient.phone?.trim();

      if (candidatePhone != null && candidatePhone.isNotEmpty) {
        final normalized = EgyptianPhoneHelper.normalize(candidatePhone);
        if (normalized == null || !EgyptianPhoneHelper.isValid(normalized)) {
          return Left(ValidationFailure(
              errMessage: 'رقم الهاتف غير صالح، يجب أن يكون رقم هاتف مصري'));
        }

        if (!allowDuplicatePhone) {
          final matches = _patients.where((p) {
            if (p.id == patient.id) return false;
            if (p.isArchived ?? false) return false;
            final pPhone = EgyptianPhoneHelper.normalize(p.phone);
            return pPhone == normalized;
          }).toList();

          if (matches.isNotEmpty) {
            return Left(
              DuplicatePhoneWarningFailure(
                errMessage: 'duplicate_phone_warning',
                matchingPatients: matches
                    .map((p) => DuplicatePhonePatientInfo(
                          id: p.id,
                          name: p.name,
                          fileNumber: p.fileNumber,
                          phone: p.phone,
                        ))
                    .toList(),
              ),
            );
          }
        }
        updatedPhone = normalized;
      }

      // 2. Child guardian check if DOB set
      final candidatePatient = existing.copyWith(
        dateOfBirth: patient.dateOfBirth ?? existing.dateOfBirth,
        guardianName: patient.guardianName ?? existing.guardianName,
        guardianPhone: patient.guardianPhone ?? existing.guardianPhone,
      );
      if (candidatePatient.isChild()) {
        final gName = candidatePatient.guardianName?.trim();
        final gPhone = candidatePatient.guardianPhone?.trim();
        if (gName == null || gName.isEmpty || gPhone == null || gPhone.isEmpty) {
          return Left(ValidationFailure(
              errMessage:
                  'بيانات ولي الأمر (الاسم ورقم الهاتف) إلزامية للأطفال دون 18 عامًا'));
        }
      }

      final updated = existing.copyWith(
        name: patient.name ?? existing.name,
        phone: updatedPhone,
        phoneHasWhatsapp: patient.phoneHasWhatsapp ?? existing.phoneHasWhatsapp,
        lastMenstrualPeriodDate: patient.lastMenstrualPeriodDate ?? existing.lastMenstrualPeriodDate,
        dateOfBirth: patient.dateOfBirth ?? existing.dateOfBirth,
        gender: patient.gender ?? existing.gender,
        bloodGroup: patient.bloodGroup ?? existing.bloodGroup,
        allergies: patient.allergies ?? existing.allergies,
        chronicDiseases: patient.chronicDiseases ?? existing.chronicDiseases,
        heightCm: patient.heightCm ?? existing.heightCm,
        weightKg: patient.weightKg ?? existing.weightKg,
        isPregnant: patient.isPregnant ?? existing.isPregnant,
        isNursing: patient.isNursing ?? existing.isNursing,
        governorate: patient.governorate ?? existing.governorate,
        city: patient.city ?? existing.city,
        detailedAddress: patient.detailedAddress ?? existing.detailedAddress,
        emergencyContactName:
            patient.emergencyContactName ?? existing.emergencyContactName,
        emergencyContactPhone:
            patient.emergencyContactPhone ?? existing.emergencyContactPhone,
        emergencyContactRelation:
            patient.emergencyContactRelation ?? existing.emergencyContactRelation,
        guardianName: patient.guardianName ?? existing.guardianName,
        guardianPhone: patient.guardianPhone ?? existing.guardianPhone,
        guardianRelation:
            patient.guardianRelation ?? existing.guardianRelation,
        insuranceCompany:
            patient.insuranceCompany ?? existing.insuranceCompany,
        insurancePolicyNumber:
            patient.insurancePolicyNumber ?? existing.insurancePolicyNumber,
        insuranceCoveragePercent:
            patient.insuranceCoveragePercent ?? existing.insuranceCoveragePercent,
        internalNotes: patient.internalNotes ?? existing.internalNotes,
        updatedAt: CairoTimeHelper.now(),
      );

      _patients[index] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تحديث بيانات المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> archivePatient({
    required String id,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final patient = _enrichWithBookingStats(_patients[index]);

      // Rejection rules: outstanding balance > 0 or upcoming appointments
      if ((patient.outstandingBalance ?? 0) > 0) {
        return Left(ValidationFailure(
            errMessage:
                'لا يمكن أرشفة ملف المريض لوجود مديونية مستحقة (${patient.outstandingBalance} ج.م)'));
      }

      final now = CairoTimeHelper.now();
      final hasUpcoming = patient.nextAppointmentDate != null &&
          patient.nextAppointmentDate!.isAfter(now);
      if (hasUpcoming) {
        return Left(ValidationFailure(
            errMessage:
                'لا يمكن أرشفة ملف المريض لوجود كشوفات قادمة مجدولة'));
      }

      _patients[index] = patient.copyWith(
        isArchived: true,
        archivedAt: now,
        archiveReason: reason ?? 'أرشفة إدارية',
        updatedAt: now,
      );

      return const Right('تم أرشفة ملف المريض بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل أرشفة ملف المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> unarchivePatient({
    required String id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final patient = _enrichWithBookingStats(_patients[index]);
      _patients[index] = patient.copyWith(
        isArchived: false,
        archivedAt: null,
        archiveReason: null,
        updatedAt: CairoTimeHelper.now(),
      );

      return const Right('تم استعادة ملف المريض بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل استعادة ملف المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> deletePatient({
    required String id,
  }) async {
    // Soft archive instead of permanent deletion
    return archivePatient(id: id, reason: 'حذف عبر النظام');
  }

  @override
  Future<Either<Failures, bool>> checkDuplicate({
    String? phone,
    String? excludePatientId,
  }) async {
    try {
      if (phone != null && phone.trim().isNotEmpty) {
        final normalized = EgyptianPhoneHelper.normalize(phone.trim());
        final exists = _patients.any((p) =>
            p.id != excludePatientId &&
            !(p.isArchived ?? false) &&
            EgyptianPhoneHelper.normalize(p.phone) == normalized);
        if (exists) return const Right(true);
      }

      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر التحقق من تكرار البيانات'));
    }
  }
}
