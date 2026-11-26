import 'package:flutter/material.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

abstract class SpecialtyRecordModule {
  MedicalSpecialty get specialty;
  String get tabLabelKey;

  Widget buildPatientTab(PatientModel patient);
  Widget buildVisitSection(VisitModel visit);

  Map<String, dynamic> emptyEntry();
  List<String> validate(Map<String, dynamic> entry);
}
