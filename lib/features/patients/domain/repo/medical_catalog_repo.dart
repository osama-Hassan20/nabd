import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/medical_catalog_item_model.dart';

abstract class MedicalCatalogRepo {
  /// Fetches medical catalog items by type ('allergy' or 'chronic_disease') with optional search query.
  Future<Either<Failures, List<MedicalCatalogItemModel>>> getCatalogItems({
    required String type,
    String? query,
  });

  /// Adds a new catalog item or returns existing if identical after Arabic normalization.
  Future<Either<Failures, MedicalCatalogItemModel>> addCatalogItem({
    required String name,
    required String type,
  });
}

