import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/drug_model.dart';
import '../repo/drugs_repo.dart';

class GetDrugsParams extends Equatable {
  final String? query;
  final String? categoryId;
  final String? reviewFilter;
  final bool includeArchived;

  const GetDrugsParams({
    this.query,
    this.categoryId,
    this.reviewFilter,
    this.includeArchived = false,
  });

  @override
  List<Object?> get props => [query, categoryId, reviewFilter, includeArchived];
}

class GetDrugsCatalogUseCase {
  final DrugsRepo repo;

  GetDrugsCatalogUseCase({required this.repo});

  Future<Either<Failures, List<DrugModel>>> call(GetDrugsParams params) {
    return repo.getDrugs(
      query: params.query,
      categoryId: params.categoryId,
      reviewFilter: params.reviewFilter,
      includeArchived: params.includeArchived,
    );
  }
}

