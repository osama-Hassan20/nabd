import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/models/media_model.dart';
import 'package:purexo/core/uses_cases/use_cases.dart';
import 'package:purexo/shared/uploads/domain/repo/files_upload_repo.dart';
import 'package:dartz/dartz.dart';

class UploadFileParams {
  final MediaModel file;
  final int maxWidth;
  final int quality;

  UploadFileParams({
    required this.file,
    this.maxWidth = 1920,
    this.quality = 85,
  });
}

class UploadFileUseCase implements UseCase<MediaModel, UploadFileParams> {
  final FileUploadRepo fileUploadRepo;

  UploadFileUseCase({required this.fileUploadRepo});

  @override
  Future<Either<Failures, MediaModel>> call(UploadFileParams params) async {
    return await fileUploadRepo.uploadFile(
      params.file,
      maxWidth: params.maxWidth,
      quality: params.quality,
    );
  }
}

