import '../../domain/contracts/doctor_settlement_visits_lookup.dart';

class DoctorSettlementVisitsMockLookup implements DoctorSettlementVisitsLookup {
  final List<SettlementVisitCandidate> _candidates = [];

  DoctorSettlementVisitsMockLookup({List<SettlementVisitCandidate>? initialCandidates}) {
    if (initialCandidates != null) {
      _candidates.addAll(initialCandidates);
    }
  }

  void addCandidate(SettlementVisitCandidate candidate) {
    _candidates.add(candidate);
  }

  void setCandidates(List<SettlementVisitCandidate> candidates) {
    _candidates.clear();
    _candidates.addAll(candidates);
  }

  @override
  Future<List<SettlementVisitCandidate>> getSettlementVisitCandidates({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    List<String> excludedEventIds = const [],
  }) async {
    return _candidates.where((c) {
      if (c.doctorId.isNotEmpty && c.doctorId != doctorId) return false;
      if (c.branchId.isNotEmpty && c.branchId != branchId) return false;
      return true;
    }).toList();
  }
}
