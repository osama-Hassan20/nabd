import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/medical_catalog_item_model.dart';
import '../repo/medical_catalog_repo.dart';

class GetMedicalCatalogParams {
  final String type;
  final String? query;

  const GetMedicalCatalogParams({required this.type, this.query});
}

class GetMedicalCatalogItemsUseCase {
  final MedicalCatalogRepo repo;

  GetMedicalCatalogItemsUseCase({required this.repo});

  Future<Either<Failures, List<MedicalCatalogItemModel>>> call(
    GetMedicalCatalogParams params,
  ) {
    return repo.getCatalogItems(type: params.type, query: params.query);
  }
}

