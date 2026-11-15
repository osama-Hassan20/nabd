import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../users_management/data/models/staff_user_model.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../../data/models/staff_payroll_profile_model.dart';
import 'hr_tab_enum.dart';

class HrState extends Equatable {
  final RequestStatusEnum status;
  final HrTabEnum selectedTab;
  final String? currentBranchId;
  final String? currentUserId;
  final StaffUserModel? currentUser;

  // Doctor Settlements
  final List<DoctorSettlementModel> settlements;
  final DoctorSettlementModel? selectedSettlement;
  final DoctorSettlementModel? draftSettlement;
  final String? filterDoctorId;
  final SettlementStatusEnum? filterSettlementStatus;
  final DateTime? filterPeriodStart;
  final DateTime? filterPeriodEnd;

  // Compensation Rules
  final List<DoctorCompensationRuleModel> compensationRules;
  final DoctorCompensationRuleModel? activeDoctorRule;

  // Staff Payroll
  final List<StaffPayrollPeriodModel> payrollPeriods;
  final StaffPayrollPeriodModel? selectedPayrollPeriod;
  final List<StaffPayrollProfileModel> staffProfiles;
  final int? filterPayrollMonth;
  final int? filterPayrollYear;

  // Employee Ledger & Advances
  final String? selectedEmployeeId;
  final List<EmployeeLedgerEntryModel> ledgerEntries;
  final int outstandingAdvancesPiastres;

  // Operational feedback
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const HrState({
    this.status = RequestStatusEnum.initial,
    this.selectedTab = HrTabEnum.settlements,
    this.currentBranchId,
    this.currentUserId,
    this.currentUser,
    this.settlements = const [],
    this.selectedSettlement,
    this.draftSettlement,
    this.filterDoctorId,
    this.filterSettlementStatus,
    this.filterPeriodStart,
    this.filterPeriodEnd,
    this.compensationRules = const [],
    this.activeDoctorRule,
    this.payrollPeriods = const [],
    this.selectedPayrollPeriod,
    this.staffProfiles = const [],
    this.filterPayrollMonth,
    this.filterPayrollYear,
    this.selectedEmployeeId,
    this.ledgerEntries = const [],
    this.outstandingAdvancesPiastres = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == RequestStatusEnum.loading;

  HrState copyWith({
    RequestStatusEnum? status,
    HrTabEnum? selectedTab,
    String? currentBranchId,
    String? currentUserId,
    StaffUserModel? currentUser,
    List<DoctorSettlementModel>? settlements,
    DoctorSettlementModel? selectedSettlement,
    bool clearSelectedSettlement = false,
    DoctorSettlementModel? draftSettlement,
    bool clearDraftSettlement = false,
    String? filterDoctorId,
    bool clearFilterDoctorId = false,
    SettlementStatusEnum? filterSettlementStatus,
    bool clearFilterSettlementStatus = false,
    DateTime? filterPeriodStart,
    bool clearFilterPeriodStart = false,
    DateTime? filterPeriodEnd,
    bool clearFilterPeriodEnd = false,
    List<DoctorCompensationRuleModel>? compensationRules,
    DoctorCompensationRuleModel? activeDoctorRule,
    bool clearActiveDoctorRule = false,
    List<StaffPayrollPeriodModel>? payrollPeriods,
    StaffPayrollPeriodModel? selectedPayrollPeriod,
    bool clearSelectedPayrollPeriod = false,
    List<StaffPayrollProfileModel>? staffProfiles,
    int? filterPayrollMonth,
    bool clearFilterPayrollMonth = false,
    int? filterPayrollYear,
    bool clearFilterPayrollYear = false,
    String? selectedEmployeeId,
    bool clearSelectedEmployeeId = false,
    List<EmployeeLedgerEntryModel>? ledgerEntries,
    int? outstandingAdvancesPiastres,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return HrState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      currentBranchId: currentBranchId ?? this.currentBranchId,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUser: currentUser ?? this.currentUser,
      settlements: settlements ?? this.settlements,
      selectedSettlement: clearSelectedSettlement ? null : (selectedSettlement ?? this.selectedSettlement),
      draftSettlement: clearDraftSettlement ? null : (draftSettlement ?? this.draftSettlement),
      filterDoctorId: clearFilterDoctorId ? null : (filterDoctorId ?? this.filterDoctorId),
      filterSettlementStatus: clearFilterSettlementStatus ? null : (filterSettlementStatus ?? this.filterSettlementStatus),
      filterPeriodStart: clearFilterPeriodStart ? null : (filterPeriodStart ?? this.filterPeriodStart),
      filterPeriodEnd: clearFilterPeriodEnd ? null : (filterPeriodEnd ?? this.filterPeriodEnd),
      compensationRules: compensationRules ?? this.compensationRules,
      activeDoctorRule: clearActiveDoctorRule ? null : (activeDoctorRule ?? this.activeDoctorRule),
      payrollPeriods: payrollPeriods ?? this.payrollPeriods,
      selectedPayrollPeriod: clearSelectedPayrollPeriod ? null : (selectedPayrollPeriod ?? this.selectedPayrollPeriod),
      staffProfiles: staffProfiles ?? this.staffProfiles,
      filterPayrollMonth: clearFilterPayrollMonth ? null : (filterPayrollMonth ?? this.filterPayrollMonth),
      filterPayrollYear: clearFilterPayrollYear ? null : (filterPayrollYear ?? this.filterPayrollYear),
      selectedEmployeeId: clearSelectedEmployeeId ? null : (selectedEmployeeId ?? this.selectedEmployeeId),
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      outstandingAdvancesPiastres: outstandingAdvancesPiastres ?? this.outstandingAdvancesPiastres,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedTab,
    currentBranchId,
    currentUserId,
    currentUser,
    settlements,
    selectedSettlement,
    draftSettlement,
    filterDoctorId,
    filterSettlementStatus,
    filterPeriodStart,
    filterPeriodEnd,
    compensationRules,
    activeDoctorRule,
    payrollPeriods,
    selectedPayrollPeriod,
    staffProfiles,
    filterPayrollMonth,
    filterPayrollYear,
    selectedEmployeeId,
    ledgerEntries,
    outstandingAdvancesPiastres,
    isSubmitting,
    errorMessage,
    successMessage,
  ];
}
