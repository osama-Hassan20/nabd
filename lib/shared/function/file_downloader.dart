import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';

Future<void> downloadFile(String url, String fileName) =>
    downloadFilePlatform(url, fileName);
