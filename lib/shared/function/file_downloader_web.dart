// import 'dart:html' as html;
// import 'package:dio/dio.dart';

// Future<void> downloadFilePlatform(String url, String fileName) async {
//   try {
//     final response = await Dio().get<List<int>>(
//       url,
//       options: Options(responseType: ResponseType.bytes),
//     );
//     final bytes = response.data;
//     if (bytes != null) {
//       final blob = html.Blob([bytes]);
//       final blobUrl = html.Url.createObjectUrlFromBlob(blob);
//       final anchor = html.AnchorElement(href: blobUrl)
//         ..setAttribute("download", fileName)
//         ..style.display = 'none';
//       html.document.body?.children.add(anchor);
//       anchor.click();
//       anchor.remove();
//       html.Url.revokeObjectUrl(blobUrl);
//     }
//   } catch (e) {
//     // Fallback: click simple link with target="_blank"
//     final anchor = html.AnchorElement(href: url)
//       ..setAttribute("download", fileName)
//       ..setAttribute("target", "_blank")
//       ..style.display = 'none';
//     html.document.body?.children.add(anchor);
//     anchor.click();
//     anchor.remove();
//   }
// }
