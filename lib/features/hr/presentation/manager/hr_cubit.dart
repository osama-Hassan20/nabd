import '../../../../core/base/safe_cubit.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../users_management/data/models/staff_user_model.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/enums/employee_type_enum.dart';
import '../../data/models/enums/ledger_entry_type_enum.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../../domain/helpers/doctor_settlement_calculator.dart';
import '../../domain/repo/hr_repo.dart';
import '../../domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import '../../domain/use_cases/confirm_doctor_settlement_use_case.dart';
import '../../domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import '../../domain/use_cases/generate_staff_payroll_period_use_case.dart';
import '../../domain/use_cases/get_active_rule_for_doctor_use_case.dart';
import '../../domain/use_cases/get_doctor_compensation_rules_use_case.dart';
import '../../domain/use_cases/payout_doctor_settlement_use_case.dart';
import '../../domain/use_cases/payout_staff_payroll_period_use_case.dart';
import '../../domain/use_cases/save_doctor_compensation_rule_use_case.dart';
import '../../domain/use_cases/save_staff_payroll_profile_use_case.dart';
import 'hr_state.dart';
import 'hr_tab_enum.dart';

class HrCubit extends SafeCubit<HrState> {
  final HrRepo hrRepo;
  final GetDoctorCompensationRulesUseCase getDoctorCompensationRulesUseCase;
  final SaveDoctorCompensationRuleUseCase saveDoctorCompensationRuleUseCase;
  final GetActiveRuleForDoctorUseCase getActiveRuleForDoctorUseCase;
  final CalculateDoctorSettlementDraftUseCase calculateDoctorSettlementDraftUseCase;
  final ConfirmDoctorSettlementUseCase confirmDoctorSettlementUseCase;
  final PayoutDoctorSettlementUseCase payoutDoctorSettlementUseCase;
  final GenerateStaffPayrollPeriodUseCase generateStaffPayrollPeriodUseCase;
  final SaveStaffPayrollProfileUseCase saveStaffPayrollProfileUseCase;
  final ConfirmStaffPayrollPeriodUseCase confirmStaffPayrollPeriodUseCase;
  final PayoutStaffPayrollPeriodUseCase payoutStaffPayrollPeriodUseCase;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  HrCubit({
    required this.hrRepo,
    required this.getDoctorCompensationRulesUseCase,
    required this.saveDoctorCompensationRuleUseCase,
    required this.getActiveRuleForDoctorUseCase,
    required this.calculateDoctorSettlementDraftUseCase,
    required this.confirmDoctorSettlementUseCase,
    required this.payoutDoctorSettlementUseCase,
    required this.generateStaffPayrollPeriodUseCase,
    required this.saveStaffPayrollProfileUseCase,
    required this.confirmStaffPayrollPeriodUseCase,
    required this.payoutStaffPayrollPeriodUseCase,
    this.permissionEvaluator,
    this.currentUserProvider,
  }) : super(const HrState());

