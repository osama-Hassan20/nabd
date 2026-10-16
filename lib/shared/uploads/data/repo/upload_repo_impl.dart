import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/shared/uploads/data/data_source/file_upload_data_source.dart';
import 'package:eyadty/shared/uploads/domain/repo/files_upload_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class FileUploadRepoImpl implements FileUploadRepo {
  final FileUploadDataSource dataSource;

  FileUploadRepoImpl({required this.dataSource});

  @override
  Future<Either<Failures, MediaModel>> uploadFile(
    MediaModel file, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final result = await dataSource.uploadFile(
        file,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (!result.success) {
        return Left(
          ServerFailure(errMessage: result.errorMessage ?? 'Upload failed'),
        );
      }

      // Convert the upload result to a network MediaTypeModel
      return Right(
        MediaModel(
          type: MediaSourceType.network,
          path: result.url!,
          category: file.category,
          fileName: result.fileName ?? file.fileName,
        ),
      );
    } catch (e) {
      if (e is DioException) {
        return Left(ServerFailure.fromDioException(dioException: e));
      } else {
        return Left(ServerFailure(errMessage: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failures, List<MediaModel>>> uploadMultipleFiles(
    List<MediaModel> files, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final result = await dataSource.uploadMultipleFiles(
        files,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (!result.allSuccess) {
        return Left(
          ServerFailure(
            errMessage: 'Some files failed to upload: ${result.failureCount}',
          ),
        );
      }

      // Convert all results to network MediaTypeModels
      final networkModels = result.results.asMap().entries.map((entry) {
        final uploadResult = entry.value;
        final originalModel = files[entry.key];
        return MediaModel(
          type: MediaSourceType.network,
          path: uploadResult.url!,
          category: originalModel.category,
          fileName: uploadResult.fileName ?? originalModel.fileName,
        );
      }).toList();

      return Right(networkModels);
    } catch (e) {
      if (e is DioException) {
        return Left(ServerFailure.fromDioException(dioException: e));
      } else {
        return Left(ServerFailure(errMessage: e.toString()));
      }
    }
  }
}

