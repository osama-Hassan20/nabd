import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/medical_catalog_item_model.dart';
import '../repo/medical_catalog_repo.dart';

class AddMedicalCatalogItemParams {
  final String name;
  final String type;

  const AddMedicalCatalogItemParams({required this.name, required this.type});
}

class AddMedicalCatalogItemUseCase {
  final MedicalCatalogRepo repo;

  AddMedicalCatalogItemUseCase({required this.repo});

  Future<Either<Failures, MedicalCatalogItemModel>> call(
    AddMedicalCatalogItemParams params,
  ) {
    return repo.addCatalogItem(name: params.name, type: params.type);
  }
}

