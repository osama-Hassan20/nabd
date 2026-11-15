import 'dart:convert';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../settings/data/models/company_settings_model.dart';
import '../../../settings/data/models/enums/print_format_enum.dart';
import '../../data/models/visit_model.dart';
import '../../presentation/helpers/effective_prescription_calculator.dart';
import '../../presentation/helpers/prescription_pdf_generator.dart';

class PrintPrescriptionParams {
  final VisitModel visit;
  final PatientModel? patient;
  final CompanySettingsModel? settings;
  final PrintFormat? format;
  final ByteData? fontData;

  const PrintPrescriptionParams({
    required this.visit,
    this.patient,
    this.settings,
    this.format,
    this.fontData,
  });
}

class PrintPrescriptionUseCase
    implements UseCase<Uint8List, PrintPrescriptionParams> {
  final PermissionEvaluator permissionEvaluator;
  final CurrentUserProvider userProvider;
  final AuditLogger? auditLogger;

  PrintPrescriptionUseCase({
    required this.permissionEvaluator,
    required this.userProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, Uint8List>> call(
    PrintPrescriptionParams params,
  ) async {
    final visit = params.visit;
    final user = userProvider.currentUser;
    final branchId = userProvider.activeBranchId ?? visit.branchId;

    // 1. Permission check: StaffPermissionEnum.issuePrescription
    final hasPermission = permissionEvaluator.can(
      StaffPermissionEnum.issuePrescription,
      branchId: branchId,
      patientDoctorIds:
          visit.doctorId != null ? {visit.doctorId!} : null,
    );

    if (!hasPermission) {
      return const Left(
        PermissionDeniedFailure(
          errMessage: 'permission_denied_issue_prescription',
        ),
      );
    }

    // 2. Doctor matching check: user must be the attending doctor for the visit
    if (user?.linkedDoctorId == null ||
        user!.linkedDoctorId != visit.doctorId) {
      return const Left(
        PermissionDeniedFailure(
          errMessage: 'unauthorized_not_attending_doctor',
        ),
      );
    }

    // 3. Compute effective items and amended status
    final effectiveItems =
        EffectivePrescriptionCalculator.calculateEffectivePrescription(
      visit: visit,
    );

    final isAmended =
        EffectivePrescriptionCalculator.isVisitAmended(visit: visit);
    final format = params.format ??
        params.settings?.effectivePrescriptionPrintFormat ??
        PrintFormat.a4;

    // 4. Generate PDF bytes
    try {
      final pdfBytes = await PrescriptionPdfGenerator.generate(
        visit: visit,
        patient: params.patient,
        effectiveItems: effectiveItems,
        settings: params.settings,
        format: format,
        fontData: params.fontData,
      );

      // 5. Log security audit event: strictly whitelist (IDs, counts, enums only, 0 clinical text)
      if (auditLogger != null) {
        auditLogger!.log(
          eventType: 'prescription_printed',
          performedByUserId: user.id,
          branchId: branchId,
          details: jsonEncode({
            'visitId': visit.id,
            'doctorId': visit.doctorId,
            'itemsCount': effectiveItems.length,
            'format': format.name,
            'isAmended': isAmended,
          }),
        );
      }

      return Right(pdfBytes);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
