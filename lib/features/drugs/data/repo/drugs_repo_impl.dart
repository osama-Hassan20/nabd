import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../domain/repo/drugs_repo.dart';
import '../models/drug_category_model.dart';
import '../models/drug_model.dart';
import '../models/enums/review_status_enum.dart';
import '../models/prescription_template_model.dart';

class DrugsRepoImpl implements DrugsRepo {
  final ApiConsumer? _apiConsumer;

  DrugsRepoImpl({ApiConsumer? apiConsumer}) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failures, List<DrugModel>>> getDrugs({
    String? query,
    String? categoryId,
    String? reviewFilter,
    bool includeArchived = false,
  }) async {
    try {
      final res = await _api.get(
        path: 'drugs',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
          if (reviewFilter != null && reviewFilter.isNotEmpty) 'reviewFilter': reviewFilter,
          if (includeArchived) 'includeArchived': true,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list.map((e) => DrugModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<DrugCategoryModel>>> getCategories() async {
    try {
      final res = await _api.get(path: 'drug-categories');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list.map((e) => DrugCategoryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DrugModel>> addDrug(DrugModel drug) async {
    try {
      final res = await _api.post(
        path: 'drugs',
        body: drug.toJson(),
        options: IdempotencyHelper.options(drug.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(DrugModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DrugModel>> updateDrug(DrugModel drug) async {
    try {
      final res = await _api.put(
        path: 'drugs/${drug.id}',
        body: drug.toJson(),
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(DrugModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> archiveDrug(String drugId) async {
    try {
      await _api.post(
        path: 'drugs/$drugId/archive',
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DrugModel>> quickAddDrug({
    required String name,
    required String visitId,
    required String doctorId,
    String? concentration,
    String? dosage,
    String? frequency,
    String? duration,
  }) async {
    try {
      final res = await _api.post(
        path: 'drugs/quick-add',
        body: {
          'name': name,
          'visitId': visitId,
          'doctorId': doctorId,
          if (concentration != null) 'concentration': concentration,
          if (dosage != null) 'dosage': dosage,
          if (frequency != null) 'frequency': frequency,
          if (duration != null) 'duration': duration,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(DrugModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DrugModel>> reviewQuickAddDrug({
    required String drugId,
    required ReviewStatusEnum decision,
    required String reviewedByUserId,
    String? mergeTargetDrugId,
  }) async {
    try {
      final res = await _api.post(
        path: 'drugs/$drugId/review',
        body: {
          'decision': decision.name,
          'reviewedByUserId': reviewedByUserId,
          if (mergeTargetDrugId != null) 'mergeTargetDrugId': mergeTargetDrugId,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(DrugModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> updateAllergyAliases({
    required String catalogItemId,
    required List<String> aliases,
  }) async {
    try {
      await _api.put(
        path: 'drugs/allergy-aliases',
        body: {'catalogItemId': catalogItemId, 'aliases': aliases},
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Map<String, List<String>>>> getAllergyAliases() async {
    try {
      final res = await _api.get(path: 'drugs/allergy-aliases');
      final data = res is Map ? (res['data'] ?? res) : res;
      final out = <String, List<String>>{};
      if (data is Map) {
        data.forEach((k, v) {
          out[k.toString()] =
              (v as List?)?.map((e) => e.toString()).toList() ?? const [];
        });
      }
      return Right(out);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<PrescriptionTemplateModel>>> getDoctorTemplates(
    String doctorId,
  ) async {
    try {
      final res = await _api.get(path: 'doctors/$doctorId/prescription-templates');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map(
              (e) => PrescriptionTemplateModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PrescriptionTemplateModel>> savePrescriptionTemplate(
    PrescriptionTemplateModel template,
  ) async {
    try {
      final id = template.id ?? 'TPL-${DateTime.now().millisecondsSinceEpoch}';
      final res = await _api.put(
        path: 'prescription-templates/$id',
        body: template.copyWith(id: id).toJson(),
        options: IdempotencyHelper.options(id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        PrescriptionTemplateModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> deletePrescriptionTemplate(
    String templateId,
    String doctorId,
  ) async {
    try {
      await _api.delete(
        path: 'prescription-templates/$templateId',
        body: {'doctorId': doctorId},
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, int>> importDrugsBatch(List<DrugModel> drugs) async {
    try {
      final res = await _api.post(
        path: 'drugs/import',
        body: {'drugs': drugs.map((d) => d.toJson()).toList()},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final count = data is Map ? (data['importedCount'] as num?)?.toInt() : null;
      return Right(count ?? drugs.length);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}
