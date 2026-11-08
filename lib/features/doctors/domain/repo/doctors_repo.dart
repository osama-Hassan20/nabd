import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import '../../data/models/doctor_leave_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/doctors_response_model.dart';

abstract class DoctorsRepo {
  Future<Either<Failures, DoctorsResponseModel>> getDoctors({
    required PaginationParams params,
  });

  Future<Either<Failures, DoctorModel>> getDoctorById({
    required String id,
  });

  Future<Either<Failures, DoctorModel>> addDoctor({
    required DoctorModel doctor,
  });

  Future<Either<Failures, DoctorModel>> updateDoctor({
    required DoctorModel doctor,
  });

  Future<Either<Failures, bool>> deleteDoctor({
    required String id,
  });

  Future<Either<Failures, DoctorScheduleModel?>> getDoctorSchedule({
    required String doctorId,
  });

  Future<Either<Failures, DoctorScheduleModel>> saveDoctorSchedule({
    required DoctorScheduleModel schedule,
  });

  Future<Either<Failures, List<DoctorLeaveModel>>> getDoctorLeaves({
    required String doctorId,
  });

  Future<Either<Failures, DoctorLeaveModel>> addDoctorLeave({
    required DoctorLeaveModel leave,
    bool force = false,
  });

  Future<Either<Failures, bool>> deleteDoctorLeave({
    required String leaveId,
  });

  Future<Either<Failures, int>> countConflictingBookings({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

