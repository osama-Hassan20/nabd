import 'package:dio/dio.dart';

class IdempotencyHelper {
  IdempotencyHelper._();

  static int _seq = 0;

  static String nextKey([String? explicit]) {
    if (explicit != null && explicit.isNotEmpty) return explicit;
    _seq++;
    return 'op_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  static Options options([String? explicit]) =>
      Options(headers: {'Idempotency-Key': nextKey(explicit)});
}
