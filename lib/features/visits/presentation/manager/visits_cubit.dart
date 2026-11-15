import 'dart:async';
import '../../../../core/base/safe_cubit.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../../patients/domain/repo/patients_repo.dart';
import '../../domain/repo/visits_repo.dart';
import '../../domain/use_cases/add_visit_addendum_use_case.dart';
import '../../domain/use_cases/finalize_visit_use_case.dart';
import '../../domain/use_cases/get_doctor_queue_use_case.dart';
import '../../domain/use_cases/get_visit_by_booking_id_use_case.dart';
import '../../domain/use_cases/record_vitals_use_case.dart';
import '../../domain/use_cases/save_visit_draft_use_case.dart';
import '../../domain/use_cases/start_consultation_use_case.dart';
import 'mixins/visit_consultation_mixin.dart';
import 'mixins/visit_prescription_mixin.dart';
import 'mixins/visit_queue_mixin.dart';
import 'mixins/visit_vitals_mixin.dart';
import 'visits_state.dart';

class VisitsCubit extends SafeCubit<VisitsState>
    with
        VisitQueueMixin,
        VisitVitalsMixin,
        VisitConsultationMixin,
        VisitPrescriptionMixin {
  @override
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;
  @override
  final PatientsRepo patientsRepo;
  @override
  final GetDoctorQueueUseCase getDoctorQueueUseCase;
  final GetVisitByBookingIdUseCase getVisitByBookingIdUseCase;
  @override
  final StartConsultationUseCase startConsultationUseCase;
  @override
  final SaveVisitDraftUseCase saveVisitDraftUseCase;
  @override
  final RecordVitalsUseCase recordVitalsUseCase;
  @override
  final FinalizeVisitUseCase finalizeVisitUseCase;
  @override
  final AddVisitAddendumUseCase? addVisitAddendumUseCase;
  @override
  final PermissionEvaluator permissionEvaluator;
  @override
  final AuditLogger? auditLogger;
  final SessionCubit? sessionCubit;
  @override
  final Timer Function(Duration duration, void Function() callback)?
      timerFactory;

  StreamSubscription<SessionState>? _sessionSubscription;
  String? _lastUserId;
  String? _lastBranchId;

  VisitsCubit({
    required this.visitsRepo,
    required this.bookingsRepo,
    required this.patientsRepo,
    required this.getDoctorQueueUseCase,
    required this.getVisitByBookingIdUseCase,
    required this.startConsultationUseCase,
    required this.saveVisitDraftUseCase,
    required this.recordVitalsUseCase,
    required this.finalizeVisitUseCase,
    this.addVisitAddendumUseCase,
    required this.permissionEvaluator,
    this.auditLogger,
    this.sessionCubit,
    this.timerFactory,
  }) : super(VisitsState.initial()) {
    _lastUserId = sessionCubit?.currentUser?.id;
    _lastBranchId = sessionCubit?.activeBranchId;

    _sessionSubscription = sessionCubit?.stream.listen((sessionState) {
      final newUser = sessionState.currentUser;
      final newBranch = sessionState.activeBranchId;

      final isLogout = newUser == null;
      final isUserSwitched = newUser?.id != _lastUserId;
      final isBranchSwitched = newBranch != _lastBranchId;

      _lastUserId = newUser?.id;
      _lastBranchId = newBranch;

      if (isLogout || isUserSwitched || isBranchSwitched) {
        // Singleton Security Wipe:
        // Clear all patient clinical data, queue, active visit, and stop timer
        stopAutoSave();
        resetLastAuditedVisitId();
        emit(VisitsState.initial());
      }

      if (!isLogout) {
        refreshPermissions();
      }
    });
  }

  @override
  Future<void> close() {
    stopAutoSave();
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    return super.close();
  }
}
