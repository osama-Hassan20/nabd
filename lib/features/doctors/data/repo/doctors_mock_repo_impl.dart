import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';

import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import '../../domain/helpers/doctor_availability_helper.dart';
import '../../domain/helpers/doctor_schedule_validator.dart';
import '../../domain/repo/doctors_repo.dart';
import '../models/doctor_break_time_model.dart';
import '../models/doctor_leave_model.dart';
import '../models/doctor_model.dart';
import '../models/doctor_schedule_model.dart';
import '../models/doctor_work_day_model.dart';
import '../models/doctors_response_model.dart';
import '../models/enums/doctor_gender_enum.dart';
import '../models/enums/doctor_status_enum.dart';
import '../models/enums/week_day_enum.dart';

class DoctorsMockRepoImpl implements DoctorsRepo {
  final ApiConsumer? apiConsumer;
  final CurrentRoleProvider? roleProvider;
  final BookingsRepo? bookingsRepo;
  final SettingsRepo? settingsRepo;

  DoctorsMockRepoImpl({
    this.apiConsumer,
    this.roleProvider,
    this.bookingsRepo,
    this.settingsRepo,
  }) {
    _initMockData();
  }

  final List<DoctorModel> _doctors = [];
  final List<DoctorLeaveModel> _leaves = [];
  final Map<String, DoctorScheduleModel> _schedules = {};

  List<BookingModel> _getAllBookings() {
    if (bookingsRepo is BookingsMockRepoImpl) {
      return (bookingsRepo as BookingsMockRepoImpl).bookings;
    }
    return [];
  }

