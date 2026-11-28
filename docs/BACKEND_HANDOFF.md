# Eyadty Backend Hand-off Guide

Contract source of truth: [`EYADTY_BACKEND_SCHEMA.json`](../EYADTY_BACKEND_SCHEMA.json)
Generated OpenAPI 3.0 spec: [`docs/openapi.json`](openapi.json)
Regenerate schema + OpenAPI: `dart run tools/regenerate_backend_schema.dart`

---

## 1. Authentication & Token Refresh
- **Login**: `POST /api/v1/admin/auth/login` -> returns `{ data: { accessToken, refreshToken, user } }`.
- **Headers**: Every authenticated request sends `Authorization: Bearer <accessToken>` and `Accept-Language: ar|en`.
- **401 Refresh**: On `401`, `AppInterceptors` calls `POST /api/v1/admin/auth/refresh` with `{ "refreshToken": "..." }` **once**, updates stored tokens, and retries the original request. On a second `401` (or expired refresh token), the user is logged out and redirected to `/login`.

## 2. Idempotency
- Every mutation sends `Idempotency-Key: <operationId>` (UUID).
- Replaying the same `Idempotency-Key` with the same payload must return the original stored result without creating duplicates.
- Replaying the same key with a different payload returns `409 IDEMPOTENCY_CONFLICT`.

## 3. Revision & Conflict Rules
- Mutable entities carry integer `revision`.
- Updates send `baseRevision`.
- If `baseRevision < currentRevision`, return `409 CONFLICT` with `serverVersion` so the client creates a `ConflictRecord` preserving both versions.

## 4. Immutability Rules (Append-Only)
- **Finalized Visits**: Direct `PUT /visits/{id}/draft` after `finalized` returns `409`. Corrections use `POST /visits/{id}/addenda`.
- **Financials (Payments, Cashier Movements, Settlements, Ledger)**: Never overwritten or deleted. Corrections use `POST /cashier/payments/{id}/refund`, `POST /cashier/payments/{id}/void`, or `POST /hr/ledger/{id}/reverse` (new counter-entry).

## 5. Sync Contract (`/sync/push` & `/sync/pull`)
### Push Request (`POST /api/v1/sync/push`)
```json
{
  "operations": [
    {
      "operationId": "stub_op_pat_1",
      "entityType": "patient",
      "localId": "PAT-DEP-1",
      "operation": "create",
      "payload": { "id": "PAT-DEP-1", "name": "Dependent Parent" },
      "baseRevision": 1,
      "dependencyRefs": []
    },
    {
      "operationId": "stub_op_bok_1",
      "entityType": "booking",
      "localId": "BOK-DEP-1",
      "operation": "create",
      "payload": { "id": "BOK-DEP-1", "patientId": "PAT-DEP-1" },
      "baseRevision": 1,
      "dependencyRefs": ["patient:PAT-DEP-1"]
    }
  ]
}
```
### Push Response
```json
{
  "data": {
    "results": [
      {
        "operationId": "stub_op_pat_1",
        "success": true,
        "serverId": "SRV-PAT-DEP-1",
        "serverCursor": "cursor_1",
        "confirmedRevision": 2,
        "hasConflict": false,
        "isRetryable": true
      }
    ]
  }
}
```
### Pull Response (`GET /api/v1/sync/pull?entityType=patient&cursor=cursor_1`)
```json
{
  "data": {
    "newCursor": "cursor_2",
    "changes": [
      {
        "serverId": "SRV-PAT-DEP-1",
        "localId": "PAT-DEP-1",
        "entityType": "patient",
        "revision": 3,
        "isDeleted": true,
        "payload": { "id": "PAT-DEP-1" }
      }
    ]
  }
}
```

## 6. Standard Error Envelope & Codes
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "patient_name_required",
    "fields": { "name": "patient_name_required" }
  }
}
```
Key error codes: `UNAUTHORIZED` (401), `PERMISSION_DENIED` (403), `NOT_FOUND` (404), `CONFLICT` / `SLOT_CONFLICT` / `IDEMPOTENCY_CONFLICT` / `ACTIVE_BOOKINGS_EXIST` (409), `VALIDATION_ERROR` / `DUPLICATE_PHONE` / `INVALID_DATE_RANGE` (422), `USER_INACTIVE` / `MUST_CHANGE_PASSWORD` / `PRIVILEGE_ESCALATION` (403).

## 7. Assumed Endpoint Paths & Where to Rename
- Auth/upload constants live in [`lib/core/api/end_points.dart`](../lib/core/api/end_points.dart).
- Feature-specific assumed paths (such as `patients`, `doctors`, `bookings`, `visits`, `cashier/*`, `hr/*`, `drugs`, `branches`, `settings`, `medical-catalogs`, `inventory`, `audit-logs`, `analytics/*`, `staff-users`, `notifications/*`, `sync/*`) are called directly by their respective `*_repo_impl.dart` classes under `lib/features/*/data/repo/` and [`lib/core/offline/remote/http_remote_sync_api.dart`](../lib/core/offline/remote/http_remote_sync_api.dart), and can be remapped on the server or updated in those repository files if the backend renames any route.
