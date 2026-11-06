import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
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
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';

class BookingsRepoImpl implements BookingsRepo {
  final ApiConsumer? apiConsumer;

  BookingsRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  final List<BookingModel> _bookings = [];

  void _initMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _bookings.addAll([
      BookingModel(
        id: 'MED-101',
        queueNumber: 1,
        patientId: 'PAT-01',
        patientName: 'سارة أحمد عبد الله',
        patientPhone: '+20 101 234 5678',
        fileNumber: 'EMR-2024-101',
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
          id: 'PAT-01',
          name: 'سارة أحمد عبد الله',
          phone: '+20 101 234 5678',
          address: 'القاهرة - المعادي الجديدة، شارع النصر',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceName: 'عيادة الباطنة (غرفة 1)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '10:00',
        endTime: '10:30',
        durationMinutes: 30,
        hourlyRate: 300,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-102',
        queueNumber: 2,
        patientId: 'PAT-02',
        patientName: 'يوسف إبراهيم المنصوري',
        patientPhone: '+20 102 345 6789',
        fileNumber: 'EMR-2024-102',
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
          id: 'PAT-02',
          name: 'يوسف إبراهيم المنصوري',
          phone: '+20 102 345 6789',
          address: 'الجيزة - الدقي، شارع مصدق',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-02', name: 'د. نورهان السيد'),
        ],
        serviceName: 'عيادة الأطفال (غرفة 2)',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '10:30',
        endTime: '11:00',
        durationMinutes: 30,
        hourlyRate: 150,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-103',
        queueNumber: 3,
        patientId: 'PAT-03',
        patientName: 'مريم حسن الشريف',
        patientPhone: '+20 103 456 7890',
        fileNumber: 'EMR-2024-103',
        doctorId: 'DOC-03',
        doctorName: 'د. حازم زكي',
        clinicRoom: 'عيادة العظام (غرفة 3)',
        specialty: 'استشاري جراحة العظام والمفاصل',
        visitType: BookingTypeEnum.emergency,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.partiallyPaid,
        consultationFee: 450,
        paidAmount: 200,
        appointmentTime: today.add(const Duration(hours: 11, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 10, minutes: 45)),
        estimatedWaitMinutes: 5,
        notes: 'التواء حاد في مفصل الكاحل الأيمن بعد سقوط مع تورم شديد',
        createdAt: now.subtract(const Duration(hours: 2)),
        customer: const CustomerModel(
          id: 'PAT-03',
          name: 'مريم حسن الشريف',
          phone: '+20 103 456 7890',
          address: 'التجمع الخامس - النرجس عمارات',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceName: 'عيادة العظام (غرفة 3)',
        bookingType: BookingTypeEnum.emergency,
        date: today,
        startTime: '11:00',
        endTime: '11:30',
        durationMinutes: 30,
        hourlyRate: 450,
        totalPrice: 450,
      ),
      BookingModel(
        id: 'MED-104',
        queueNumber: 4,
        patientId: 'PAT-04',
        patientName: 'خالد عبد الرحمن السليطي',
        patientPhone: '+20 104 567 8901',
        fileNumber: 'EMR-2024-104',
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
          id: 'PAT-04',
          name: 'خالد عبد الرحمن السليطي',
          phone: '+20 104 567 8901',
          address: 'الشيخ زايد - كمبوند الربوة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceName: 'عيادة الباطنة (غرفة 1)',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '09:00',
        endTime: '09:30',
        durationMinutes: 30,
        hourlyRate: 150,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-105',
        queueNumber: 5,
        patientId: 'PAT-05',
        patientName: 'ندى عمر القحطاني',
        patientPhone: '+20 105 678 9012',
        fileNumber: 'EMR-2024-105',
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
        consultationFee: 250,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 11, minutes: 30)),
        arrivalTime: today.add(const Duration(hours: 11, minutes: 10)),
        estimatedWaitMinutes: 40,
        notes: 'تأخرت المريضة في الطريق وطلبت تأجيل الدور بعد الحالة رقم 6',
        createdAt: now.subtract(const Duration(hours: 4)),
        customer: const CustomerModel(
          id: 'PAT-05',
          name: 'ندى عمر القحطاني',
          phone: '+20 105 678 9012',
          address: 'مدينة نصر - الحي السابع',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-04', name: 'د. ريم المهدي'),
        ],
        serviceName: 'عيادة الرمد (غرفة 4)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '11:30',
        endTime: '12:00',
        durationMinutes: 30,
        hourlyRate: 250,
        totalPrice: 250,
      ),
      BookingModel(
        id: 'MED-106',
        queueNumber: 6,
        patientId: 'PAT-06',
        patientName: 'طارق زياد الهاشمي',
        patientPhone: '+20 106 789 0123',
        fileNumber: 'EMR-2024-106',
        doctorId: 'DOC-03',
        doctorName: 'د. حازم زكي',
        clinicRoom: 'عيادة العظام (غرفة 3)',
        specialty: 'استشاري جراحة العظام والمفاصل',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 350,
        paidAmount: 350,
        appointmentTime: today.add(const Duration(hours: 12, minutes: 0)),
        arrivalTime: today.add(const Duration(hours: 11, minutes: 35)),
        estimatedWaitMinutes: 25,
        notes: 'آلام حادة أسفل الظهر مع تنميل في الساق اليسرى بعد رفع حمل ثقيل',
        createdAt: now.subtract(const Duration(hours: 3)),
        customer: const CustomerModel(
          id: 'PAT-06',
          name: 'طارق زياد الهاشمي',
          phone: '+20 106 789 0123',
          address: 'مصر الجديدة - الكوربة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceName: 'عيادة العظام (غرفة 3)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '12:00',
        endTime: '12:30',
        durationMinutes: 30,
        hourlyRate: 350,
        totalPrice: 350,
      ),
      BookingModel(
        id: 'MED-107',
        queueNumber: 7,
        patientId: 'PAT-07',
        patientName: 'أسماء فاروق التميمي',
        patientPhone: '+20 107 890 1234',
        fileNumber: 'EMR-2024-107',
        doctorId: 'DOC-02',
        doctorName: 'د. نورهان السيد',
        clinicRoom: 'عيادة الأطفال (غرفة 2)',
        specialty: 'أخصائية طب الأطفال وحديثي الولادة',
        visitType: BookingTypeEnum.emergency,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        consultationFee: 300,
        paidAmount: 300,
        appointmentTime: today.add(const Duration(hours: 9, minutes: 15)),
        arrivalTime: today.add(const Duration(hours: 9, minutes: 0)),
        consultationStartTime: today.add(const Duration(hours: 9, minutes: 15)),
        estimatedWaitMinutes: 0,
        notes: 'حساسية مفاجئة وطفح جلدي حاد بعد تناول مضاد حيوي تم إعطاء حقنة مضادة للحساسية',
        createdAt: now.subtract(const Duration(hours: 6)),
        customer: const CustomerModel(
          id: 'PAT-07',
          name: 'أسماء فاروق التميمي',
          phone: '+20 107 890 1234',
          address: 'المهندسين - شارع جامعة الدول العربية',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-02', name: 'د. نورهان السيد'),
        ],
        serviceName: 'عيادة الأطفال (غرفة 2)',
        bookingType: BookingTypeEnum.emergency,
        date: today,
        startTime: '09:15',
        endTime: '09:45',
        durationMinutes: 30,
        hourlyRate: 300,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-108',
        branchId: 'branch_2',
        queueNumber: 8,
        patientId: 'PAT-08',
        patientName: 'وليد عصام النجار',
        patientPhone: '+20 108 901 2345',
        fileNumber: 'EMR-2024-108',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 300,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 12, minutes: 30)),
        arrivalTime: today.add(const Duration(hours: 12, minutes: 0)),
        estimatedWaitMinutes: 45,
        notes: 'فحص دوري شامل وشكوى من حموضة متكررة وارتجاع مريئي',
        createdAt: now.subtract(const Duration(hours: 2)),
        customer: const CustomerModel(
          id: 'PAT-08',
          name: 'وليد عصام النجار',
          phone: '+20 108 901 2345',
          address: 'الشروق - المنطقة الثامنة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceName: 'عيادة الباطنة (غرفة 1)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '12:30',
        endTime: '13:00',
        durationMinutes: 30,
        hourlyRate: 300,
        totalPrice: 300,
      ),
      BookingModel(
        id: 'MED-109',
        queueNumber: 9,
        patientId: 'PAT-09',
        patientName: 'هناء محمود البشير',
        patientPhone: '+20 109 012 3456',
        fileNumber: 'EMR-2024-109',
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
          id: 'PAT-09',
          name: 'هناء محمود البشير',
          phone: '+20 109 012 3456',
          address: 'الزمالك - شارع حسن صبري',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-04', name: 'د. ريم المهدي'),
        ],
        serviceName: 'عيادة الرمد (غرفة 4)',
        bookingType: BookingTypeEnum.revisit,
        date: today,
        startTime: '13:00',
        endTime: '13:30',
        durationMinutes: 30,
        hourlyRate: 150,
        totalPrice: 150,
      ),
      BookingModel(
        id: 'MED-110',
        queueNumber: 10,
        patientId: 'PAT-10',
        patientName: 'كريم ماجد الدوسري',
        patientPhone: '+20 110 123 4567',
        fileNumber: 'EMR-2024-110',
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
          id: 'PAT-10',
          name: 'كريم ماجد الدوسري',
          phone: '+20 110 123 4567',
          address: 'المعادي - دجلة',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-03', name: 'د. حازم زكي'),
        ],
        serviceName: 'عيادة العظام (غرفة 3)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '14:00',
        endTime: '14:30',
        durationMinutes: 30,
        hourlyRate: 350,
        totalPrice: 350,
      ),
      BookingModel(
        id: 'MED-111',
        queueNumber: 11,
        patientId: 'PAT-11',
        patientName: 'أحمد محمود البدري',
        patientPhone: '+20 111 234 5678',
        fileNumber: 'EMR-2024-111',
        doctorId: 'DOC-01',
        doctorName: 'د. رامي سلامة',
        clinicRoom: 'عيادة الباطنة (غرفة 1)',
        specialty: 'استشاري أمراض باطنة وسكري',
        visitType: BookingTypeEnum.newVisit,
        status: BookingStatusEnum.noShow,
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 300,
        paidAmount: 0,
        appointmentTime: today.add(const Duration(hours: 8, minutes: 30)),
        arrivalTime: null,
        estimatedWaitMinutes: 0,
        notes: 'لم يحضر المريض في الموعد المحدد ولم يتم تسجيل وصوله بالعيادة',
        createdAt: now.subtract(const Duration(days: 1)),
        customer: const CustomerModel(
          id: 'PAT-11',
          name: 'أحمد محمود البدري',
          phone: '+20 111 234 5678',
          address: 'مدينة نصر - عباس العقاد',
        ),
        technicians: const [
          TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة'),
        ],
        serviceName: 'عيادة الباطنة (غرفة 1)',
        bookingType: BookingTypeEnum.newVisit,
        date: today,
        startTime: '08:30',
        endTime: '09:00',
        durationMinutes: 30,
        hourlyRate: 300,
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
      String? dayOfWeekFilter;
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
        } else if (filter.key == 'dayOfWeek') {
          dayOfWeekFilter = filter.value.toString().trim().toLowerCase();
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

      // Day of week filter (for recurring schedules)
      if (dayOfWeekFilter != null &&
          dayOfWeekFilter.isNotEmpty &&
          dayOfWeekFilter != 'all') {
        filtered = filtered.where((b) {
          final scheds = b.recurrence?.daySchedules ?? [];
          final days = b.recurrence?.daysOfWeek ?? [];
          return scheds.any((s) => s.day.toLowerCase() == dayOfWeekFilter) ||
              days.any((d) => d.toLowerCase() == dayOfWeekFilter);
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
  Future<Either<Failures, BookingModel>> createBooking(
    BookingModel booking,
  ) async {
    try {
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
    BookingModel booking,
  ) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        final updated = booking.copyWith(updatedAt: DateTime.now());
        _bookings[index] = updated;
        return right(updated);
      }
      return left(const ServerFailure(errMessage: 'Booking not found'));
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
