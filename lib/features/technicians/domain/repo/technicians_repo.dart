import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../data/models/technician_leave_model.dart';
import '../../data/models/technician_model.dart';
import '../../data/models/technicians_response_model.dart';

abstract class TechniciansRepo {
  Future<Either<Failures, TechniciansResponseModel>> getTechnicians({
    required PaginationParams params,
  });

  Future<Either<Failures, TechnicianModel>> getTechnicianById({
    required String id,
  });

  Future<Either<Failures, TechnicianModel>> addTechnician({
    required TechnicianModel technician,
  });

  Future<Either<Failures, TechnicianModel>> updateTechnician({
    required TechnicianModel technician,
  });

  Future<Either<Failures, bool>> deleteTechnician({
    required String id,
  });

  Future<Either<Failures, List<TechnicianLeaveModel>>> getTechnicianLeaves({
    required String technicianId,
  });

  Future<Either<Failures, TechnicianLeaveModel>> addTechnicianLeave({
    required TechnicianLeaveModel leave,
  });

  Future<Either<Failures, bool>> deleteTechnicianLeave({
    required String leaveId,
  });
}
