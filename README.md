# Eyadty Clinic SaaS

## Backend modes

Eyadty supports two backend modes controlled by a single compile-time/runtime switch (`BACKEND_MODE`):

### 1. Local mode (`BACKEND_MODE=local`, default)
- **Usage**:
  ```bash
  flutter run
  # or explicitly:
  flutter run --dart-define=BACKEND_MODE=local
  ```
- **How it works**: Data comes from the in-process local server simulation (`lib/core/local_server/`), backed by `LocalServerApiConsumer` and `LocalServerSyncApi` with seeded clinic fixtures (`LocalServerSeeds`) persisted locally.
- **Offline-first layer**: Repositories in `lib/core/offline/repositories/` (`OfflineFirst*Repo`) remain the only layer cubits interact with; they wrap the underlying remote/local repository and queue mutations in the outbox for `SyncEngine`.

### 2. Remote mode (`BACKEND_MODE=remote`)
- **Usage**:
  ```bash
  flutter run --dart-define=BACKEND_MODE=remote --dart-define=BASE_URL=https://api.example.com/
  ```
- **How it works**: `ApiConsumer` resolves to `DioConsumer` (with `AppInterceptors` handling Bearer JWT injection and 401 token refresh), and `RemoteSyncApi` resolves to `HttpRemoteSyncApi` calling `/sync/push` and `/sync/pull`.
- **Contract**: All assumed endpoints, envelopes, idempotency (`Idempotency-Key`), revision conflicts (`409` + `serverVersion`), and sync contracts are documented in `EYADTY_BACKEND_SCHEMA.json`.

### Testing against the local stub HTTP server
A standalone Dart `HttpServer` stub lives at `test/tools/stub_backend_server.dart`, and `test/core/remote_mode_stub_server_test.dart` exercises `BACKEND_MODE=remote` (`DioConsumer` + `AppInterceptors` + `HttpRemoteSyncApi`) against it for Bearer auth, `Idempotency-Key`, pagination, 401 refresh, 409 conflict, 422 validation, timeout retry, and airplane mode (offline queue).
