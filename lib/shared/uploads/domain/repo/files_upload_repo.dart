import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/models/media_model.dart';
import 'package:dartz/dartz.dart';

abstract class FileUploadRepo {
  /// Upload a single file to server and returns a MediaTypeModel with network type
  Future<Either<Failures, MediaModel>> uploadFile(
    MediaModel file, {
    int maxWidth = 1920,
    int quality = 85,
  });

  /// Upload multiple files to server and returns a list of MediaTypeModels with network type
  Future<Either<Failures, List<MediaModel>>> uploadMultipleFiles(
    List<MediaModel> files, {
    int maxWidth = 1920,
    int quality = 85,
  });
}