  void _initMockData() {
    final now = CairoTimeHelper.now();

    // ─── Initial Leaves ────────────────────────────────────────────────────────
    _leaves.addAll([
      DoctorLeaveModel(
        id: 'LEAVE-01',
        doctorId: 'DOC-03',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        reason: 'إجازة سنوية اعتيادية',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      DoctorLeaveModel(
        id: 'LEAVE-02',
        doctorId: 'DOC-01',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 14)),
        reason: 'مؤتمر طبي تخصصي',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      DoctorLeaveModel(
        id: 'LEAVE-03',
        doctorId: 'DOC-05',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 25)),
        reason: 'إجازة مرضية سابقة',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      DoctorLeaveModel(
        id: 'LEAVE-04',
        doctorId: 'DOC-04',
        startDate: now.add(const Duration(days: 12)),
        endDate: now.add(const Duration(days: 16)),
        reason: 'إجازة عائلية قادمة',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    // ─── Initial Doctors ───────────────────────────────────────────────────────
    _doctors.addAll([
      DoctorModel(
        id: 'DOC-01',
        name: 'د. حسام الدين مصطفى',
        phone: '+20 10 1122 3344',
        specialty: 'باطنة وقلب',
        specialties: const [MedicalSpecialty.internalMedicine, MedicalSpecialty.cardiology],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 4,
        upcomingBookingsCount: 6,
        completedBookingsCount: 42,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-02',
        name: 'د. أحمد الشافعي',
        phone: '+20 11 2233 4455',
        specialty: 'جراحة عامة ومناظير',
        specialties: const [MedicalSpecialty.generalSurgery],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.busy,
        todayTasksCount: 5,
        upcomingBookingsCount: 7,
        completedBookingsCount: 58,
        createdAt: now.subtract(const Duration(days: 220)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      DoctorModel(
        id: 'DOC-03',
        name: 'د. سارة المنشاوي',
        phone: '+20 12 3344 5566',
        specialty: 'أطفال وحديثي الولادة',
        specialties: const [MedicalSpecialty.pediatrics],
        gender: DoctorGenderEnum.female,
        status: DoctorStatusEnum.onLeave,
        todayTasksCount: 0,
        upcomingBookingsCount: 2,
        completedBookingsCount: 36,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-04',
        name: 'د. محمود خليل',
        phone: '+20 15 4455 6677',
        specialty: 'عظام ومفاصل',
        specialties: const [MedicalSpecialty.orthopedics],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 3,
        upcomingBookingsCount: 5,
        completedBookingsCount: 49,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      DoctorModel(
        id: 'DOC-05',
        name: 'د. ريم عبد الوهاب',
        phone: '+20 10 5566 7788',
        specialty: 'جلدية وتجميل',
        specialties: const [MedicalSpecialty.dermatology, MedicalSpecialty.cosmeticPlasticSurgery],
        gender: DoctorGenderEnum.female,
        status: DoctorStatusEnum.available,
        todayTasksCount: 6,
        upcomingBookingsCount: 8,
        completedBookingsCount: 65,
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-06',
        name: 'د. طارق العوضي',
        phone: '+20 11 6677 8899',
        specialty: 'أنف وأذن وحنجرة',
        specialties: const [MedicalSpecialty.ent],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.busy,
        todayTasksCount: 4,
        upcomingBookingsCount: 6,
        completedBookingsCount: 39,
        createdAt: now.subtract(const Duration(days: 110)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      DoctorModel(
        id: 'DOC-07',
        name: 'د. نادية الشربيني',
        phone: '+20 10 7788 9900',
        specialty: 'نساء وتوليد',
        specialties: const [MedicalSpecialty.obstetricsGynecology],
        gender: DoctorGenderEnum.female,
        status: DoctorStatusEnum.available,
        todayTasksCount: 5,
        upcomingBookingsCount: 7,
        completedBookingsCount: 54,
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-08',
        name: 'د. كريم البنا',
        phone: '+20 11 8899 0011',
        specialty: 'أسنان وتقويم أسنان',
        specialties: const [MedicalSpecialty.dentistry, MedicalSpecialty.orthodontics],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 4,
        upcomingBookingsCount: 5,
        completedBookingsCount: 44,
        createdAt: now.subtract(const Duration(days: 80)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-09',
        name: 'د. ياسر الفقي',
        phone: '+20 12 9900 1122',
        specialty: 'عيون ورمد',
        specialties: const [MedicalSpecialty.ophthalmology],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 3,
        upcomingBookingsCount: 4,
        completedBookingsCount: 31,
        createdAt: now.subtract(const Duration(days: 70)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-10',
        name: 'د. هبة علام',
        phone: '+20 15 0011 2233',
        specialty: 'علاج طبيعي وتغذية علاجية',
        specialties: const [MedicalSpecialty.physiotherapy, MedicalSpecialty.nutrition],
        gender: DoctorGenderEnum.female,
        status: DoctorStatusEnum.available,
        todayTasksCount: 3,
        upcomingBookingsCount: 3,
        completedBookingsCount: 25,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-11',
        name: 'د. شريف زيدان',
        phone: '+20 10 1100 2299',
        specialty: 'مسالك بولية وغدد صماء',
        specialties: const [MedicalSpecialty.urology, MedicalSpecialty.endocrinology],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 2,
        upcomingBookingsCount: 3,
        completedBookingsCount: 22,
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-12',
        name: 'د. دينا راشد',
        phone: '+20 11 2200 3388',
        specialty: 'مخ وأعصاب ونفسية',
        specialties: const [MedicalSpecialty.neurology, MedicalSpecialty.psychiatry],
        gender: DoctorGenderEnum.female,
        status: DoctorStatusEnum.available,
        todayTasksCount: 2,
        upcomingBookingsCount: 2,
        completedBookingsCount: 19,
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      DoctorModel(
        id: 'DOC-13',
        name: 'د. عمر فاروق',
        phone: '+20 12 3300 4477',
        specialty: 'طب عام',
        specialties: const [MedicalSpecialty.generalPractice, MedicalSpecialty.other],
        gender: DoctorGenderEnum.male,
        status: DoctorStatusEnum.available,
        todayTasksCount: 3,
        upcomingBookingsCount: 4,
        completedBookingsCount: 30,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // ─── Initial Schedules (Realistic variety across doctors) ──────────────────
    // 1) DOC-01: Morning only (Sat-Thu 09:00 - 15:00, break 12:00 - 12:30, Friday off)
    _schedules['DOC-01'] = DoctorScheduleModel(
      id: 'SCHED-01',
      doctorId: 'DOC-01',
      slotDurationMinutes: 20,
      bufferDurationMinutes: 5,
      isAcceptingWalkIns: true,
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday,
            startTime: day != WeekDayEnum.friday ? '09:00' : null,
            endTime: day != WeekDayEnum.friday ? '15:00' : null,
            breaks: day != WeekDayEnum.friday
                ? [
                    const DoctorBreakTimeModel(
                      name: 'استراحة صلاة وغداء',
                      startTime: '12:00',
                      endTime: '12:30',
                    ),
                  ]
                : null,
          ),
      ],
    );

    // 2) DOC-02: Two shifts / split day (Sat-Wed 09:00 - 21:00, break 14:00 - 17:00, Thu & Fri off)
    _schedules['DOC-02'] = DoctorScheduleModel(
      id: 'SCHED-02',
      doctorId: 'DOC-02',
      slotDurationMinutes: 30,
      bufferDurationMinutes: 10,
      isAcceptingWalkIns: true,
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday && day != WeekDayEnum.thursday,
            startTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? '09:00'
                    : null,
            endTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? '21:00'
                    : null,
            breaks:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? [
                        const DoctorBreakTimeModel(
                          name: 'استراحة ما بين الفترتين',
                          startTime: '14:00',
                          endTime: '17:00',
                        ),
                      ]
                    : null,
          ),
      ],
    );

    // 3) DOC-03: Off Friday and Tuesday (Sat, Sun, Mon, Wed, Thu 10:00 - 18:00, break 13:00 - 14:00)
    _schedules['DOC-03'] = DoctorScheduleModel(
      id: 'SCHED-03',
      doctorId: 'DOC-03',
      slotDurationMinutes: 15,
      bufferDurationMinutes: 5,
      isAcceptingWalkIns: false,
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday && day != WeekDayEnum.tuesday,
            startTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.tuesday
                    ? '10:00'
                    : null,
            endTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.tuesday
                    ? '18:00'
                    : null,
            breaks:
                day != WeekDayEnum.friday && day != WeekDayEnum.tuesday
                    ? [
                        const DoctorBreakTimeModel(
                          name: 'استراحة غداء',
                          startTime: '13:00',
                          endTime: '14:00',
                        ),
                      ]
                    : null,
          ),
      ],
    );

    // 4) DOC-04: Regular schedule (Sat-Thu 08:30 - 16:30, break 12:30 - 13:00, Fri off)
    _schedules['DOC-04'] = DoctorScheduleModel(
      id: 'SCHED-04',
      doctorId: 'DOC-04',
      slotDurationMinutes: 20,
      bufferDurationMinutes: 5,
      isAcceptingWalkIns: true,
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday,
            startTime: day != WeekDayEnum.friday ? '08:30' : null,
            endTime: day != WeekDayEnum.friday ? '16:30' : null,
            breaks: day != WeekDayEnum.friday
                ? [
                    const DoctorBreakTimeModel(
                      name: 'استراحة',
                      startTime: '12:30',
                      endTime: '13:00',
                    ),
                  ]
                : null,
          ),
      ],
    );

    // 5) DOC-05: Evening shift (Sat-Wed 16:00 - 23:00, break 19:30 - 20:00, Thu & Fri off)
    _schedules['DOC-05'] = DoctorScheduleModel(
      id: 'SCHED-05',
      doctorId: 'DOC-05',
      slotDurationMinutes: 20,
      bufferDurationMinutes: 0,
      isAcceptingWalkIns: true,
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday && day != WeekDayEnum.thursday,
            startTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? '16:00'
                    : null,
            endTime:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? '23:00'
                    : null,
            breaks:
                day != WeekDayEnum.friday && day != WeekDayEnum.thursday
                    ? [
                        const DoctorBreakTimeModel(
                          name: 'استراحة شاي',
                          startTime: '19:30',
                          endTime: '20:00',
                        ),
                      ]
                    : null,
          ),
      ],
    );

    // 6) DOC-06: No schedule defined (null) to test the unassigned / no_schedule state
  }

  // ─── Doctors List & Details ───────────────────────────────────────────────
  @override
  Future<Either<Failures, DoctorsResponseModel>> getDoctors({
    required PaginationParams params,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      List<DoctorModel> filtered = List.from(_doctors);

      final filters = params.filterList;
      if (filters.isNotEmpty) {
        for (final f in filters) {
          if (f.key == 'search' && f.value.toString().isNotEmpty) {
            final query = f.value.toString().toLowerCase().trim();
            filtered = filtered.where((d) {
              final nameMatch = (d.name ?? '').toLowerCase().contains(query);
              final phoneMatch = (d.phone ?? '').toLowerCase().contains(query);
              final specMatch =
                  (d.specialty ?? '').toLowerCase().contains(query);
              return nameMatch || phoneMatch || specMatch;
            }).toList();
          } else if (f.key == 'status' && f.value.toString().isNotEmpty) {
            final statusStr = f.value.toString().toLowerCase().trim();
            filtered = filtered.where((d) {
              return (d.status?.value ?? '').toLowerCase() == statusStr;
            }).toList();
          }
        }
      }

      final totalCount = filtered.length;
      final limit = (params.limit ?? 10) > 0 ? (params.limit ?? 10) : 10;
      final totalPages = (totalCount / limit).ceil().clamp(1, 999);
      final page = params.page ?? 1;
      final currentPage = page.clamp(1, totalPages);

      final startIndex = (currentPage - 1) * limit;
      final paginatedItems = startIndex < totalCount
          ? filtered.skip(startIndex).take(limit).toList()
          : <DoctorModel>[];

      return Right(
        DoctorsResponseModel(
          items: paginatedItems,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: currentPage,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب قائمة الأطباء'));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> getDoctorById({
    required String id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final doc = _doctors.firstWhere(
        (d) => d.id == id,
        orElse: () => const DoctorModel(),
      );

      if (doc.id == null) {
        return Left(ServerFailure(errMessage: 'الطبيب غير موجود'));
      }

      return Right(doc);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب تفاصيل الطبيب'));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> addDoctor({
    required DoctorModel doctor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final newId = doctor.id ?? 'DOC-0${_doctors.length + 1}';
      final newDoctor = doctor.copyWith(
        id: newId,
        todayTasksCount: 0,
        upcomingBookingsCount: 0,
        completedBookingsCount: 0,
        status: doctor.status ?? DoctorStatusEnum.available,
        createdAt: CairoTimeHelper.now(),
        updatedAt: CairoTimeHelper.now(),
      );

      _doctors.insert(0, newDoctor);
      return Right(newDoctor);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل إضافة الطبيب'));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> updateDoctor({
    required DoctorModel doctor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final index = _doctors.indexWhere((d) => d.id == doctor.id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'الطبيب غير موجود'));
      }

      final existing = _doctors[index];
      final updated = existing.copyWith(
        name: doctor.name ?? existing.name,
        phone: doctor.phone ?? existing.phone,
        image: doctor.image ?? existing.image,
        specialty: doctor.specialty ?? existing.specialty,
        gender: doctor.gender ?? existing.gender,
        status: doctor.status ?? existing.status,
        updatedAt: CairoTimeHelper.now(),
      );

      _doctors[index] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تحديث بيانات الطبيب'));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteDoctor({required String id}) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final index = _doctors.indexWhere((d) => d.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'الطبيب غير موجود'));
      }

      _doctors.removeAt(index);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل حذف الطبيب'));
    }
  }

  // ─── Doctor Schedule ───────────────────────────────────────────────────────
  @override
  Future<Either<Failures, DoctorScheduleModel?>> getDoctorSchedule({
    required String doctorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      final schedule = _schedules[doctorId];
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب جدول دوام الطبيب'));
    }
  }

  @override
  Future<Either<Failures, DoctorScheduleModel>> saveDoctorSchedule({
    required DoctorScheduleModel schedule,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // Admin role check
    if (roleProvider != null &&
        roleProvider!.currentRole != UserRoleEnum.admin) {
      return const Left(
        ValidationFailure(errMessage: 'unauthorized_admin_only'),
      );
    }

    // Validation
    final validationError = DoctorScheduleValidator.validateSchedule(schedule);
    if (validationError != null) {
      return Left(ValidationFailure(errMessage: validationError));
    }

    final docId = schedule.doctorId;
    if (docId == null || docId.isEmpty) {
      return const Left(ValidationFailure(errMessage: 'doctor_id_required'));
    }

    _schedules[docId] = schedule;
    return Right(schedule);
  }

  // ─── Doctor Leaves ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failures, List<DoctorLeaveModel>>> getDoctorLeaves({
    required String doctorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final leaves =
          _leaves.where((l) => l.doctorId == doctorId).toList()
            ..sort((a, b) {
              final aDate = a.startDate ?? DateTime(2000);
              final bDate = b.startDate ?? DateTime(2000);
              return bDate.compareTo(aDate);
            });
      return Right(leaves);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب إجازات الطبيب'));
    }
  }

  @override
  Future<Either<Failures, int>> countConflictingBookings({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DoctorAvailabilityHelper.dateOnly(startDate);
    final end = DoctorAvailabilityHelper.dateOnly(endDate);

    final allBookings = _getAllBookings();
    final count = allBookings.where((b) {
      final docMatches = b.doctorId == doctorId || b.technicianId == doctorId;
      if (!docMatches) return false;
      final bDate = b.date;
      if (bDate == null) return false;
      final target = DoctorAvailabilityHelper.dateOnly(bDate);
      if (target.isBefore(start) || target.isAfter(end)) return false;

      // Active only: not cancelled, completed, or noShow
      final s = b.status;
      if (s == BookingStatusEnum.cancelled ||
          s == BookingStatusEnum.completed ||
          s == BookingStatusEnum.noShow) {
        return false;
      }
      return true;
    }).length;

    return Right(count);
  }

  @override
  Future<Either<Failures, DoctorLeaveModel>> addDoctorLeave({
    required DoctorLeaveModel leave,
    bool force = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // Admin role check
    if (roleProvider != null &&
        roleProvider!.currentRole != UserRoleEnum.admin) {
      return const Left(
        ValidationFailure(errMessage: 'unauthorized_admin_only'),
      );
    }

    // Validation
    final validationError = DoctorScheduleValidator.validateLeave(
      leave: leave,
      existingLeaves: _leaves,
    );
    if (validationError != null) {
      return Left(ValidationFailure(errMessage: validationError));
    }

    // Check for active conflicting bookings if force is false
    if (!force &&
        leave.doctorId != null &&
        leave.startDate != null &&
        leave.endDate != null) {
      final conflictRes = await countConflictingBookings(
        doctorId: leave.doctorId!,
        startDate: leave.startDate!,
        endDate: leave.endDate!,
      );
      final count = conflictRes.getOrElse(() => 0);
      if (count > 0) {
        return Left(
          ConflictingBookingsFailure(
            conflictingCount: count,
            errMessage: 'conflicting_bookings_warning',
          ),
        );
      }
    }

    try {
      final newId =
          'LEAVE-${(_leaves.length + 1).toString().padLeft(2, '0')}';
      final created = leave.copyWith(
        id: newId,
        createdAt: CairoTimeHelper.now(),
      );

      _leaves.insert(0, created);

      // Check if currently active leave and update doctor status if so
      if (created.isCurrentlyActive()) {
        final docIndex =
            _doctors.indexWhere((d) => d.id == created.doctorId);
        if (docIndex != -1) {
          _doctors[docIndex] = _doctors[docIndex].copyWith(
            status: DoctorStatusEnum.onLeave,
            updatedAt: CairoTimeHelper.now(),
          );
        }
      }

      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تسجيل الإجازة'));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteDoctorLeave({
    required String leaveId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // Admin role check
    if (roleProvider != null &&
        roleProvider!.currentRole != UserRoleEnum.admin) {
      return const Left(
        ValidationFailure(errMessage: 'unauthorized_admin_only'),
      );
    }

    try {
      final index = _leaves.indexWhere((l) => l.id == leaveId);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'الإجازة غير موجودة'));
      }

      final removed = _leaves.removeAt(index);

      // Check if was active leave and restore doctor status to available
      if (removed.isCurrentlyActive()) {
        final docIndex =
            _doctors.indexWhere((d) => d.id == removed.doctorId);
        if (docIndex != -1) {
          _doctors[docIndex] = _doctors[docIndex].copyWith(
            status: DoctorStatusEnum.available,
            updatedAt: CairoTimeHelper.now(),
          );
        }
      }

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل حذف الإجازة'));
    }
  }
}
