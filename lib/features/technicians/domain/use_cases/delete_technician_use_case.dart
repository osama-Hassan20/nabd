import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/technicians_repo.dart';

class DeleteTechnicianUseCase extends UseCase<bool, String> {
  final TechniciansRepo repo;

  DeleteTechnicianUseCase({required this.repo});

  @override
  Future<Either<Failures, bool>> call(String id) {
    return repo.deleteTechnician(id: id);
  }
}
