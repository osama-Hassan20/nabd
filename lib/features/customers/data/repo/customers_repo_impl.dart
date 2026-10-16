import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';

import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';

import '../../domain/repo/customers_repo.dart';
import '../models/customer_model.dart';
import '../models/customers_response_model.dart';

class CustomersRepoImpl implements CustomersRepo {
  final ApiConsumer? apiConsumer;

  CustomersRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  final List<CustomerModel> _customers = [];

  void _initMockData() {
    final now = DateTime.now();

    _customers.addAll([
      CustomerModel(
        id: 'CUST-01',
        name: 'شيخة الكواري',
        phone: '+974 5512 3456',
        address: 'الدوحة - اللؤلؤة، بورتو أرابيا برج 12',
        totalBookings: 8,
        upcomingBookings: 2,
        hasRepeatedBooking: true,
        recurrence: const RecurrenceRuleModel(
          frequency: 'weekly',
          isOngoing: true,
          daySchedules: [
            RecurringDaySchedule(
              day: 'sunday',
              startTime: '10:00',
              endTime: '12:00',
            ),
            RecurringDaySchedule(
              day: 'tuesday',
              startTime: '14:00',
              endTime: '16:00',
            ),
          ],
        ),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      CustomerModel(
        id: 'CUST-02',
        name: 'محمد المري',
        phone: '+974 6623 4567',
        address: 'الدوحة - الخليج الغربي، أبراج الفردان',
        totalBookings: 5,
        upcomingBookings: 1,
        hasRepeatedBooking: false,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      CustomerModel(
        id: 'CUST-03',
        name: 'فاطمة السليطي',
        phone: '+974 7734 5678',
        address: 'لوسيل - مارينا بروميناد، برج 4',
        totalBookings: 12,
        upcomingBookings: 3,
        hasRepeatedBooking: true,
        recurrence: const RecurrenceRuleModel(
          frequency: 'weekly',
          isOngoing: true,
          daySchedules: [
            RecurringDaySchedule(
              day: 'monday',
              startTime: '09:00',
              endTime: '11:00',
            ),
            RecurringDaySchedule(
              day: 'thursday',
              startTime: '16:00',
              endTime: '18:00',
            ),
          ],
        ),
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      CustomerModel(
        id: 'CUST-04',
        name: 'عبدالله الكعبي',
        phone: '+974 3345 6789',
        address: 'الريان - الوعب، فيلا 15',
        totalBookings: 3,
        upcomingBookings: 1,
        hasRepeatedBooking: false,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      CustomerModel(
        id: 'CUST-05',
        name: 'نورة الهاجري',
        phone: '+974 5556 7890',
        address: 'الوكرة - قرية ازدان، فيلا 22',
        totalBookings: 6,
        upcomingBookings: 0,
        hasRepeatedBooking: false,
        createdAt: now.subtract(const Duration(days: 75)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      CustomerModel(
        id: 'CUST-06',
        name: 'خالد المهندي',
        phone: '+974 6667 8901',
        address: 'الخور - شاطئ الفركية، فيلا 8',
        totalBookings: 4,
        upcomingBookings: 1,
        hasRepeatedBooking: false,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      CustomerModel(
        id: 'CUST-07',
        name: 'ريم العطية',
        phone: '+974 7788 9900',
        address: 'الدوحة - الدفنة، برج النصر',
        totalBookings: 9,
        upcomingBookings: 2,
        hasRepeatedBooking: true,
        recurrence: const RecurrenceRuleModel(
          frequency: 'weekly',
          isOngoing: true,
          daySchedules: [
            RecurringDaySchedule(
              day: 'saturday',
              startTime: '11:00',
              endTime: '13:00',
            ),
          ],
        ),
        createdAt: now.subtract(const Duration(days: 140)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      CustomerModel(
        id: 'CUST-08',
        name: 'سالم النعيمي',
        phone: '+974 3311 2233',
        address: 'الشحانية - منطقة المزارع، فيلا 2',
        totalBookings: 2,
        upcomingBookings: 0,
        hasRepeatedBooking: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
    ]);
  }

  @override
  Future<Either<Failures, CustomersResponseModel>> getCustomers({
    required PaginationParams params,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      List<CustomerModel> filtered = List.from(_customers);

      // Search query
      String? query;
      for (final f in params.filterList) {
        if (f.key == 'search') {
          query = f.value?.toString().toLowerCase().trim();
          break;
        }
      }

      if (query != null && query.isNotEmpty) {
        filtered = filtered.where((c) {
          final name = c.name?.toLowerCase() ?? '';
          final phone = c.phone?.toLowerCase() ?? '';
          final address = c.address?.toLowerCase() ?? '';
          return name.contains(query!) ||
              phone.contains(query) ||
              address.contains(query);
        }).toList();
      }

      // Sort newest first
      filtered.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );

      final totalCount = filtered.length;
      final limit = params.limit ?? 10;
      final totalPages = (totalCount / limit).ceil().clamp(1, 9999);
      final currentPage = (params.page ?? 1).clamp(1, totalPages);

      final startIndex = (currentPage - 1) * limit;
      final pagedItems = startIndex < totalCount
          ? filtered.skip(startIndex).take(limit).toList()
          : <CustomerModel>[];

      return Right(
        CustomersResponseModel(
          items: pagedItems,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: currentPage,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CustomerModel>> getCustomerById({
    required String id,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        return Right(_customers[index]);
      }
      return Left(ServerFailure(errMessage: 'العميل غير موجود'));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CustomerModel>> addCustomer({
    required CustomerModel customer,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final newId = 'CUST-${_customers.length + 1}'.padLeft(7, '0');
      final newCustomer = customer.copyWith(
        id: customer.id ?? newId,
        totalBookings: 0,
        upcomingBookings: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _customers.insert(0, newCustomer);
      return Right(newCustomer);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CustomerModel>> updateCustomer({
    required CustomerModel customer,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        final existing = _customers[index];
        final updated = customer.copyWith(
          totalBookings: existing.totalBookings,
          upcomingBookings: existing.upcomingBookings,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        _customers[index] = updated;
        return Right(updated);
      }
      return Left(ServerFailure(errMessage: 'العميل غير موجود للتعديل'));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> deleteCustomer({required String id}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final index = _customers.indexWhere((c) => c.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'العميل غير موجود'));
      }

      final customer = _customers[index];
      if ((customer.upcomingBookings ?? 0) > 0) {
        return Left(
          ServerFailure(
            errMessage:
                'لا يمكن حذف العميل لوجود حجوزات نشطة أو قادمة مسجلة له.',
          ),
        );
      }

      _customers.removeAt(index);
      return const Right('تم حذف العميل بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
