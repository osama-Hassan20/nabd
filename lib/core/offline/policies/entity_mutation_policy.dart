import '../models/sync_status.dart';

abstract class EntityMutationPolicy {
  /// Whether an existing record can be overwritten in place by an update.
  bool canOverwriteInPlace(Map<String, dynamic> existing, Map<String, dynamic> incoming);

  /// Whether an existing record can be deleted.
  bool canDelete(Map<String, dynamic> existing);

  /// The outbox operation type emitted for deletions/reversals.
  OutboxOperationType get deleteOperationType;
}

/// Ordinary editable records: updates increment revision; deletions land as tombstones.
class PatientMutationPolicy implements EntityMutationPolicy {
  const PatientMutationPolicy();

  @override
  bool canOverwriteInPlace(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) =>
      true;

  @override
  bool canDelete(Map<String, dynamic> existing) => true;

  @override
  OutboxOperationType get deleteOperationType => OutboxOperationType.delete;
}

/// Appointments / Bookings: editable, status updates track lifecycle.
class BookingMutationPolicy implements EntityMutationPolicy {
  const BookingMutationPolicy();

  @override
  bool canOverwriteInPlace(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) =>
      true;

  @override
  bool canDelete(Map<String, dynamic> existing) => true;

  @override
  OutboxOperationType get deleteOperationType => OutboxOperationType.delete;
}

/// Signed or finalized clinical records: append new version or addendum; never overwrite or drop.
class ClinicalRecordMutationPolicy implements EntityMutationPolicy {
  const ClinicalRecordMutationPolicy();

  @override
  bool canOverwriteInPlace(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    final isFinalized =
        existing['isFinalized'] == true || existing['status'] == 'completed';
    // Finalized notes must never be overwritten in-place
    return !isFinalized;
  }

  @override
  bool canDelete(Map<String, dynamic> existing) {
    final isFinalized =
        existing['isFinalized'] == true || existing['status'] == 'completed';
    return !isFinalized;
  }

  @override
  OutboxOperationType get deleteOperationType => OutboxOperationType.delete;
}

/// Posted financial entries (payments, settlements): append-only; corrections as reversals.
class FinancialEntryPolicy implements EntityMutationPolicy {
  const FinancialEntryPolicy();

  @override
  bool canOverwriteInPlace(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    // Posted payments are immutable; never edited in place
    return false;
  }

  @override
  bool canDelete(Map<String, dynamic> existing) {
    // Payments cannot be deleted; reversal adjustment required
    return false;
  }

  @override
  OutboxOperationType get deleteOperationType =>
      OutboxOperationType.reverseFinancial;
}
