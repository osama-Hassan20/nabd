import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class SaveVisitDraftUseCase implements UseCase<VisitModel, VisitModel> {
  final VisitsRepo repo;

  SaveVisitDraftUseCase({required this.repo});

  @override
  Future<Either<Failures, VisitModel>> call(VisitModel draft) {
    return repo.saveVisitDraft(draft: draft);
  }
}
