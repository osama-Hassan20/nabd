import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';

/// Local-mode implementation of [RemoteSyncApi].
///
/// Registered only when `BACKEND_MODE=local`.
class LocalServerSyncApi extends FakeRemoteSyncApi {
  LocalServerSyncApi();
}
