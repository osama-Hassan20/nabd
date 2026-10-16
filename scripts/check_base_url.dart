// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final file = File('lib/core/api/end_points.dart');
  if (!file.existsSync()) {
    print('❌ Error: lib/core/api/end_points.dart not found!');
    exit(1);
  }

  final content = file.readAsStringSync();

  // Regex to extract appBaseUrl value without raw string escaping issues
  final urlPattern = RegExp("appBaseUrl\\s*=\\s*['\"]([^'\"]+)['\"]");
  final match = urlPattern.firstMatch(content);

  if (match == null) {
    print('❌ Error: appBaseUrl not found in lib/core/api/end_points.dart!');
    exit(1);
  }

  final url = match.group(1)!;
  print('🔍 Checking appBaseUrl: $url');

  // Forbidden patterns
  final forbidden = [
    RegExp(r'localhost', caseSensitive: false),
    RegExp(r'127\.0\.0\.1'),
    RegExp(r'192\.168\.'),
    RegExp(r'10\.\d+\.\d+\.\d+'),
    RegExp(r'172\.(1[6-9]|2\d|3[01])\.'),
    RegExp(r'^http://'), // HTTP is not secure for production
  ];

  for (final pattern in forbidden) {
    if (pattern.hasMatch(url)) {
      print('\x1B[31m🚨 BLOCKED: appBaseUrl "$url" looks like a local/dev URL!\x1B[0m');
      print('   Please change it to your secure production URL in lib/core/api/end_points.dart before building release assets.');
      exit(1); // Stop build immediately
    }
  }

  print('\x1B[32m✅ appBaseUrl "$url" is valid and secure for production build!\x1B[0m');
}
