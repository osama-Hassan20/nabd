import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/enums/medical_catalog_kind_enum.dart';
import '../../data/models/medical_catalog_entry_model.dart';

abstract class MedicalCatalogsRepo {
  Future<Either<Failures, List<MedicalCatalogEntryModel>>> getEntries({
    required MedicalCatalogKindEnum kind,
    String? query,
    String? category,
  });

  Future<Either<Failures, MedicalCatalogEntryModel>> addEntry(
    MedicalCatalogEntryModel entry,
  );

  Future<Either<Failures, MedicalCatalogEntryModel>> updateEntry(
    MedicalCatalogEntryModel entry,
  );

  Future<Either<Failures, bool>> deleteEntry(String id);

  Future<Either<Failures, MedicalCatalogEntryModel>> toggleActive({
    required String id,
    required bool isActive,
  });
}
