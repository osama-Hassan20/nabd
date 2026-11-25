enum SyncStatus {
  synced,
  pending,
  failed,
  conflict,
  blocked,
}

enum OutboxStatus {
  pending,
  inFlight,
  acknowledged,
  failed,
  blocked,
}

enum OutboxOperationType {
  create,
  update,
  delete,
  appendAddendum,
  reverseFinancial,
}
