import 'package:dartz/dartz.dart';
import 'package:purexo/core/api/api_consumer.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/uses_cases/params.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/booking_summary_model.dart';
import 'package:purexo/features/bookings/data/models/bookings_response_model.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/domain/repo/bookings_repo.dart';
import 'package:purexo/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:purexo/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:purexo/features/customers/data/models/customer_model.dart';
import 'package:purexo/features/technicians/data/models/technician_model.dart';

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
        id: 'BK-1001',
        customer: const CustomerModel(
          id: 'CUST-01',
          name: 'شيخة الكواري',
          phone: '+974 5512 3456',
          address: 'الدوحة - اللؤلؤة، بورتو أرابيا برج 12',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-01', name: 'م. أحمد الشافعي'),
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
        ],
        serviceName: 'تنظيف شامل للفيلا',
        bookingType: BookingTypeEnum.oneTime,
        date: today,
        startTime: '09:00',
        endTime: '12:00',
        durationMinutes: 180,
        hourlyRate: 80,
        totalPrice: 240,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'يرجى التركيز على المطبخ والصالة الرئيسية',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      BookingModel(
        id: 'BK-1002',
        customer: const CustomerModel(
          id: 'CUST-02',
          name: 'محمد المري',
          phone: '+974 6623 4567',
          address: 'الدوحة - الخليج الغربي، أبراج الفردان',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
        ],
        serviceName: 'صيانة تكييف مركزي',
        bookingType: BookingTypeEnum.oneTime,
        date: today,
        startTime: '13:00',
        endTime: '15:00',
        durationMinutes: 120,
        hourlyRate: 75,
        totalPrice: 150,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.unpaid,
        notes: 'المكيف يصدر صوتاً مرتفعاً في غرفة النوم',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BookingModel(
        id: 'BK-1003',
        customer: const CustomerModel(
          id: 'CUST-03',
          name: 'فاطمة السليطي',
          phone: '+974 7734 5678',
          address: 'لوسيل - مارينا بروميناد، برج 4',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-03', name: 'م. يوسف النجار'),
          TechnicianModel(id: 'TECH-05', name: 'م. ماجد القاضي'),
        ],
        serviceName: 'تنظيف سجاد ومفروشات',
        bookingType: BookingTypeEnum.recurring,
        date: today,
        recurrence: RecurrenceRuleModel(
          frequency: 'weekly',
          daysOfWeek: const ['sunday', 'wednesday'],
          daySchedules: const [
            RecurringDaySchedule(
              day: 'sunday',
              startTime: '10:00',
              endTime: '12:30',
            ),
            RecurringDaySchedule(
              day: 'wednesday',
              startTime: '15:30',
              endTime: '18:00',
            ),
          ],
          startDate: today.subtract(const Duration(days: 14)),
          isOngoing: true,
        ),
        startTime: '15:30',
        endTime: '18:00',
        durationMinutes: 150,
        hourlyRate: 70,
        totalPrice: 175,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'حجز دوري أسبوعي كل أحد وأربعاء',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      BookingModel(
        id: 'BK-1004',
        customer: const CustomerModel(
          id: 'CUST-04',
          name: 'جاسم الهاجري',
          phone: '+974 3345 6789',
          address: 'الريان - الوعب، مجمع النخيل',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-01', name: 'م. أحمد الشافعي'),
          TechnicianModel(id: 'TECH-04', name: 'م. طارق العسيري'),
        ],
        serviceName: 'مكافحة حشرات وتعقيم',
        bookingType: BookingTypeEnum.oneTime,
        date: today.add(const Duration(days: 1)),
        startTime: '10:00',
        endTime: '12:00',
        durationMinutes: 120,
        hourlyRate: 90,
        totalPrice: 180,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.unpaid,
        notes: 'مطلوب مبيدات بدون رائحة ومواد صديقة للبيئة',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      BookingModel(
        id: 'BK-1005',
        customer: const CustomerModel(
          id: 'CUST-05',
          name: 'مريم المنصوري',
          phone: '+974 5598 7654',
          address: 'الدوحة - السد، شارع سحيم بن حمد',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-04', name: 'م. طارق العسيري'),
        ],
        serviceName: 'تنظيف واجهات زجاجية',
        bookingType: BookingTypeEnum.oneTime,
        date: today.add(const Duration(days: 2)),
        startTime: '08:00',
        endTime: '11:00',
        durationMinutes: 180,
        hourlyRate: 100,
        totalPrice: 300,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'الدور الثاني بحاجة لمعدات تنظيف مرتفعة',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BookingModel(
        id: 'BK-1006',
        customer: const CustomerModel(
          id: 'CUST-06',
          name: 'عبد الله الكعبي',
          phone: '+974 6687 6543',
          address: 'الوكرة - حي الجبل، فيلا 18',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
        ],
        serviceName: 'صيانة سباكة ومضخات',
        bookingType: BookingTypeEnum.oneTime,
        date: today.subtract(const Duration(days: 1)),
        startTime: '11:00',
        endTime: '13:00',
        durationMinutes: 120,
        hourlyRate: 85,
        totalPrice: 170,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'تم استبدال مضخة المياه والفلتر بنجاح',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      BookingModel(
        id: 'BK-1007',
        customer: const CustomerModel(
          id: 'CUST-07',
          name: 'نورة المهندي',
          phone: '+974 7776 5432',
          address: 'الدوحة - مدينة خليفة الجنوبية',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-03', name: 'م. يوسف النجار'),
        ],
        serviceName: 'تنظيف خزانات مياه وتعقيم',
        bookingType: BookingTypeEnum.oneTime,
        date: today.subtract(const Duration(days: 2)),
        startTime: '09:00',
        endTime: '12:00',
        durationMinutes: 180,
        hourlyRate: 95,
        totalPrice: 285,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'تم فحص جودة المياه ونظافة الخزان الأرضي',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      BookingModel(
        id: 'BK-1008',
        customer: const CustomerModel(
          id: 'CUST-08',
          name: 'أحمد فخرو',
          phone: '+974 3365 4321',
          address: 'الدوحة - الدفنة، المنطقة الدبلوماسية',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-01', name: 'م. أحمد الشافعي'),
        ],
        serviceName: 'تنظيف مجالس وكنب بالبخار',
        bookingType: BookingTypeEnum.oneTime,
        date: today.subtract(const Duration(days: 3)),
        startTime: '14:00',
        endTime: '16:00',
        durationMinutes: 120,
        hourlyRate: 70,
        totalPrice: 140,
        status: BookingStatusEnum.cancelled,
        paymentStatus: PaymentStatusEnum.unpaid,
        notes: 'اعتذر العميل بسبب ارتباط طارئ وتم الإلغاء',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      BookingModel(
        id: 'BK-1009',
        customer: const CustomerModel(
          id: 'CUST-09',
          name: 'ريم النعيمي',
          phone: '+974 5554 3210',
          address: 'الريان - الغرافة، شارع الاتحاد',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-05', name: 'م. ماجد القاضي'),
        ],
        serviceName: 'تطهير وتعقيم مكاتب',
        bookingType: BookingTypeEnum.recurring,
        date: today.add(const Duration(days: 3)),
        recurrence: RecurrenceRuleModel(
          frequency: 'weekly',
          daysOfWeek: const ['saturday', 'tuesday'],
          daySchedules: const [
            RecurringDaySchedule(
              day: 'saturday',
              startTime: '09:00',
              endTime: '12:00',
            ),
            RecurringDaySchedule(
              day: 'tuesday',
              startTime: '16:00',
              endTime: '19:00',
            ),
          ],
          startDate: today.subtract(const Duration(days: 30)),
          endDate: today.add(const Duration(days: 60)),
          isOngoing: false,
        ),
        startTime: '16:00',
        endTime: '19:00',
        durationMinutes: 180,
        hourlyRate: 80,
        totalPrice: 240,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'دورية تعقيم مرتين أسبوعياً (السبت والثلاثاء)',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      BookingModel(
        id: 'BK-1010',
        customer: const CustomerModel(
          id: 'CUST-10',
          name: 'طارق الدوسري',
          phone: '+974 6643 2109',
          address: 'الدوحة - الهلال، الطريق الدائري الرابع',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-04', name: 'م. طارق العسيري'),
        ],
        serviceName: 'صيانة كهرباء وإنارة منزلية',
        bookingType: BookingTypeEnum.oneTime,
        date: today.subtract(const Duration(days: 4)),
        startTime: '10:00',
        endTime: '11:30',
        durationMinutes: 90,
        hourlyRate: 80,
        totalPrice: 120,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'تم فحص القواطع الكهربائية وصيانتها',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      BookingModel(
        id: 'BK-1011',
        customer: const CustomerModel(
          id: 'CUST-11',
          name: 'ليلى العطية',
          phone: '+974 7732 1098',
          address: 'لوسيل - جبل ثعيلب، شارع 20',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
        ],
        serviceName: 'غسيل واجهات حجرية بضغط عالي',
        bookingType: BookingTypeEnum.oneTime,
        date: today.add(const Duration(days: 4)),
        startTime: '08:30',
        endTime: '12:00',
        durationMinutes: 210,
        hourlyRate: 90,
        totalPrice: 315,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.unpaid,
        notes: 'مطلوب إحضار خراطيم مياه إضافية',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      BookingModel(
        id: 'BK-1012',
        customer: const CustomerModel(
          id: 'CUST-12',
          name: 'حمد الخاطر',
          phone: '+974 3321 0987',
          address: 'الدوحة - مشيرب قلب الدوحة',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-05', name: 'م. ماجد القاضي'),
        ],
        serviceName: 'تنظيف أرضيات وتلميع رخام',
        bookingType: BookingTypeEnum.oneTime,
        date: today.subtract(const Duration(days: 5)),
        startTime: '13:00',
        endTime: '17:00',
        durationMinutes: 240,
        hourlyRate: 85,
        totalPrice: 340,
        status: BookingStatusEnum.cancelled,
        paymentStatus: PaymentStatusEnum.unpaid,
        notes: 'تم الإلغاء بطلب العميل بسبب السفر',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      BookingModel(
        id: 'BK-1013',
        customer: const CustomerModel(
          id: 'CUST-01',
          name: 'شيخة الكواري',
          phone: '+974 5512 3456',
          address: 'الدوحة - اللؤلؤة، بورتو أرابيا برج 12',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-01', name: 'م. أحمد الشافعي'),
        ],
        serviceName: 'صيانة دورية للمسابح والحدائق',
        bookingType: BookingTypeEnum.recurring,
        date: today,
        recurrence: RecurrenceRuleModel(
          frequency: 'weekly',
          daysOfWeek: const ['monday', 'thursday'],
          daySchedules: const [
            RecurringDaySchedule(
              day: 'monday',
              startTime: '08:00',
              endTime: '11:00',
            ),
            RecurringDaySchedule(
              day: 'thursday',
              startTime: '08:00',
              endTime: '11:00',
            ),
          ],
          startDate: today.subtract(const Duration(days: 45)),
          isOngoing: true,
        ),
        startTime: '08:00',
        endTime: '11:00',
        durationMinutes: 180,
        hourlyRate: 85,
        totalPrice: 255,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'دورية أسبوعية منتظمة كل اثنين وخميس صباحاً',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      BookingModel(
        id: 'BK-1014',
        customer: const CustomerModel(
          id: 'CUST-06',
          name: 'سالم الكعبي',
          phone: '+974 6698 7654',
          address: 'الخور - حي الشاطئ، فيلا 18',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
          TechnicianModel(id: 'TECH-04', name: 'م. طارق العسيري'),
        ],
        serviceName: 'تنظيف وصيانة دورية للفيلات',
        bookingType: BookingTypeEnum.recurring,
        date: today,
        recurrence: RecurrenceRuleModel(
          frequency: 'weekly',
          daysOfWeek: const ['friday'],
          daySchedules: const [
            RecurringDaySchedule(
              day: 'friday',
              startTime: '14:00',
              endTime: '18:00',
            ),
          ],
          startDate: today.subtract(const Duration(days: 20)),
          endDate: today.add(const Duration(days: 40)),
          isOngoing: false,
        ),
        startTime: '14:00',
        endTime: '18:00',
        durationMinutes: 240,
        hourlyRate: 90,
        totalPrice: 360,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'دورية كل يوم جمعة بعد الصلاة',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      BookingModel(
        id: 'BK-1015',
        customer: const CustomerModel(
          id: 'CUST-01',
          name: 'شيخة الكواري',
          phone: '+974 5512 3456',
          address: 'الدوحة - اللؤلؤة، بورتو أرابيا برج 12',
        ),
        technicians: const [
          TechnicianModel(id: 'TECH-02', name: 'م. عمر عبد العزيز'),
        ],
        serviceName: 'تنظيف سجاد وستائر بالبخار',
        bookingType: BookingTypeEnum.recurring,
        date: today.subtract(const Duration(days: 60)),
        recurrence: RecurrenceRuleModel(
          frequency: 'weekly',
          daysOfWeek: const ['sunday'],
          daySchedules: const [
            RecurringDaySchedule(
              day: 'sunday',
              startTime: '10:00',
              endTime: '12:00',
            ),
          ],
          startDate: today.subtract(const Duration(days: 120)),
          endDate: today.subtract(const Duration(days: 30)),
          isOngoing: false,
        ),
        startTime: '10:00',
        endTime: '12:00',
        durationMinutes: 120,
        hourlyRate: 80,
        totalPrice: 160,
        status: BookingStatusEnum.completed,
        paymentStatus: PaymentStatusEnum.paid,
        notes: 'عقد دوري سابق انتهت مدته المحددة',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ]);
  }

  @override
  Future<Either<Failures, BookingSummaryModel>> getBookingSummary() async {
    try {
      final total = _bookings.length;
      final upcoming = _bookings
          .where((b) => b.status == BookingStatusEnum.scheduled)
          .length;
      final completed = _bookings
          .where((b) => b.status == BookingStatusEnum.completed)
          .length;
      final cancelled = _bookings
          .where((b) => b.status == BookingStatusEnum.cancelled)
          .length;

      return right(
        BookingSummaryModel(
          totalBookings: total,
          upcomingBookings: upcoming,
          completedBookings: completed,
          cancelledBookings: cancelled,
        ),
      );
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

      // Status filter
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'all') {
        filtered = filtered.where((b) {
          return b.status?.value.toLowerCase() == statusFilter;
        }).toList();
      }

      // Date filter (YYYY-MM-DD or YYYY-MM)
      if (dateFilter != null && dateFilter.isNotEmpty) {
        filtered = filtered.where((b) {
          if (b.date == null) return false;
          final d = b.date!;
          final dayFormatted =
              "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          final monthFormatted =
              "${d.year}-${d.month.toString().padLeft(2, '0')}";
          if (dateFilter!.length == 7) {
            return monthFormatted == dateFilter;
          }
          return dayFormatted == dateFilter;
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
        _bookings[index] = _bookings[index].copyWith(
          status: params.newStatus,
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
      _bookings.removeWhere((b) => b.id == bookingId);
      return right(unit);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }
}
