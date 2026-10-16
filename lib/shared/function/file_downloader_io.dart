import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFilePlatform(String url, String fileName) async {
  try {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      final filePath = '${directory.path}/$fileName';
      await Dio().download(url, filePath);
    }
  } catch (e) {
    // Silent fallback
  }
}
