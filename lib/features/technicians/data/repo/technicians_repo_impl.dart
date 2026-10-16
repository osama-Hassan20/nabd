import 'package:dartz/dartz.dart';
import 'package:purexo/core/api/api_consumer.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/uses_cases/params.dart';

import '../../domain/repo/technicians_repo.dart';
import '../models/enums/technician_gender_enum.dart';
import '../models/enums/technician_status_enum.dart';
import '../models/technician_leave_model.dart';
import '../models/technician_model.dart';
import '../models/technicians_response_model.dart';

class TechniciansRepoImpl implements TechniciansRepo {
  final ApiConsumer? apiConsumer;

  TechniciansRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  final List<TechnicianModel> _technicians = [];
  final List<TechnicianLeaveModel> _leaves = [];

  void _initMockData() {
    final now = DateTime.now();

    _leaves.addAll([
      TechnicianLeaveModel(
        id: 'LEAVE-01',
        technicianId: 'TECH-03',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 2)),
        reason: 'إجازة سنوية اعتيادية',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      TechnicianLeaveModel(
        id: 'LEAVE-02',
        technicianId: 'TECH-01',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 14)),
        reason: 'إجازة مناسبة عائلية',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TechnicianLeaveModel(
        id: 'LEAVE-03',
        technicianId: 'TECH-05',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 25)),
        reason: 'إجازة مرضية سابقة',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
    ]);

    _technicians.addAll([
      TechnicianModel(
        id: 'TECH-01',
        name: 'أحمد الشافعي',
        phone: '+974 5501 1122',
        gender: TechnicianGenderEnum.male,
        status: TechnicianStatusEnum.available,
        todayTasksCount: 2,
        upcomingBookingsCount: 4,
        completedBookingsCount: 28,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      TechnicianModel(
        id: 'TECH-02',
        name: 'عمر عبد العزيز',
        phone: '+974 5502 2233',
        gender: TechnicianGenderEnum.male,
        status: TechnicianStatusEnum.busy,
        todayTasksCount: 3,
        upcomingBookingsCount: 5,
        completedBookingsCount: 34,
        createdAt: now.subtract(const Duration(days: 220)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      TechnicianModel(
        id: 'TECH-03',
        name: 'يوسف النجار',
        phone: '+974 5503 3344',
        gender: TechnicianGenderEnum.male,
        status: TechnicianStatusEnum.onLeave,
        todayTasksCount: 0,
        upcomingBookingsCount: 2,
        completedBookingsCount: 42,
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      TechnicianModel(
        id: 'TECH-04',
        name: 'مريم المنصور',
        phone: '+974 5504 4455',
        gender: TechnicianGenderEnum.female,
        status: TechnicianStatusEnum.available,
        todayTasksCount: 1,
        upcomingBookingsCount: 3,
        completedBookingsCount: 19,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      TechnicianModel(
        id: 'TECH-05',
        name: 'فاطمة الكواري',
        phone: '+974 5505 5566',
        gender: TechnicianGenderEnum.female,
        status: TechnicianStatusEnum.busy,
        todayTasksCount: 2,
        upcomingBookingsCount: 4,
        completedBookingsCount: 25,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ]);
  }

  @override
  Future<Either<Failures, TechniciansResponseModel>> getTechnicians({
    required PaginationParams params,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      List<TechnicianModel> filtered = List.from(_technicians);

      final filterList = params.filterList;
      for (final filter in filterList) {
        if (filter.key == 'search' &&
            filter.value != null &&
            filter.value.toString().isNotEmpty) {
          final query = filter.value.toString().toLowerCase().trim();
          filtered = filtered.where((t) {
            final name = t.name?.toLowerCase() ?? '';
            final phone = t.phone?.toLowerCase() ?? '';
            final id = t.id?.toLowerCase() ?? '';
            return name.contains(query) ||
                phone.contains(query) ||
                id.contains(query);
          }).toList();
        }

        if (filter.key == 'status' &&
            filter.value != null &&
            filter.value.toString().isNotEmpty) {
          final statusVal = filter.value.toString();
          filtered = filtered
              .where((t) => t.status?.value == statusVal)
              .toList();
        }
      }

      final page = params.page ?? 1;
      final limit = params.limit ?? 10;
      final totalCount = filtered.length;
      final totalPages = (totalCount / limit).ceil().clamp(1, 9999);

      final startIndex = (page - 1) * limit;
      final pagedItems = startIndex < totalCount
          ? filtered.skip(startIndex).take(limit).toList()
          : <TechnicianModel>[];

      return Right(
        TechniciansResponseModel(
          items: pagedItems,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: page,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, TechnicianModel>> getTechnicianById({
    required String id,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final tech = _technicians.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Technician not found'),
      );
      return Right(tech);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, TechnicianModel>> addTechnician({
    required TechnicianModel technician,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final newId = 'TECH-0${_technicians.length + 1}';
      final now = DateTime.now();

      final created = technician.copyWith(
        id: newId,
        status: TechnicianStatusEnum.available,
        todayTasksCount: 0,
        upcomingBookingsCount: 0,
        completedBookingsCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      _technicians.insert(0, created);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, TechnicianModel>> updateTechnician({
    required TechnicianModel technician,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _technicians.indexWhere((t) => t.id == technician.id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'Technician not found'));
      }

      final existing = _technicians[index];
      final updated = existing.copyWith(
        name: technician.name ?? existing.name,
        phone: technician.phone ?? existing.phone,
        gender: technician.gender ?? existing.gender,
        image: technician.image ?? existing.image,
        updatedAt: DateTime.now(),
      );

      _technicians[index] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteTechnician({required String id}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final tech = _technicians.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Technician not found'),
      );

      // Guard check: cannot delete if active/upcoming bookings exist
      if ((tech.upcomingBookingsCount ?? 0) > 0 ||
          (tech.todayTasksCount ?? 0) > 0) {
        return Left(ServerFailure(errMessage: 'tech_delete_guard_msg'));
      }

      _technicians.removeWhere((t) => t.id == id);
      _leaves.removeWhere((l) => l.technicianId == id);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<TechnicianLeaveModel>>> getTechnicianLeaves({
    required String technicianId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final leaves =
          _leaves.where((l) => l.technicianId == technicianId).toList()..sort(
            (a, b) => (b.startDate ?? DateTime.now()).compareTo(
              a.startDate ?? DateTime.now(),
            ),
          );
      return Right(leaves);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, TechnicianLeaveModel>> addTechnicianLeave({
    required TechnicianLeaveModel leave,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final newId = 'LEAVE-0${_leaves.length + 1}';
      final created = leave.copyWith(id: newId, createdAt: DateTime.now());

      _leaves.insert(0, created);

      // Update technician status to on_leave if currently active
      if (created.isCurrentlyActive()) {
        final index = _technicians.indexWhere(
          (t) => t.id == created.technicianId,
        );
        if (index != -1) {
          _technicians[index] = _technicians[index].copyWith(
            status: TechnicianStatusEnum.onLeave,
          );
        }
      }

      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteTechnicianLeave({
    required String leaveId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _leaves.removeWhere((l) => l.id == leaveId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
