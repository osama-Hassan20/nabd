import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/local_server/local_server_router.dart';

class AuthLocalHandler {
  AuthLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('POST', 'admin/auth/login', (req) async {
      final identifier = (req.body['email'] ??
              req.body['phone'] ??
              req.body['identifier'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();
      final users = router.db.collection('staffUsers');
      final matched = users.firstWhere(
        (u) =>
            (u['email']?.toString().toLowerCase() == identifier) ||
            (u['phone']?.toString().toLowerCase() == identifier),
        orElse: () => users.isNotEmpty ? users.first : <String, dynamic>{},
      );
      if (matched.isEmpty) {
        LocalServerRouter.throwHttpError(
          req.path,
          401,
          'INVALID_CREDENTIALS',
          'Invalid credentials',
        );
      }
      final userId = (matched['id'] ?? 'USER-OWNER').toString();
      return LocalServerRouter.ok({
        'accessToken': AppConfig.generateDemoToken(userId),
        'refreshToken': 'refresh_$userId',
        'user': matched,
      });
    });

    router.register('POST', 'admin/auth/refresh', (req) async {
      return LocalServerRouter.ok({
        'accessToken': AppConfig.generateDemoToken('USER-OWNER'),
        'refreshToken': 'refresh_USER-OWNER',
      });
    });

    router.register('POST', 'admin/auth/logout', (req) async {
      return LocalServerRouter.ok({'loggedOut': true});
    });

    router.register('GET', 'admin/auth/profile', (req) async {
      final users = router.db.collection('staffUsers');
      final user = users.isNotEmpty ? users.first : <String, dynamic>{};
      return LocalServerRouter.ok(user);
    });

    router.register('POST', 'auth/forget-password', (req) async {
      return LocalServerRouter.ok({'otpSent': true});
    });

    router.register('POST', 'auth/verify', (req) async {
      return LocalServerRouter.ok({'verified': true});
    });

    router.register('POST', 'auth/reset-password', (req) async {
      return LocalServerRouter.ok({'reset': true});
    });

    router.register('PUT', 'users/change-password', (req) async {
      return LocalServerRouter.ok({'changed': true});
    });

    router.register('POST', 'upload/image', (req) async {
      final fileName = (req.body['fileName'] ?? 'upload.png').toString();
      return LocalServerRouter.ok({
        'url': '${AppConfig.baseImageUrl}/$fileName',
        'fileName': fileName,
      });
    });
  }
}
