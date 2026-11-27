import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';

class BookingsLocalHandler {
  BookingsLocalHandler._();

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
      list[idx] = {...list[idx], ...req.body, 'id': id};
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
      list[idx] = {...list[idx], ...req.body, 'id': id};
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
        'discountType': null,
        'discountValue': null,
        'discountAmount': 0,
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'bookings/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('bookings');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx != -1) {
        list[idx] = {...list[idx], 'isDeleted': true};
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
