import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/bookings/domain/helpers/slot_generator_helper.dart';

class BookingsLocalHandler {
  BookingsLocalHandler._();

  static void _validateSlotAvailability(
    LocalServerRouter router,
    String reqPath,
    BookingModel booking, {
    DateTime? customNow,
    String? excludeBookingId,
  }) {
    final date = booking.date ?? booking.appointmentTime;
    final startTime = booking.startTime;
    if (date == null || startTime == null || startTime.isEmpty) return;

    final cairoToday = DoctorAvailabilityHelper.getTodayCairo(customNow);
    final targetDateOnly = DoctorAvailabilityHelper.dateOnly(date);
    if (targetDateOnly.isBefore(cairoToday)) {
      LocalServerRouter.throwHttpError(
        reqPath,
        422,
        'VALIDATION_ERROR',
        'booking_time_in_past',
      );
    }
    if (CairoTimeHelper.isSameDay(date, cairoToday)) {
      final cairoNow = customNow ?? CairoTimeHelper.now();
      final nowMinutes = cairoNow.hour * 60 + cairoNow.minute;
      final startMinutes = SlotGeneratorHelper.timeToMinutes(startTime);
      if (startMinutes <= nowMinutes) {
        LocalServerRouter.throwHttpError(
          reqPath,
          422,
          'VALIDATION_ERROR',
          'booking_time_in_past',
        );
      }
    }

    final doctorId = booking.doctorId ??
        (booking.technicians.isNotEmpty ? booking.technicians.first.id : null);
    if (doctorId == null) return;

    final schedJson = router.db.collection('doctorSchedules').cast<Map<String, dynamic>?>().firstWhere(
          (s) => s!['doctorId'] == doctorId,
          orElse: () => null,
        );
    if (schedJson == null) return;

    final schedule = DoctorScheduleModel.fromJson(schedJson);
    final leaves = router.db
        .collection('doctorLeaves')
        .where((l) => l['doctorId'] == doctorId && l['isDeleted'] != true)
        .map((l) => DoctorLeaveModel.fromJson(l))
        .toList();
    final doctorBookings = router.db
        .collection('bookings')
        .where((b) => b['isDeleted'] != true)
        .map((b) => BookingModel.fromJson(b))
        .toList();

    final isAvailable = SlotGeneratorHelper.isSlotStillAvailable(
      schedule: schedule,
      leaves: leaves,
      holidays: const [],
      doctorBookings: doctorBookings,
      serviceDurationMinutes: booking.durationMinutes ?? 20,
      date: date,
      startTime: startTime,
      customNow: customNow,
      excludeBookingId: excludeBookingId,
    );
    if (!isAvailable) {
      LocalServerRouter.throwHttpError(
        reqPath,
        409,
        'SLOT_CONFLICT',
        'slot_already_booked_or_unavailable',
      );
    }
  }

  static void register(LocalServerRouter router) {
    router.register('GET', 'bookings/summary', (req) async {
      final dateStr = req.queryParameters['date']?.toString();
      final selectedDate = dateStr != null
          ? (DateTime.tryParse(dateStr) ?? CairoTimeHelper.now())
          : CairoTimeHelper.now();
      final branchId = req.queryParameters['branchId']?.toString();
      final bookings = router.db
          .collection('bookings')
          .where((b) => b['isDeleted'] != true)
          .map((j) => BookingModel.fromJson(j))
          .toList();
      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: selectedDate,
        branchId: branchId,
      );
      return LocalServerRouter.ok(summary.toJson());
    });

    router.register('GET', 'bookings', (req) async {
      var items = router.db
          .collection('bookings')
          .where((b) => b['isDeleted'] != true)
          .toList();
      final dateFilter = req.queryParameters['date']?.toString();
      if (dateFilter != null && dateFilter.isNotEmpty) {
        items = items.where((b) {
          final raw = (b['appointmentTime'] ?? b['date'])?.toString() ?? '';
          return raw.startsWith(dateFilter);
        }).toList();
      }
      final page = int.tryParse(req.queryParameters['page']?.toString() ?? '1') ?? 1;
      final limit = int.tryParse(req.queryParameters['limit']?.toString() ?? '20') ?? 20;
      return LocalServerRouter.paginated(items, page: page, limit: limit);
    });

    router.register('GET', 'bookings/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('bookings').cast<Map<String, dynamic>?>().firstWhere(
            (b) => b!['id'] == id && b['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'bookings', (req) async {
      final list = router.db.collection('bookings');
      final record = Map<String, dynamic>.from(req.body);
      final customNowRaw = record.remove('customNow')?.toString();
      final customNow = customNowRaw != null ? DateTime.tryParse(customNowRaw) : null;
      _validateSlotAvailability(
        router,
        req.path,
        BookingModel.fromJson(record),
        customNow: customNow,
      );
      record['id'] ??= 'BOOK-${DateTime.now().millisecondsSinceEpoch}';
      record['queueNumber'] ??= list.length + 1;
      record['revision'] = router.db.nextRevision('booking:${record['id']}');
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'bookings/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      final body = Map<String, dynamic>.from(req.body);
      final customNowRaw = body.remove('customNow')?.toString();
      final customNow = customNowRaw != null ? DateTime.tryParse(customNowRaw) : null;
      final existing = BookingModel.fromJson(list[idx]);
      final merged = {...list[idx], ...body, 'id': id};
      final next = BookingModel.fromJson(merged);
      if (existing.date != next.date ||
          existing.startTime != next.startTime ||
          existing.doctorId != next.doctorId) {
        _validateSlotAvailability(
          router,
          req.path,
          next,
          customNow: customNow,
          excludeBookingId: id,
        );
      }
      list[idx] = merged;
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PATCH', 'bookings/{id}/status', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      list[idx] = {...list[idx], ...req.body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PATCH', 'bookings/{id}/technician', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      list[idx] = {...list[idx], ...req.body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'bookings/{id}/discount', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      list[idx] = {
        ...list[idx],
        'discountType': req.body['discountType'],
        'discountValue': req.body['discountValue'],
        'discountReason': req.body['reason'],
        if (req.body['approvedByUserId'] != null)
          'discountApprovedByUserId': req.body['approvedByUserId'],
        'discountApprovedAt': DateTime.now().toUtc().toIso8601String(),
        'discountRemovedReason': null,
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'bookings/{id}/discount', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Booking not found');
      }
      list[idx] = {
        ...list[idx],
        'discountType': 'none',
        'discountValue': 0,
        'discountReason': null,
        if (req.body['reason'] != null)
          'discountRemovedReason': req.body['reason'],
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'bookings/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx != -1) {
        list[idx] = {...list[idx], 'status': 'cancelled'};
        router.db.persist();
      }
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('GET', 'doctors/{doctorId}/bookings', (req) async {
      final doctorId = req.pathParams['doctorId']!;
      final dateFilter = req.queryParameters['date']?.toString();
      final items = router.db.collection('bookings').where((b) {
        if (b['isDeleted'] == true) return false;
        if (b['doctorId'] != doctorId) return false;
        if (dateFilter != null && dateFilter.isNotEmpty) {
          final raw = (b['appointmentTime'] ?? b['date'])?.toString() ?? '';
          return raw.startsWith(dateFilter);
        }
        return true;
      }).toList();
      return LocalServerRouter.ok(items);
    });
  }
}
