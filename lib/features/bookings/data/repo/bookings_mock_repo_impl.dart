import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/bookings_response_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';
import 'package:eyadty/features/bookings/domain/helpers/slot_generator_helper.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/doctors/domain/repo/doctors_repo.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';

class BookingsMockRepoImpl implements BookingsRepo {
  final ApiConsumer? apiConsumer;
  final DoctorsRepo? doctorsRepo;
  final SettingsRepo? settingsRepo;

  BookingsMockRepoImpl({
    this.apiConsumer,
    this.doctorsRepo,
    this.settingsRepo,
  }) {
    _initMockData();
  }

  DoctorsRepo? get _effectiveDoctorsRepo {
    if (doctorsRepo != null) return doctorsRepo;
    if (getIt.isRegistered<DoctorsRepo>()) {
      return getIt<DoctorsRepo>();
    }
    return null;
  }

  SettingsRepo? get _effectiveSettingsRepo {
    if (settingsRepo != null) return settingsRepo;
    if (getIt.isRegistered<SettingsRepo>()) {
      return getIt<SettingsRepo>();
    }
    return null;
  }

  final List<BookingModel> _bookings = [];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  List<BookingModel> getBookingsForPatient(String patientId) {
    return _bookings.where((b) {
      return (b.patientId != null && b.patientId == patientId) ||
          (b.fileNumber != null && b.fileNumber == patientId) ||
          (b.customer?.id != null && b.customer!.id == patientId);
    }).toList();
  }

