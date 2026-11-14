abstract class PatientBalanceLookup {
  num calculateOutstandingBalance({
    required String patientId,
    String? fileNumber,
  });

  num calculateTotalPaid({
    required String patientId,
    String? fileNumber,
  });
}