  /// Initializes HR state for active branch and current user.
  Future<void> init({
    required String branchId,
    required StaffUserModel user,
  }) async {
    emit(state.copyWith(
      status: RequestStatusEnum.loading,
      currentBranchId: branchId,
      currentUserId: user.id,
      currentUser: user,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    await Future.wait([
      loadSettlements(),
      loadCompensationRules(),
      loadPayrollData(),
    ]);

    emit(state.copyWith(status: RequestStatusEnum.success));
  }

  /// Automatically clears all state upon branch switch or logout.
  void reset() {
    emit(const HrState());
  }

  /// Handles branch or user switch reactively.
  Future<void> onBranchOrUserChanged({
    required String newBranchId,
    required StaffUserModel newUser,
  }) async {
    reset();
    await init(branchId: newBranchId, user: newUser);
  }

  /// Switches active tab.
  void switchTab(HrTabEnum tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  /// Sets doctor filter and reloads settlements.
  void setDoctorFilter(String? doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      emit(state.copyWith(clearFilterDoctorId: true));
    } else {
      emit(state.copyWith(filterDoctorId: doctorId));
    }
    loadSettlements();
  }

  /// Sets status filter and reloads settlements.
  void setStatusFilter(SettlementStatusEnum? status) {
    if (status == null) {
      emit(state.copyWith(clearFilterSettlementStatus: true));
    } else {
      emit(state.copyWith(filterSettlementStatus: status));
    }
    loadSettlements();
  }

  /// Sets period date range filters.
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      filterPeriodStart: start,
      filterPeriodEnd: end,
      clearFilterPeriodStart: start == null,
      clearFilterPeriodEnd: end == null,
    ));
    loadSettlements();
  }

  /// Loads doctor settlements taking doctor-isolation into account.
  Future<void> loadSettlements() async {
    final branchId = state.currentBranchId ?? 'branch_1';
    final user = state.currentUser;

    // Doctor user isolation: non-owners with linked doctor profile only see their own settlements
    String? effectiveDoctorId = state.filterDoctorId;
    if (user != null && user.isOwner != true && user.linkedDoctorId != null) {
      effectiveDoctorId = user.linkedDoctorId;
    }

    final result = await hrRepo.getDoctorSettlements(
      doctorId: effectiveDoctorId,
      branchId: branchId,
      status: state.filterSettlementStatus,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.errMessage)),
      (settlements) {
        var filtered = settlements;
        if (state.filterPeriodStart != null && state.filterPeriodEnd != null) {
          filtered = filtered.where((s) {
            if (s.periodStart == null || s.periodEnd == null) return false;
            return !s.periodStart!.isBefore(state.filterPeriodStart!) &&
                !s.periodEnd!.isAfter(state.filterPeriodEnd!);
          }).toList();
        }
        emit(state.copyWith(settlements: filtered));
      },
    );
  }

  /// Loads compensation rules for current branch.
  Future<void> loadCompensationRules() async {
    final branchId = state.currentBranchId ?? 'branch_1';
    final user = state.currentUser;

    String? doctorId;
    if (user != null && user.isOwner != true && user.linkedDoctorId != null) {
      doctorId = user.linkedDoctorId;
    }

    final result = await getDoctorCompensationRulesUseCase(
      doctorId: doctorId,
      branchId: branchId,
    );

    result.fold(
      (failure) => null, // Fail-closed or quiet
      (rules) => emit(state.copyWith(compensationRules: rules)),
    );
  }

  /// Loads staff payroll periods and profiles if authorized.
  Future<void> loadPayrollData() async {
    final branchId = state.currentBranchId ?? 'branch_1';

    // Fail-closed authorization check for staff payroll data
    if (permissionEvaluator != null) {
      final canManagePayroll = permissionEvaluator!.can(
        StaffPermissionEnum.manageStaffPayroll,
        branchId: branchId,
      );
      if (!canManagePayroll) {
        emit(state.copyWith(
          payrollPeriods: const [],
          staffProfiles: const [],
        ));
        return;
      }
    }

    final periodsRes = await hrRepo.getStaffPayrollPeriods(primaryBranchId: branchId);
    final profilesRes = await hrRepo.getStaffPayrollProfiles(primaryBranchId: branchId);

    emit(state.copyWith(
      payrollPeriods: periodsRes.getOrElse(() => []),
      staffProfiles: profilesRes.getOrElse(() => []),
    ));
  }

  /// Loads ledger entries and calculates outstanding balance for selected employee.
  Future<void> loadEmployeeLedger(String employeeId) async {
    final branchId = state.currentBranchId ?? 'branch_1';

    final result = await hrRepo.getEmployeeLedgerEntries(
      employeeId: employeeId,
      branchId: branchId,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.errMessage)),
      (entries) {
        final outstanding = DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(entries);
        emit(state.copyWith(
          selectedEmployeeId: employeeId,
          ledgerEntries: entries,
          outstandingAdvancesPiastres: outstanding,
        ));
      },
    );
  }

  /// Adds an advance or deduction to ledger and reloads employee ledger reactively.
  Future<bool> addAdvance({
    required String employeeId,
    required EmployeeTypeEnum employeeType,
    required int amountPiastres,
    required String reason,
    String? clientRequestId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final branchId = state.currentBranchId ?? 'branch_1';
    final user = state.currentUser;

    final entry = EmployeeLedgerEntryModel(
      employeeId: employeeId,
      employeeType: employeeType,
      branchId: branchId,
      entryType: LedgerEntryTypeEnum.advance,
      amountPiastres: amountPiastres,
      reason: reason,
      date: CairoTimeHelper.now(),
      performedByUserId: user?.id,
      clientRequestId: clientRequestId,
    );

    final result = await hrRepo.addEmployeeLedgerEntry(entry);
    emit(state.copyWith(isSubmitting: false));

    if (result.isRight()) {
      await loadEmployeeLedger(employeeId);
      return true;
    } else {
      final err = result.fold((f) => f.errMessage, (r) => null);
      emit(state.copyWith(errorMessage: err));
      return false;
    }
  }

  /// Reverses a ledger entry and updates active balance.
  Future<bool> reverseLedgerEntry({
    required String entryId,
    required String reason,
    required String employeeId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final user = state.currentUser;
    final result = await hrRepo.reverseEmployeeLedgerEntry(
      entryId: entryId,
      reason: reason,
      performedByUserId: user?.id ?? 'unknown',
    );

    emit(state.copyWith(isSubmitting: false));

    if (result.isRight()) {
      await loadEmployeeLedger(employeeId);
      return true;
    } else {
      final err = result.fold((f) => f.errMessage, (r) => null);
      emit(state.copyWith(errorMessage: err));
      return false;
    }
  }

  /// Calculates a draft doctor settlement and updates draft in state.
  Future<bool> calculateDraftSettlement({
    required String doctorId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? doctorName,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final branchId = state.currentBranchId ?? 'branch_1';
    final result = await calculateDoctorSettlementDraftUseCase(
      doctorId: doctorId,
      branchId: branchId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      doctorName: doctorName,
    );

    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (draft) {
        emit(state.copyWith(
          draftSettlement: draft,
          settlements: [draft, ...state.settlements.where((s) => s.id != draft.id)],
        ));
        return true;
      },
    );
  }

  /// Confirms a doctor settlement and updates state reactively.
  Future<bool> confirmSettlement(String settlementId) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await confirmDoctorSettlementUseCase(settlementId: settlementId);
    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (confirmed) {
        final updatedList = state.settlements.map((s) {
          return s.id == confirmed.id ? confirmed : s;
        }).toList();

        emit(state.copyWith(
          settlements: updatedList,
          selectedSettlement: confirmed,
          clearDraftSettlement: state.draftSettlement?.id == confirmed.id,
        ));
        return true;
      },
    );
  }

  /// Pays out a doctor settlement and refreshes ledger entries reactively.
  Future<bool> payoutSettlement({
    required String settlementId,
    required PaymentMethod method,
    String? refNumber,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await payoutDoctorSettlementUseCase(
      settlementId: settlementId,
      paymentMethod: method,
      paymentReferenceNumber: refNumber,
    );

    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (paid) {
        final updatedList = state.settlements.map((s) {
          return s.id == paid.id ? paid : s;
        }).toList();

        emit(state.copyWith(
          settlements: updatedList,
          selectedSettlement: paid,
        ));

        if (paid.doctorId != null && paid.doctorId == state.selectedEmployeeId) {
          loadEmployeeLedger(paid.doctorId!);
        }
        return true;
      },
    );
  }

  /// Saves doctor compensation rule and refreshes active rules.
  Future<bool> saveCompensationRule(DoctorCompensationRuleModel rule) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await saveDoctorCompensationRuleUseCase(rule);
    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (saved) {
        loadCompensationRules();
        return true;
      },
    );
  }

  /// Generates a staff payroll period for target branch, month, and year.
  Future<bool> generateStaffPayrollPeriod({
    required int month,
    required int year,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final branchId = state.currentBranchId ?? 'branch_1';
    final result = await generateStaffPayrollPeriodUseCase(
      primaryBranchId: branchId,
      month: month,
      year: year,
    );

    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (period) {
        emit(state.copyWith(
          payrollPeriods: [period, ...state.payrollPeriods.where((p) => p.id != period.id)],
          selectedPayrollPeriod: period,
        ));
        return true;
      },
    );
  }

  /// Confirms a staff payroll period and updates status in state.
  Future<bool> confirmStaffPayrollPeriod(String periodId) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await confirmStaffPayrollPeriodUseCase(periodId: periodId);
    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (confirmed) {
        final updatedList = state.payrollPeriods.map((p) {
          return p.id == confirmed.id ? confirmed : p;
        }).toList();

        emit(state.copyWith(
          payrollPeriods: updatedList,
          selectedPayrollPeriod: confirmed,
        ));
        return true;
      },
    );
  }

  /// Pays out a staff payroll period and refreshes ledger entries.
  Future<bool> payoutStaffPayrollPeriod(String periodId) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await payoutStaffPayrollPeriodUseCase(periodId: periodId);
    emit(state.copyWith(isSubmitting: false));

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (paid) {
        final updatedList = state.payrollPeriods.map((p) {
          return p.id == paid.id ? paid : p;
        }).toList();

        emit(state.copyWith(
          payrollPeriods: updatedList,
          selectedPayrollPeriod: paid,
        ));

        if (state.selectedEmployeeId != null) {
          loadEmployeeLedger(state.selectedEmployeeId!);
        }
        return true;
      },
    );
  }
}