  void _initMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _bookings.addAll([
      BookingModel(
        id: 'MED-101',
        queueNumber: 1,
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        patientPhone: '+201012345678',
        fileNumber: 'PAT-000101',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.inConsultation,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 300,
        paidAmount: 300,
        appointmentTime: today.add(const Duration(hours: 10)),
        arrivalTime: today.add(const Duration(hours: 9, minutes: 40)),
        consultationStartTime: today.add(const Duration(hours: 10, minutes: 0)),
        estimatedWaitMinutes: 0,
        notes: 'ارتفاع في ضغط الدم وصداع نصفي مستمر منذ يومين',
        createdAt: now.subtract(const Duration(days: 1)),
        // Legacy compatibility
        customer: const CustomerModel(
          id: 'PAT-000101',
          name: 'سارة أحمد عبد الله',
          phone: '+20 101 234 5678',
          detailedAddress: 'القاهرة - المعادي الجديدة، شارع النصر',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceId: 'SRV-01',
        serviceName: 'كشف استشاري باطنة عامة',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '10:00',
        endTime: '10:30',
        durationMinutes: 30,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-102',
        queueNumber: 2,
        patientId: 'PAT-000102',
        patientName: 'يوسف إبراهيم المنصوري',
        patientPhone: '+201123456789',
        fileNumber: 'PAT-000102',
        doctorId: 'DOC-02',
        doctorName: 'د. نورهان السيد',
        clinicRoom: 'عيادة الأطفال (غرفة 2)',
        specialty: 'أخصائية طب الأطفال وحديثي الولادة',
        visitType: BookingTypeEnum.revisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 150,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 10, minutes: 30)),
        arrivalTime: today.add(const Duration(hours: 10, minutes: 15)),
        estimatedWaitMinutes: 10,
        notes: 'متابعة نتائج تحليل الدم الشامل ووظائف الكبد والحساسية',
        createdAt: now.subtract(const Duration(hours: 5)),
        customer: const CustomerModel(
          id: 'PAT-000102',
          name: 'يوسف إبراهيم المنصوري',
          phone: '+201123456789',
          detailedAddress: 'الجيزة - الدقي، شارع مصدق',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-02', name: 'د. نورهان السيد'),
        ],
        serviceId: 'SRV-03',
        serviceName: 'كشف أطفال وحديثي الولادة',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '10:30',
        endTime: '11:00',
        durationMinutes: 30,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-103',
        queueNumber: 3,
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        patientPhone: '+201234567890',
        fileNumber: 'PAT-000103',
        doctorId: 'DOC-03',
        doctorName: 'د. حازم زكي',
        clinicRoom: 'عيادة العظام (غرفة 3)',
        specialty: 'استشاري جراحة العظام والمفاصل',
        visitType: BookingTypeEnum.emergency,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 450,
        paidAmount: 450,
        appointmentTime: today.add(const Duration(hours: 11, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 10, minutes: 45)),
        estimatedWaitMinutes: 5,
        notes: 'التواء حاد في مفصل الكاحل الأيمن بعد سقوط مع تورم شديد',
        createdAt: now.subtract(const Duration(hours: 2)),
        customer: const CustomerModel(
          id: 'PAT-000103',
          name: 'مريم محمود حسن',
          phone: '+201234567890',
          detailedAddress: 'التجمع الخامس - النرجس عمارات',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceId: 'SRV-05',
        serviceName: 'كشف عظام ومفاصل',
        bookingType: BookingTypeEnum.emergency,
        date: today,
        startTime: '11:00',
        endTime: '11:30',
        durationMinutes: 30,
        totalPrice: 450,
      ),
      BookingModel(
        id: 'MED-104',
        queueNumber: 4,
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        patientPhone: '+201545678901',
        fileNumber: 'PAT-000104',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.revisit,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 150,
        paidAmount: 150,
        appointmentTime: today.add(const Duration(hours: 9, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 8, minutes: 45)),
        consultationStartTime: today.add(const Duration(hours: 9, minutes: 0)),
        estimatedWaitMinutes: 0,
        notes: 'تم صرف علاج السكري الجديد وتنظيم جرعات الإنسولين والمتابعة بعد شهر',
        createdAt: now.subtract(const Duration(days: 3)),
        customer: const CustomerModel(
          id: 'PAT-000104',
          name: 'طارق عبد الرحمن علي',
          phone: '+201545678901',
          detailedAddress: 'الشيخ زايد - كمبوند الربوة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceId: 'SRV-01',
        serviceName: 'كشف استشاري باطنة عامة',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '09:00',
        endTime: '09:30',
        durationMinutes: 30,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-105',
        queueNumber: 5,
        patientId: 'PAT-000105',
        patientName: 'منى فاروق الشناوي',
        patientPhone: '+201098765432',
        fileNumber: 'PAT-000105',
        doctorId: 'DOC-04',
        doctorName: 'د. ريم المهدي',
        clinicRoom: 'عيادة الرمد (غرفة 4)',
        specialty: 'أخصائية طب وجراحة العيون',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.postponed,
        originalAppointmentTime:
            today.add(const Duration(hours: 11, minutes: 30)),
        rescheduledTo: today.add(const Duration(days: 3, hours: 14)),
        postponedAt: today.add(const Duration(hours: 10)),
        postponeReason: 'تأخرت المريضة في الطريق وطلبت تأجيل الموعد لتاريخ آخر',
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 200,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 11, minutes: 30)),
        arrivalTime: today.add(const Duration(hours: 11, minutes: 10)),
        estimatedWaitMinutes: 40,
        notes: 'تأخرت المريضة في الطريق وطلبت تأجيل الدور بعد الحالة رقم 6',
        createdAt: now.subtract(const Duration(hours: 4)),
        customer: const CustomerModel(
          id: 'PAT-000105',
          name: 'منى فاروق الشناوي',
          phone: '+201098765432',
          detailedAddress: 'مدينة نصر - الحي السابع',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-04', name: 'د. ريم المهدي'),
        ],
        serviceId: 'SRV-06',
        serviceName: 'فحص قاع عين وقياس ضغط العين',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '11:30',
        endTime: '12:00',
        durationMinutes: 30,
        totalPrice: 200,
      ),
      BookingModel(
        id: 'MED-106',
        queueNumber: 6,
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        patientPhone: '+201012345678',
        fileNumber: 'PAT-000101',
        doctorId: 'DOC-03',
        doctorName: 'د. حازم زكي',
        clinicRoom: 'عيادة العظام (غرفة 3)',
        specialty: 'استشاري جراحة العظام والمفاصل',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 350,
        paidAmount: 350,
        appointmentTime: today.add(const Duration(days: 2, hours: 12, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 11, minutes: 35)),
        estimatedWaitMinutes: 25,
        notes: 'آلام حادة أسفل الظهر مع تنميل في الساق اليسرى بعد رفع حمل ثقيل',
        createdAt: now.subtract(const Duration(hours: 3)),
        customer: const CustomerModel(
          id: 'PAT-000101',
          name: 'سارة أحمد عبد الله',
          phone: '+201012345678',
          detailedAddress: 'مصر الجديدة - الكوربة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceId: 'SRV-05',
        serviceName: 'كشف عظام ومفاصل',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '12:00',
        endTime: '12:30',
        durationMinutes: 30,
        totalPrice: 350,
      ),
      BookingModel(
        id: 'MED-107',
        queueNumber: 7,
        patientId: 'PAT-000102',
        patientName: 'يوسف إبراهيم المنصوري',
        patientPhone: '+201123456789',
        fileNumber: 'PAT-000102',
        doctorId: 'DOC-02',
        doctorName: 'د. نورهان السيد',
        clinicRoom: 'عيادة الأطفال (غرفة 2)',
        specialty: 'أخصائية طب الأطفال وحديثي الولادة',
        visitType: BookingTypeEnum.emergency,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.partiallyPaid,
        consultationFee: 300,
        paidAmount: 150,
        appointmentTime: today.add(const Duration(hours: 9, minutes: 15)),
        arrivalTime: today.add(const Duration(hours: 9, minutes: 0)),
        consultationStartTime: today.add(const Duration(hours: 9, minutes: 15)),
        estimatedWaitMinutes: 0,
        notes: 'حساسية مفاجئة وطفح جلدي حاد بعد تناول مضاد حيوي تم إعطاء حقنة مضادة للحساسية',
        createdAt: now.subtract(const Duration(hours: 6)),
        customer: const CustomerModel(
          id: 'PAT-000102',
          name: 'يوسف إبراهيم المنصوري',
          phone: '+201123456789',
          detailedAddress: 'المهندسين - شارع جامعة الدول العربية',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-02', name: 'د. نورهان السيد'),
        ],
        serviceId: 'SRV-03',
        serviceName: 'كشف أطفال وحديثي الولادة',
        bookingType: BookingTypeEnum.emergency,
        date: today,
        startTime: '09:15',
        endTime: '09:45',
        durationMinutes: 30,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-108',
        branchId: 'branch_2',
        queueNumber: 8,
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        patientPhone: '+201234567890',
        fileNumber: 'PAT-000103',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 300,
        paidAmount: 300,
        appointmentTime: today.add(const Duration(hours: 12, minutes: 30)),
        arrivalTime: today.add(const Duration(hours: 12, minutes: 0)),
        estimatedWaitMinutes: 45,
        notes: 'فحص دوري شامل وشكوى من حموضة متكررة وارتجاع مريئي',
        createdAt: now.subtract(const Duration(hours: 2)),
        customer: const CustomerModel(
          id: 'PAT-000103',
          name: 'مريم محمود حسن',
          phone: '+201234567890',
          detailedAddress: 'الشروق - المنطقة الثامنة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceId: 'SRV-01',
        serviceName: 'كشف استشاري باطنة عامة',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '12:30',
        endTime: '13:00',
        durationMinutes: 30,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-109',
        queueNumber: 9,
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        patientPhone: '+201545678901',
        fileNumber: 'PAT-000104',
        doctorId: 'DOC-04',
        doctorName: 'د. ريم المهدي',
        clinicRoom: 'عيادة الرمد (غرفة 4)',
        specialty: 'أخصائية طب وجراحة العيون',
        visitType: BookingTypeEnum.revisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 150,
        paidAmount: 150,
        appointmentTime: today.add(const Duration(hours: 13, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 12, minutes: 40)),
        estimatedWaitMinutes: 60,
        notes: 'قياس ضغط العين وفحص قاع العين لمرضى السكري',
        createdAt: now.subtract(const Duration(days: 2)),
        customer: const CustomerModel(
          id: 'PAT-000104',
          name: 'طارق عبد الرحمن علي',
          phone: '+201545678901',
          detailedAddress: 'الزمالك - شارع حسن صبري',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-04', name: 'د. ريم المهدي'),
        ],
        serviceId: 'SRV-06',
        serviceName: 'فحص قاع عين وقياس ضغط العين',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '13:00',
        endTime: '13:30',
        durationMinutes: 30,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-110',
        queueNumber: 10,
        patientId: 'PAT-000105',
        patientName: 'منى فاروق الشناوي',
        patientPhone: '+201098765432',
        fileNumber: 'PAT-000105',
        doctorId: 'DOC-03',
        doctorName: 'د. حازم زكي',
        clinicRoom: 'عيادة العظام (غرفة 3)',
        specialty: 'استشاري جراحة العظام والمفاصل',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.cancelled,
        cancelledAt: today.add(const Duration(hours: 9)),
        cancelledBy: 'patient',
        cancelReason:
            'اعتذر المريض عن الحضور وتم إلغاء الحجز بناءً على اتصاله هاتفياً',
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 350,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 14, minutes: 0)),
        arrivalTime: null,
        estimatedWaitMinutes: 0,
        notes: 'اعتذر المريض عن الحضور وتم إلغاء الحجز بناءً على اتصاله هاتفياً',
        createdAt: now.subtract(const Duration(days: 1)),
        customer: const CustomerModel(
          id: 'PAT-000105',
          name: 'منى فاروق الشناوي',
          phone: '+201098765432',
          detailedAddress: 'المعادي - دجلة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceId: 'SRV-05',
        serviceName: 'كشف عظام ومفاصل',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '14:00',
        endTime: '14:30',
        durationMinutes: 30,
        totalPrice: 350,
      ),
      BookingModel(
        id: 'MED-111',
        queueNumber: 11,
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        patientPhone: '+201012345678',
        fileNumber: 'PAT-000101',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.noShow,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 300,
        paidAmount: 300,
        appointmentTime: today.add(const Duration(hours: 8, minutes: 30)),
        arrivalTime: null,
        estimatedWaitMinutes: 0,
        notes: 'لم يحضر المريض في الموعد المحدد ولم يتم تسجيل وصوله بالعيادة',
        createdAt: now.subtract(const Duration(days: 1)),
        customer: const CustomerModel(
          id: 'PAT-000101',
          name: 'سارة أحمد عبد الله',
          phone: '+201012345678',
          detailedAddress: 'مدينة نصر - عباس العقاد',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceId: 'SRV-01',
        serviceName: 'كشف استشاري باطنة عامة',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '08:30',
        endTime: '09:00',
        durationMinutes: 30,
        totalPrice: 300,
      ),
    ]);
  }

