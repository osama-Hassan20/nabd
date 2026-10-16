import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/models/media_model.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import 'package:eyadty/shared/uploads/domain/repo/files_upload_repo.dart';
import 'package:dartz/dartz.dart';

/// Parameters for uploading multiple files
class UploadMultipleFilesParams {
  final List<MediaModel> files;
  final int maxWidth;
  final int quality;

  UploadMultipleFilesParams({
    required this.files,
    this.maxWidth = 1024,
    this.quality = 60,
  });
}

class UploadMultipleFilesUseCase
    implements UseCase<List<MediaModel>, UploadMultipleFilesParams> {
  final FileUploadRepo fileUploadRepo;

  UploadMultipleFilesUseCase({required this.fileUploadRepo});

  @override
  Future<Either<Failures, List<MediaModel>>> call(
    UploadMultipleFilesParams params,
  ) async {
    return await fileUploadRepo.uploadMultipleFiles(
      params.files,
      maxWidth: params.maxWidth,
      quality: params.quality,
    );
  }
}