  @override
  Future<Either<Failures, BookingSummaryModel>> getBookingSummary({
    DateTime? date,
    String? branchId,
  }) async {
    try {
      final targetDate = date ?? CairoTimeHelper.now();
      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: _bookings,
        selectedDate: targetDate,
        branchId: branchId,
      );
      return right(summary);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BookingsResponseModel>> getBookings(
    PaginationParams params,
  ) async {
    try {
      List<BookingModel> filtered = List.from(_bookings);

      String? searchQuery;
      String? statusFilter;
      String? dateFilter;
      String? branchIdFilter;
      String? bookingTypeFilter;
      String? customerIdFilter;

      for (final filter in params.filterList) {
        if (!filter.isActive || filter.value == null) continue;
        if (filter.key == 'search') {
          searchQuery = filter.value.toString().trim().toLowerCase();
        } else if (filter.key == 'status') {
          statusFilter = filter.value.toString().trim().toLowerCase();
        } else if (filter.key == 'date') {
          dateFilter = filter.value.toString().trim();
        } else if (filter.key == 'branchId' || filter.key == 'branch') {
          branchIdFilter = filter.value.toString().trim();
        } else if (filter.key == 'bookingType' || filter.key == 'type') {
          bookingTypeFilter = filter.value.toString().trim().toLowerCase();
        } else if (filter.key == 'customerId') {
          customerIdFilter = filter.value.toString().trim();
        }
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filtered = filtered.where((b) {
          final customerName = b.customerName?.toLowerCase() ?? '';
          final customerPhone = b.customerPhone?.toLowerCase() ?? '';
          final serviceName = b.serviceName?.toLowerCase() ?? '';
          final technicianNamesStr =
              b.technicianNames.join(' ').toLowerCase();
          final technicianName = b.technicianName?.toLowerCase() ?? '';
          final bookingId = b.id?.toLowerCase() ?? '';

          return customerName.contains(searchQuery!) ||
              customerPhone.contains(searchQuery) ||
              serviceName.contains(searchQuery) ||
              technicianNamesStr.contains(searchQuery) ||
              technicianName.contains(searchQuery) ||
              bookingId.contains(searchQuery);
        }).toList();
      }

      // Branch filter
      if (branchIdFilter != null &&
          branchIdFilter.isNotEmpty &&
          branchIdFilter != 'all') {
        filtered = filtered
            .where((b) =>
                BookingStatisticsCalculator.matchesBranch(b, branchIdFilter))
            .toList();
      }

      DateTime? selectedDateObj;
      if (dateFilter != null && dateFilter.isNotEmpty && dateFilter.length == 10) {
        selectedDateObj = DateTime.tryParse(dateFilter);
      }

      // Status & Date filter synchronized with BookingStatisticsCalculator
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'all') {
        final statusEnum = BookingStatusEnum.fromValue(statusFilter);
        if (statusEnum != null && selectedDateObj != null) {
          filtered = filtered.where((b) {
            return BookingStatisticsCalculator.matchesStatusFilter(
              b,
              statusEnum,
              selectedDate: selectedDateObj!,
              branchId: branchIdFilter,
            );
          }).toList();
        } else if (statusEnum != null) {
          filtered = filtered.where((b) => b.status == statusEnum).toList();
        }
      } else if (selectedDateObj != null) {
        // Date filter with all statuses: include bookings for this date or postponed from this date
        filtered = filtered.where((b) {
          return BookingStatisticsCalculator.matchesStatusFilter(
            b,
            null,
            selectedDate: selectedDateObj!,
            branchId: branchIdFilter,
          );
        }).toList();
      } else if (dateFilter != null && dateFilter.length == 7) {
        // Month filter
        filtered = filtered.where((b) {
          final d = b.appointmentTime ?? b.date;
          if (d == null) return false;
          final monthFormatted =
              "${d.year}-${d.month.toString().padLeft(2, '0')}";
          return monthFormatted == dateFilter;
        }).toList();
      }

      // Booking type filter (one_time / recurring)
      if (bookingTypeFilter != null &&
          bookingTypeFilter.isNotEmpty &&
          bookingTypeFilter != 'all') {
        filtered = filtered.where((b) {
          return b.bookingType?.value.toLowerCase() == bookingTypeFilter;
        }).toList();
      }

      // Customer ID filter
      if (customerIdFilter != null && customerIdFilter.isNotEmpty) {
        filtered = filtered.where((b) {
          return b.customerId == customerIdFilter ||
              b.customer?.id == customerIdFilter;
        }).toList();
      }

      // Sort by date desc
      filtered.sort((a, b) {
        final dateA = a.date ?? DateTime(1970);
        final dateB = b.date ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      final page = params.page ?? 1;
      final limit = params.limit ?? 10;
      final total = filtered.length;
      final pages = (total / limit).ceil();

      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, total);

      final pagedList = (startIndex < total)
          ? filtered.sublist(startIndex, endIndex)
          : <BookingModel>[];

      return right(
        BookingsResponseModel(
          bookings: pagedList,
          pagination: PaginationModel(
            page: page,
            limit: limit,
            total: total,
            pages: pages > 0 ? pages : 1,
          ),
        ),
      );
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> getBookingById(String id) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        return right(_bookings[index]);
      }
      return left(const ServerFailure(errMessage: 'Booking not found'));
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<BookingModel>>> getDoctorBookingsForDate({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final list = _bookings.where((b) {
        final bDoc = b.doctorId ??
            (b.technicians.isNotEmpty ? b.technicians.first.id : null);
        if (bDoc != doctorId) return false;
        final bDate = b.date ?? b.appointmentTime;
        if (bDate == null) return false;
        return CairoTimeHelper.isSameDay(bDate, date);
      }).toList();
      return right(list);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  Future<Either<Failures, Unit>> _validateBookingSlotAvailability({
    required BookingModel booking,
    DateTime? customNow,
    String? excludeBookingId,
  }) async {
    final date = booking.date ?? booking.appointmentTime;
    final startTime = booking.startTime;

    if (date != null && startTime != null && startTime.isNotEmpty) {
      // 1. فحص هل الموعد في الماضي
      final cairoToday = DoctorAvailabilityHelper.getTodayCairo(customNow);
      final targetDateOnly = DoctorAvailabilityHelper.dateOnly(date);

      if (targetDateOnly.isBefore(cairoToday)) {
        return left(
          const ValidationFailure(errMessage: 'booking_time_in_past'),
        );
      }

      if (CairoTimeHelper.isSameDay(date, cairoToday)) {
        final cairoNow = customNow ?? CairoTimeHelper.now();
        final nowMinutes = cairoNow.hour * 60 + cairoNow.minute;
        final startMinutes = SlotGeneratorHelper.timeToMinutes(startTime);
        if (startMinutes <= nowMinutes) {
          return left(
            const ValidationFailure(errMessage: 'booking_time_in_past'),
          );
        }
      }

      // 2. فحص توفر الطبيب وعدم التعارض
      final doctorId = booking.doctorId ??
          (booking.technicians.isNotEmpty ? booking.technicians.first.id : null);

      if (doctorId != null) {
        DoctorScheduleModel? schedule;
        List<DoctorLeaveModel>? leaves;
        List<SpecialHolidayModel>? holidays;

        final docRepo = _effectiveDoctorsRepo;
        if (docRepo != null) {
          final schedRes = await docRepo.getDoctorSchedule(doctorId: doctorId);
          schedule = schedRes.fold((_) => null, (r) => r);
          final leavesRes = await docRepo.getDoctorLeaves(doctorId: doctorId);
          leaves = leavesRes.fold((_) => null, (r) => r);
        }

        final setRepo = _effectiveSettingsRepo;
        if (setRepo != null) {
          final settingsRes = await setRepo.getCompanySettings();
          holidays = settingsRes.fold((_) => null, (r) => r.specialHolidays);
        }

        final duration = booking.durationMinutes ?? 20;

        if (schedule != null) {
          final isAvailable = SlotGeneratorHelper.isSlotStillAvailable(
            schedule: schedule,
            leaves: leaves,
            holidays: holidays,
            doctorBookings: _bookings,
            serviceDurationMinutes: duration,
            date: date,
            startTime: startTime,
            customNow: customNow,
            excludeBookingId: excludeBookingId,
          );

          if (!isAvailable) {
            return left(
              const SlotConflictFailure(
                errMessage: 'slot_already_booked_or_unavailable',
              ),
            );
          }
        } else {
          // في حال لم يحدد دوام بعد: فحص التعارض المباشر مع الحجوزات النشطة
          final startM = SlotGeneratorHelper.timeToMinutes(startTime);
          final endM = startM + duration;
          for (final b in _bookings) {
            if (excludeBookingId != null && b.id == excludeBookingId) continue;
            if (!SlotGeneratorHelper.isBookingOccupyingSlot(b.status)) continue;
            final bDoc = b.doctorId ??
                (b.technicians.isNotEmpty ? b.technicians.first.id : null);
            if (bDoc != doctorId) continue;
            final bDate = b.date ?? b.appointmentTime;
            if (bDate == null || !CairoTimeHelper.isSameDay(bDate, date)) {
              continue;
            }
            final bStart = SlotGeneratorHelper.timeToMinutes(b.startTime);
            final bEnd = SlotGeneratorHelper.timeToMinutes(b.endTime);
            if (startM < bEnd && endM > bStart) {
              return left(
                SlotConflictFailure(
                  errMessage: 'slot_already_booked_or_unavailable',
                  conflictingPatientName: b.patientName ?? b.customer?.name,
                  conflictingBookingId: b.id,
                ),
              );
            }
          }
        }
      }
    }

    return right(unit);
  }

  @override
  Future<Either<Failures, BookingModel>> createBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    try {
      final validationRes = await _validateBookingSlotAvailability(
        booking: booking,
        customNow: customNow,
      );
      if (validationRes.isLeft()) {
        return left(
          validationRes.swap().getOrElse(
                () => const ServerFailure(errMessage: 'Validation failed'),
              ),
        );
      }

      final newId = 'BK-${1000 + _bookings.length + 1}';
      final createdBooking = booking.copyWith(
        id: newId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _bookings.insert(0, createdBooking);
      return right(createdBooking);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index == -1) {
        return left(const ServerFailure(errMessage: 'Booking not found'));
      }

      final existing = _bookings[index];
      final isDateOrTimeChanged = existing.date != booking.date ||
          existing.startTime != booking.startTime ||
          existing.doctorId != booking.doctorId;

      if (isDateOrTimeChanged) {
        final validationRes = await _validateBookingSlotAvailability(
          booking: booking,
          customNow: customNow,
          excludeBookingId: booking.id,
        );
        if (validationRes.isLeft()) {
          return left(
            validationRes.swap().getOrElse(
                  () => const ServerFailure(errMessage: 'Validation failed'),
                ),
          );
        }
      }

      final updated = booking.copyWith(updatedAt: DateTime.now());
      _bookings[index] = updated;
      return right(updated);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> changeBookingStatus(
    ChangeBookingStatusParams params,
  ) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == params.bookingId);
      if (index != -1) {
        final existing = _bookings[index];
        final now = CairoTimeHelper.now();

        DateTime? originalAppointmentTime = existing.originalAppointmentTime;
        DateTime? rescheduledTo = existing.rescheduledTo;
        DateTime? postponedAt = existing.postponedAt;
        String? postponeReason = existing.postponeReason;

        String? cancelReason = existing.cancelReason;
        String? cancelledBy = existing.cancelledBy;
        DateTime? cancelledAt = existing.cancelledAt;

        DateTime? arrivalTime = existing.arrivalTime;

        if (params.newStatus == BookingStatusEnum.postponed) {
          originalAppointmentTime ??=
              existing.appointmentTime ?? existing.date;
          rescheduledTo = params.rescheduledTo ?? existing.rescheduledTo;
          postponedAt = now;
          postponeReason = params.postponeReason ?? existing.postponeReason;
        } else if (params.newStatus == BookingStatusEnum.cancelled) {
          cancelReason = params.cancelReason ?? existing.cancelReason;
          cancelledBy = params.cancelledBy ?? existing.cancelledBy ?? 'patient';
          cancelledAt = params.cancelledAt ?? now;
        } else if (params.newStatus == BookingStatusEnum.waiting) {
          // If moving to waiting room from no-show, register arrival
          if (existing.status == BookingStatusEnum.noShow ||
              existing.arrivalTime == null) {
            arrivalTime = params.arrivalTime ?? now;
          }
        }

        _bookings[index] = existing.copyWith(
          status: params.newStatus,
          originalAppointmentTime: originalAppointmentTime,
          rescheduledTo: rescheduledTo,
          postponedAt: postponedAt,
          postponeReason: postponeReason,
          cancelReason: cancelReason,
          cancelledBy: cancelledBy,
          cancelledAt: cancelledAt,
          arrivalTime: arrivalTime,
          updatedAt: now,
        );
        return right(unit);
      }
      return left(const ServerFailure(errMessage: 'Booking not found'));
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> reassignTechnician(
    ReassignTechnicianParams params,
  ) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == params.bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          technicianIds: params.newTechnicianIds,
          technicianNames: params.newTechnicianNames,
          technicianId: params.newTechnicianIds.isNotEmpty
              ? params.newTechnicianIds.first
              : params.newTechnicianId,
          technicianName: params.newTechnicianNames.isNotEmpty
              ? params.newTechnicianNames.join('، ')
              : params.newTechnicianName,
          updatedAt: DateTime.now(),
        );
        return right(unit);
      }
      return left(const ServerFailure(errMessage: 'Booking not found'));
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteBooking(String bookingId) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final existing = _bookings[index];
        final now = CairoTimeHelper.now();
        _bookings[index] = existing.copyWith(
          status: BookingStatusEnum.cancelled,
          cancelledAt: now,
          cancelledBy: existing.cancelledBy ?? 'clinic',
          cancelReason: existing.cancelReason ??
              'تم إلغاء الحجز بواسطة إدارة العيادة بناءً على طلب المريض',
          updatedAt: now,
        );
        return right(unit);
      }
      return left(const ServerFailure(errMessage: 'Booking not found'));
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }
}

typedef BookingsRepoImpl = BookingsMockRepoImpl;
