import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/core/offline/repositories/offline_first_bookings_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_drugs_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_visits_repo.dart';
import 'package:eyadty/core/api/app_interceptor.dart';
import 'package:eyadty/core/api/dio_consumer.dart';
import 'package:eyadty/core/api/end_points.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/theme/app_theme_cubit.dart';
import 'package:eyadty/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/notification_service.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/shared/app_layout/data/repositories/layout_repo_impl.dart';
import 'package:eyadty/shared/app_layout/domain/repositories/layout_repo.dart';
import 'package:eyadty/shared/app_layout/domain/use_cases/get_profile_use_case.dart';
import 'package:eyadty/shared/auth/data/repositories/login_repo_impl.dart';
import 'package:eyadty/shared/auth/domain/repositories/login_repo.dart';
import 'package:eyadty/shared/auth/domain/use_cases/login/login_use_case.dart';
import 'package:eyadty/shared/cubit/basic_cubit.dart';

import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/contracts/active_visit_lookup.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_doctor_bookings_for_date_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/users_management/domain/use_cases/save_role_use_case.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';

// Visits Feature
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';
import 'package:eyadty/features/visits/domain/use_cases/add_visit_addendum_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/print_prescription_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';

// Drugs Feature
import 'package:eyadty/features/drugs/data/repo/drugs_mock_repo_impl.dart';
import 'package:eyadty/features/drugs/domain/repo/drugs_repo.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_drugs_catalog_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/archive_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/quick_add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/review_quick_add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_doctor_templates_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/save_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/delete_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_allergy_aliases_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/import_drugs_use_case.dart';
import 'package:eyadty/features/drugs/presentation/manager/drugs_cubit.dart';

// Medical Catalogs Feature
import 'package:eyadty/features/medical_catalogs/data/repo/medical_catalogs_mock_repo_impl.dart';
import 'package:eyadty/features/medical_catalogs/domain/repo/medical_catalogs_repo.dart';
import 'package:eyadty/features/medical_catalogs/presentation/manager/medical_catalogs_cubit.dart';

// Inventory Feature
import 'package:eyadty/features/inventory/data/repo/inventory_mock_repo_impl.dart';
import 'package:eyadty/features/inventory/domain/repo/inventory_repo.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';

// Patients Feature
import 'package:eyadty/features/patients/data/repo/medical_catalog_mock_repo_impl.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/patients/domain/contracts/patient_balance_lookup.dart';
import 'package:eyadty/features/bookings/data/services/booking_patient_balance_lookup_impl.dart';
import 'package:eyadty/features/patients/domain/repo/medical_catalog_repo.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_medical_catalog_item_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/archive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/delete_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/find_patients_by_phone_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_medical_catalog_items_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patient_by_id_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patients_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/unarchive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/update_patient_use_case.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';

// Settings Feature
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';
import 'package:eyadty/features/settings/domain/use_cases/add_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/change_password_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/delete_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_print_settings_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';

// Medical Services Catalog Feature
import 'package:eyadty/features/settings/data/repo/medical_services_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/repo/medical_services_repo.dart';
import 'package:eyadty/features/settings/domain/use_cases/add_medical_service_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/delete_medical_service_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_service_by_id_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/toggle_medical_service_status_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_medical_service_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';

// Doctors Feature
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/repo/doctors_repo.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_by_id_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/save_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/update_doctor_use_case.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';

// Features
import 'package:eyadty/features/home_dashboard/presentation/cubit/home_dashboard_cubit.dart';
import 'package:eyadty/features/branches/domain/repo/branches_repo.dart';
import 'package:eyadty/features/branches/data/repo/branches_mock_repo_impl.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';
import 'package:eyadty/features/audit_logs/domain/repo/audit_logs_repo.dart';
import 'package:eyadty/features/audit_logs/data/repo/audit_logs_mock_repo_impl.dart';
import 'package:eyadty/features/audit_logs/presentation/cubit/audit_logs_cubit.dart';
import 'package:eyadty/features/cashier/domain/repo/cashier_repo.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_mock_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/contracts/cashier_policy.dart';
import 'package:eyadty/features/cashier/domain/helpers/cashier_shift_calculator.dart';
import 'package:eyadty/features/cashier/domain/helpers/payment_reconciliation_helper.dart';
import 'package:eyadty/features/cashier/domain/use_cases/get_active_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/open_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/close_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/collect_payment_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/refund_payment_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/record_drawer_expense_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/approve_shortage_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/force_close_shift_use_case.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';

// HR Feature
import 'package:eyadty/features/hr/domain/repo/hr_repo.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_mock_lookup.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_doctor_compensation_rules_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_active_rule_for_doctor_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/generate_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_staff_payroll_profile_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';

// Analytics Feature
import 'package:eyadty/features/analytics/data/repo/analytics_mock_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/repo/analytics_repo.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // Fail-loud safety gate: Prevent accidental mock repo registration in production mode
  AppConfig.assertDemoModeAllowed('setupGetIt');

  // ─── Network & Core Services ───────────────────────────────────────────────
  getIt.registerSingleton<Dio>(
    Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      )
        ..followRedirects = false
        ..receiveDataWhenStatusError = true,
    ),
  );

  getIt.registerSingleton<DioConsumer>(
    DioConsumer(
      dio: getIt.get<Dio>()
        ..interceptors.add(AppInterceptors(dio: getIt.get<Dio>()))
        ..interceptors.addAll([
          if (kDebugMode)
            PrettyDioLogger(
              request: true,
              requestBody: true,
              responseHeader: true,
              responseBody: true,
              error: true,
              compact: true,
            ),
        ]),
    ),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  getIt.registerLazySingleton<DataModeService>(
    () => DataModeService(),
  );

  getIt.registerLazySingleton<TransactionalLocalStore>(
    () => InMemoryTransactionalStore(
      dataModeService: getIt<DataModeService>(),
    ),
  );

  getIt.registerLazySingleton<RemoteSyncApi>(
    () => FakeRemoteSyncApi(),
  );

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      localStore: getIt<TransactionalLocalStore>(),
      dataModeService: getIt<DataModeService>(),
      remoteApi: getIt<RemoteSyncApi>(),
    ),
  );

  // ─── Session & Role Provider ──────────────────────────────────────────────
  getIt.registerLazySingleton<SessionCubit>(
    () => SessionCubit(SessionState.initial()),
  );
  getIt.registerLazySingleton<LocalPasscodeCubit>(
    () => LocalPasscodeCubit(),
  );
  getIt.registerLazySingleton<AppThemeCubit>(
    () => AppThemeCubit(),
  );
  getIt.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(
      auditLogger:
          getIt.isRegistered<AuditLogger>() ? getIt<AuditLogger>() : null,
    ),
  );
  getIt.registerLazySingleton<CurrentUserProvider>(() => getIt<SessionCubit>());
  getIt.registerLazySingleton<CurrentRoleProvider>(() => getIt<SessionCubit>());
  getIt.registerLazySingleton<RolesProvider>(() => getIt<SessionCubit>());
  getIt.registerLazySingleton<PermissionEvaluator>(
    () => getIt<SessionCubit>().permissionEvaluator,
  );

  // ─── Shared & Auth ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LoginRepo>(
    () => LoginRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(loginRepo: getIt<LoginRepo>()),
  );

  getIt.registerLazySingleton<LayoutRepo>(
    () => LayoutRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(repository: getIt<LayoutRepo>()),
  );

  getIt.registerLazySingleton<BasicCubit>(
    () => BasicCubit(
      getProfileUseCase: getIt<GetProfileUseCase>(),
    ),
  );

  // ─── Bookings Feature ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<BookingsMockRepoImpl>(
    () => BookingsMockRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<BookingsRepo>(
    () => OfflineFirstBookingsRepo(
      localStore: getIt<TransactionalLocalStore>(),
      dataModeService: getIt<DataModeService>(),
      remoteRepo: getIt<BookingsMockRepoImpl>(),
      getCurrentAccountId: () => 'default',
      getCurrentBranchId: () =>
          getIt<SessionCubit>().state.activeBranchId ?? 'branch_1',
    ),
  );

  getIt.registerLazySingleton<GetBookingSummaryUseCase>(
    () => GetBookingSummaryUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<GetBookingsUseCase>(
    () => GetBookingsUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<GetBookingByIdUseCase>(
    () => GetBookingByIdUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<CreateBookingUseCase>(
    () => CreateBookingUseCase(
      repo: getIt<BookingsRepo>(),
      staffUsersRepo: getIt<StaffUsersRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<UpdateBookingUseCase>(
    () => UpdateBookingUseCase(
      repo: getIt<BookingsRepo>(),
      staffUsersRepo: getIt<StaffUsersRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<ChangeBookingStatusUseCase>(
    () => ChangeBookingStatusUseCase(
      repo: getIt<BookingsRepo>(),
      activeVisitLookup: getIt<ActiveVisitLookup>(),
    ),
  );
  getIt.registerLazySingleton<ReassignTechnicianUseCase>(
    () => ReassignTechnicianUseCase(
      repo: getIt<BookingsRepo>(),
      activeVisitLookup: getIt<ActiveVisitLookup>(),
    ),
  );
  getIt.registerLazySingleton<DeleteBookingUseCase>(
    () => DeleteBookingUseCase(
      repo: getIt<BookingsRepo>(),
      activeVisitLookup: getIt<ActiveVisitLookup>(),
    ),
  );
  getIt.registerLazySingleton<GetDoctorBookingsForDateUseCase>(
    () => GetDoctorBookingsForDateUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<ApplyBookingDiscountUseCase>(
    () => ApplyBookingDiscountUseCase(
      bookingsRepo: getIt<BookingsRepo>(),
      staffUsersRepo: getIt<StaffUsersRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<RemoveBookingDiscountUseCase>(
    () => RemoveBookingDiscountUseCase(
      bookingsRepo: getIt<BookingsRepo>(),
      staffUsersRepo: getIt<StaffUsersRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<UpdateRoleDiscountPolicyUseCase>(
    () => UpdateRoleDiscountPolicyUseCase(
      staffUsersRepo: getIt<StaffUsersRepo>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<SaveRoleUseCase>(
    () => SaveRoleUseCase(
      staffUsersRepo: getIt<StaffUsersRepo>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  // ─── Visits Feature ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<VisitsMockRepoImpl>(
    () => VisitsMockRepoImpl(bookingsRepo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<OfflineFirstVisitsRepo>(
    () => OfflineFirstVisitsRepo(
      localStore: getIt<TransactionalLocalStore>(),
      dataModeService: getIt<DataModeService>(),
      remoteRepo: getIt<VisitsMockRepoImpl>(),
      getCurrentAccountId: () => 'default',
      getCurrentBranchId: () =>
          getIt<SessionCubit>().state.activeBranchId ?? 'branch_1',
    ),
  );
  getIt.registerLazySingleton<VisitsRepo>(
    () => getIt<OfflineFirstVisitsRepo>(),
  );
  getIt.registerLazySingleton<ActiveVisitLookup>(
    () => getIt<OfflineFirstVisitsRepo>(),
  );

  getIt.registerLazySingleton<GetDoctorQueueUseCase>(
    () => GetDoctorQueueUseCase(repo: getIt<VisitsRepo>()),
  );
  getIt.registerLazySingleton<GetVisitByBookingIdUseCase>(
    () => GetVisitByBookingIdUseCase(repo: getIt<VisitsRepo>()),
  );
  getIt.registerLazySingleton<StartConsultationUseCase>(
    () => StartConsultationUseCase(
      visitsRepo: getIt<VisitsRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<SaveVisitDraftUseCase>(
    () => SaveVisitDraftUseCase(
      repo: getIt<VisitsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
    ),
  );
  getIt.registerLazySingleton<RecordVitalsUseCase>(
    () => RecordVitalsUseCase(
      visitsRepo: getIt<VisitsRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<FinalizeVisitUseCase>(
    () => FinalizeVisitUseCase(
      visitsRepo: getIt<VisitsRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<AddVisitAddendumUseCase>(
    () => AddVisitAddendumUseCase(
      visitsRepo: getIt<VisitsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<PrintPrescriptionUseCase>(
    () => PrintPrescriptionUseCase(
      permissionEvaluator: getIt<PermissionEvaluator>(),
      userProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerFactory<BookingsCubit>(
    () => BookingsCubit(
      getBookingSummaryUseCase: getIt<GetBookingSummaryUseCase>(),
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      getBookingByIdUseCase: getIt<GetBookingByIdUseCase>(),
      createBookingUseCase: getIt<CreateBookingUseCase>(),
      updateBookingUseCase: getIt<UpdateBookingUseCase>(),
      changeBookingStatusUseCase: getIt<ChangeBookingStatusUseCase>(),
      reassignTechnicianUseCase: getIt<ReassignTechnicianUseCase>(),
      deleteBookingUseCase: getIt<DeleteBookingUseCase>(),
      getDoctorsUseCase: getIt<GetDoctorsUseCase>(),
      getPatientsUseCase: getIt<GetPatientsUseCase>(),
      getMedicalServicesUseCase: getIt<GetMedicalServicesUseCase>(),
      getDoctorScheduleUseCase: getIt<GetDoctorScheduleUseCase>(),
      getDoctorLeavesUseCase: getIt<GetDoctorLeavesUseCase>(),
      getCompanySettingsUseCase: getIt<GetCompanySettingsUseCase>(),
      getDoctorBookingsForDateUseCase: getIt<GetDoctorBookingsForDateUseCase>(),
      applyBookingDiscountUseCase: getIt<ApplyBookingDiscountUseCase>(),
      removeBookingDiscountUseCase: getIt<RemoveBookingDiscountUseCase>(),
      sessionCubit: getIt<SessionCubit>(),
    ),
  );

  // ─── Drugs Feature ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<DrugsMockRepoImpl>(
    () => DrugsMockRepoImpl(),
  );

  getIt.registerLazySingleton<DrugsRepo>(
    () => OfflineFirstDrugsRepo(
      localStore: getIt<TransactionalLocalStore>(),
      dataModeService: getIt<DataModeService>(),
      remoteRepo: getIt<DrugsMockRepoImpl>(),
      getCurrentAccountId: () => 'default',
      getCurrentBranchId: () =>
          getIt<SessionCubit>().state.activeBranchId ?? 'branch_1',
    ),
  );

  getIt.registerLazySingleton<GetDrugsCatalogUseCase>(
    () => GetDrugsCatalogUseCase(repo: getIt<DrugsRepo>()),
  );
  getIt.registerLazySingleton<AddDrugUseCase>(
    () => AddDrugUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<UpdateDrugUseCase>(
    () => UpdateDrugUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<ArchiveDrugUseCase>(
    () => ArchiveDrugUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<QuickAddDrugUseCase>(
    () => QuickAddDrugUseCase(
      repo: getIt<DrugsRepo>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<ReviewQuickAddDrugUseCase>(
    () => ReviewQuickAddDrugUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<GetDoctorTemplatesUseCase>(
    () => GetDoctorTemplatesUseCase(repo: getIt<DrugsRepo>()),
  );
  getIt.registerLazySingleton<SavePrescriptionTemplateUseCase>(
    () => SavePrescriptionTemplateUseCase(
      repo: getIt<DrugsRepo>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<DeletePrescriptionTemplateUseCase>(
    () => DeletePrescriptionTemplateUseCase(
      repo: getIt<DrugsRepo>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<UpdateAllergyAliasesUseCase>(
    () => UpdateAllergyAliasesUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<ImportDrugsUseCase>(
    () => ImportDrugsUseCase(
      repo: getIt<DrugsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  // ─── Patients Feature ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<MedicalCatalogRepo>(
    () => MedicalCatalogMockRepoImpl(),
  );

  getIt.registerLazySingleton<GetMedicalCatalogItemsUseCase>(
    () => GetMedicalCatalogItemsUseCase(repo: getIt<MedicalCatalogRepo>()),
  );
  getIt.registerLazySingleton<AddMedicalCatalogItemUseCase>(
    () => AddMedicalCatalogItemUseCase(repo: getIt<MedicalCatalogRepo>()),
  );

  getIt.registerLazySingleton<PatientBalanceLookup>(
    () => BookingPatientBalanceLookupImpl(getIt<BookingsRepo>()),
  );

  getIt.registerLazySingleton<PatientsMockRepoImpl>(
    () => PatientsMockRepoImpl(
      apiConsumer: getIt<DioConsumer>(),
      roleProvider: getIt<CurrentRoleProvider>(),
      bookingsRepo: getIt<BookingsRepo>(),
      balanceLookup: getIt<PatientBalanceLookup>(),
    ),
  );

  getIt.registerLazySingleton<PatientsRepo>(
    () => OfflineFirstPatientsRepo(
      localStore: getIt<TransactionalLocalStore>(),
      dataModeService: getIt<DataModeService>(),
      remoteRepo: getIt<PatientsMockRepoImpl>(),
      getCurrentAccountId: () => 'default',
      getCurrentBranchId: () =>
          getIt<SessionCubit>().state.activeBranchId ?? 'branch_1',
    ),
  );

  getIt.registerLazySingleton<GetPatientsUseCase>(
    () => GetPatientsUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<GetPatientByIdUseCase>(
    () => GetPatientByIdUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<AddPatientUseCase>(
    () => AddPatientUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<UpdatePatientUseCase>(
    () => UpdatePatientUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<DeletePatientUseCase>(
    () => DeletePatientUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<ArchivePatientUseCase>(
    () => ArchivePatientUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<UnarchivePatientUseCase>(
    () => UnarchivePatientUseCase(repo: getIt<PatientsRepo>()),
  );
  getIt.registerLazySingleton<FindPatientsByPhoneUseCase>(
    () => FindPatientsByPhoneUseCase(repo: getIt<PatientsRepo>()),
  );

  getIt.registerFactory<PatientsCubit>(
    () => PatientsCubit(
      getPatientsUseCase: getIt<GetPatientsUseCase>(),
      getPatientByIdUseCase: getIt<GetPatientByIdUseCase>(),
      addPatientUseCase: getIt<AddPatientUseCase>(),
      updatePatientUseCase: getIt<UpdatePatientUseCase>(),
      deletePatientUseCase: getIt<DeletePatientUseCase>(),
      archivePatientUseCase: getIt<ArchivePatientUseCase>(),
      unarchivePatientUseCase: getIt<UnarchivePatientUseCase>(),
      findPatientsByPhoneUseCase: getIt<FindPatientsByPhoneUseCase>(),
      getMedicalCatalogItemsUseCase: getIt<GetMedicalCatalogItemsUseCase>(),
      addMedicalCatalogItemUseCase: getIt<AddMedicalCatalogItemUseCase>(),
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      changeBookingStatusUseCase: getIt<ChangeBookingStatusUseCase>(),
      reassignTechnicianUseCase: getIt<ReassignTechnicianUseCase>(),
      deleteBookingUseCase: getIt<DeleteBookingUseCase>(),
      patientsRepo: getIt<PatientsRepo>(),
    ),
  );

  // ─── Settings Feature ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<SettingsRepo>(
    () => SettingsMockRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<GetCompanySettingsUseCase>(
    () => GetCompanySettingsUseCase(repo: getIt<SettingsRepo>()),
  );
  getIt.registerLazySingleton<UpdateCompanySettingsUseCase>(
    () => UpdateCompanySettingsUseCase(repo: getIt<SettingsRepo>()),
  );
  getIt.registerLazySingleton<AddSpecialHolidayUseCase>(
    () => AddSpecialHolidayUseCase(repo: getIt<SettingsRepo>()),
  );
  getIt.registerLazySingleton<DeleteSpecialHolidayUseCase>(
    () => DeleteSpecialHolidayUseCase(repo: getIt<SettingsRepo>()),
  );
  getIt.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(repo: getIt<SettingsRepo>()),
  );
  getIt.registerLazySingleton<UpdatePrintSettingsUseCase>(
    () => UpdatePrintSettingsUseCase(
      repo: getIt<SettingsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  // ─── Medical Services Catalog ───────────────────────────────────────────────
  getIt.registerLazySingleton<MedicalServicesRepo>(
    () => MedicalServicesMockRepoImpl(
      roleProvider: getIt<CurrentRoleProvider>(),
      bookingsRepo: getIt<BookingsRepo>(),
    ),
  );

  getIt.registerLazySingleton<GetMedicalServicesUseCase>(
    () => GetMedicalServicesUseCase(repo: getIt<MedicalServicesRepo>()),
  );
  getIt.registerLazySingleton<GetMedicalServiceByIdUseCase>(
    () => GetMedicalServiceByIdUseCase(repo: getIt<MedicalServicesRepo>()),
  );
  getIt.registerLazySingleton<AddMedicalServiceUseCase>(
    () => AddMedicalServiceUseCase(repo: getIt<MedicalServicesRepo>()),
  );
  getIt.registerLazySingleton<UpdateMedicalServiceUseCase>(
    () => UpdateMedicalServiceUseCase(repo: getIt<MedicalServicesRepo>()),
  );
  getIt.registerLazySingleton<ToggleMedicalServiceStatusUseCase>(
    () => ToggleMedicalServiceStatusUseCase(repo: getIt<MedicalServicesRepo>()),
  );
  getIt.registerLazySingleton<DeleteMedicalServiceUseCase>(
    () => DeleteMedicalServiceUseCase(repo: getIt<MedicalServicesRepo>()),
  );

  // ─── Doctors Feature ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<DoctorsRepo>(
    () => DoctorsMockRepoImpl(
      apiConsumer: getIt<DioConsumer>(),
      roleProvider: getIt<CurrentRoleProvider>(),
      bookingsRepo: getIt<BookingsRepo>(),
      settingsRepo: getIt<SettingsRepo>(),
    ),
  );

  // ─── Users Management Feature & Security Audit ─────────────────────────────
  getIt.registerLazySingleton<AuditLogger>(
    () => InMemoryAuditLogger(),
  );

  getIt.registerLazySingleton<StaffUsersRepo>(
    () => StaffUsersMockRepoImpl(
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<BranchesRepo>(
    () => BranchesMockRepoImpl(
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerFactory<BranchesCubit>(
    () => BranchesCubit(
      branchesRepo: getIt<BranchesRepo>(),
    ),
  );

  getIt.registerFactory<StaffUsersCubit>(
    () => StaffUsersCubit(
      staffUsersRepo: getIt<StaffUsersRepo>(),
      saveRoleUseCase: getIt<SaveRoleUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AuditLogsRepo>(
    () => AuditLogsMockRepoImpl(
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<CashierPolicy>(
    () => const CashierPolicy(),
  );

  getIt.registerLazySingleton<CashierShiftCalculator>(
    () => const CashierShiftCalculator(),
  );

  getIt.registerLazySingleton<PaymentReconciliationHelper>(
    () => const PaymentReconciliationHelper(),
  );

  getIt.registerLazySingleton<CashierRepo>(
    () => CashierMockRepoImpl(),
  );

  getIt.registerLazySingleton<GetActiveShiftUseCase>(
    () => GetActiveShiftUseCase(
      cashierRepo: getIt<CashierRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
    ),
  );

  getIt.registerLazySingleton<OpenShiftDrawerUseCase>(
    () => OpenShiftDrawerUseCase(
      cashierRepo: getIt<CashierRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<CloseShiftDrawerUseCase>(
    () => CloseShiftDrawerUseCase(
      cashierRepo: getIt<CashierRepo>(),
      policy: getIt<CashierPolicy>(),
      calculator: getIt<CashierShiftCalculator>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<CollectPaymentUseCase>(
    () => CollectPaymentUseCase(
      cashierRepo: getIt<CashierRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      reconciliationHelper: getIt<PaymentReconciliationHelper>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<RefundPaymentUseCase>(
    () => RefundPaymentUseCase(
      cashierRepo: getIt<CashierRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      reconciliationHelper: getIt<PaymentReconciliationHelper>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<RecordDrawerExpenseUseCase>(
    () => RecordDrawerExpenseUseCase(
      cashierRepo: getIt<CashierRepo>(),
      policy: getIt<CashierPolicy>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<ApproveShortageUseCase>(
    () => ApproveShortageUseCase(
      cashierRepo: getIt<CashierRepo>(),
      staffUsersRepo: getIt<StaffUsersRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<ForceCloseShiftUseCase>(
    () => ForceCloseShiftUseCase(
      cashierRepo: getIt<CashierRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerFactory<CashierCubit>(
    () => CashierCubit(
      cashierRepo: getIt<CashierRepo>(),
      getActiveShiftUseCase: getIt<GetActiveShiftUseCase>(),
      openShiftDrawerUseCase: getIt<OpenShiftDrawerUseCase>(),
      closeShiftDrawerUseCase: getIt<CloseShiftDrawerUseCase>(),
      collectPaymentUseCase: getIt<CollectPaymentUseCase>(),
      refundPaymentUseCase: getIt<RefundPaymentUseCase>(),
      recordDrawerExpenseUseCase: getIt<RecordDrawerExpenseUseCase>(),
      approveShortageUseCase: getIt<ApproveShortageUseCase>(),
      forceCloseShiftUseCase: getIt<ForceCloseShiftUseCase>(),
    ),
  );

  getIt.registerFactory<AuditLogsCubit>(
    () => AuditLogsCubit(
      repo: getIt<AuditLogsRepo>(),
    ),
  );

  getIt.registerLazySingleton<GetDoctorsUseCase>(
    () => GetDoctorsUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<GetDoctorByIdUseCase>(
    () => GetDoctorByIdUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<AddDoctorUseCase>(
    () => AddDoctorUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<UpdateDoctorUseCase>(
    () => UpdateDoctorUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<DeleteDoctorUseCase>(
    () => DeleteDoctorUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<GetDoctorLeavesUseCase>(
    () => GetDoctorLeavesUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<AddDoctorLeaveUseCase>(
    () => AddDoctorLeaveUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<DeleteDoctorLeaveUseCase>(
    () => DeleteDoctorLeaveUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<GetDoctorScheduleUseCase>(
    () => GetDoctorScheduleUseCase(repo: getIt<DoctorsRepo>()),
  );
  getIt.registerLazySingleton<SaveDoctorScheduleUseCase>(
    () => SaveDoctorScheduleUseCase(repo: getIt<DoctorsRepo>()),
  );

  // ─── Features Cubits ───────────────────────────────────────────────────────
  getIt.registerFactory<HomeDashboardCubit>(
    () => HomeDashboardCubit(),
  );

  getIt.registerFactory<DoctorsCubit>(
    () => DoctorsCubit(
      getDoctorsUseCase: getIt<GetDoctorsUseCase>(),
      getDoctorByIdUseCase: getIt<GetDoctorByIdUseCase>(),
      addDoctorUseCase: getIt<AddDoctorUseCase>(),
      updateDoctorUseCase: getIt<UpdateDoctorUseCase>(),
      deleteDoctorUseCase: getIt<DeleteDoctorUseCase>(),
      getDoctorLeavesUseCase: getIt<GetDoctorLeavesUseCase>(),
      addDoctorLeaveUseCase: getIt<AddDoctorLeaveUseCase>(),
      deleteDoctorLeaveUseCase: getIt<DeleteDoctorLeaveUseCase>(),
      getDoctorScheduleUseCase: getIt<GetDoctorScheduleUseCase>(),
      saveDoctorScheduleUseCase: getIt<SaveDoctorScheduleUseCase>(),
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      changeBookingStatusUseCase: getIt<ChangeBookingStatusUseCase>(),
      reassignTechnicianUseCase: getIt<ReassignTechnicianUseCase>(),
      deleteBookingUseCase: getIt<DeleteBookingUseCase>(),
    ),
  );

  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getCompanySettingsUseCase: getIt<GetCompanySettingsUseCase>(),
      updateCompanySettingsUseCase: getIt<UpdateCompanySettingsUseCase>(),
      addSpecialHolidayUseCase: getIt<AddSpecialHolidayUseCase>(),
      deleteSpecialHolidayUseCase: getIt<DeleteSpecialHolidayUseCase>(),
      changePasswordUseCase: getIt<ChangePasswordUseCase>(),
      updatePrintSettingsUseCase: getIt<UpdatePrintSettingsUseCase>(),
    ),
  );

  getIt.registerFactory<MedicalServicesCubit>(
    () => MedicalServicesCubit(
      getMedicalServicesUseCase: getIt<GetMedicalServicesUseCase>(),
      addMedicalServiceUseCase: getIt<AddMedicalServiceUseCase>(),
      updateMedicalServiceUseCase: getIt<UpdateMedicalServiceUseCase>(),
      toggleMedicalServiceStatusUseCase:
          getIt<ToggleMedicalServiceStatusUseCase>(),
      deleteMedicalServiceUseCase: getIt<DeleteMedicalServiceUseCase>(),
    ),
  );

  getIt.registerLazySingleton<VisitsCubit>(
    () => VisitsCubit(
      visitsRepo: getIt<VisitsRepo>(),
      bookingsRepo: getIt<BookingsRepo>(),
      patientsRepo: getIt<PatientsRepo>(),
      getDoctorQueueUseCase: getIt<GetDoctorQueueUseCase>(),
      getVisitByBookingIdUseCase: getIt<GetVisitByBookingIdUseCase>(),
      startConsultationUseCase: getIt<StartConsultationUseCase>(),
      saveVisitDraftUseCase: getIt<SaveVisitDraftUseCase>(),
      recordVitalsUseCase: getIt<RecordVitalsUseCase>(),
      finalizeVisitUseCase: getIt<FinalizeVisitUseCase>(),
      addVisitAddendumUseCase: getIt<AddVisitAddendumUseCase>(),
      printPrescriptionUseCase: getIt<PrintPrescriptionUseCase>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      auditLogger: getIt<AuditLogger>(),
      sessionCubit: getIt.isRegistered<SessionCubit>()
          ? getIt<SessionCubit>()
          : null,
    ),
  );

  getIt.registerFactory<DrugsCubit>(
    () => DrugsCubit(
      repo: getIt<DrugsRepo>(),
      medicalCatalogRepo: getIt<MedicalCatalogRepo>(),
      getDrugsCatalogUseCase: getIt<GetDrugsCatalogUseCase>(),
      addDrugUseCase: getIt<AddDrugUseCase>(),
      updateDrugUseCase: getIt<UpdateDrugUseCase>(),
      archiveDrugUseCase: getIt<ArchiveDrugUseCase>(),
      reviewQuickAddDrugUseCase: getIt<ReviewQuickAddDrugUseCase>(),
      getDoctorTemplatesUseCase: getIt<GetDoctorTemplatesUseCase>(),
      savePrescriptionTemplateUseCase: getIt<SavePrescriptionTemplateUseCase>(),
      deletePrescriptionTemplateUseCase:
          getIt<DeletePrescriptionTemplateUseCase>(),
      updateAllergyAliasesUseCase: getIt<UpdateAllergyAliasesUseCase>(),
      importDrugsUseCase: getIt<ImportDrugsUseCase>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      userProvider: getIt<CurrentUserProvider>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  // ─── Medical Catalogs Feature ──────────────────────────────────────────────
  getIt.registerLazySingleton<MedicalCatalogsRepo>(
    () => MedicalCatalogsMockRepoImpl(),
  );
  getIt.registerFactory<MedicalCatalogsCubit>(
    () => MedicalCatalogsCubit(
      repo: getIt<MedicalCatalogsRepo>(),
    ),
  );

  // ─── Inventory & Medical Supplies Feature ────────────────────────────────────
  getIt.registerLazySingleton<InventoryRepo>(
    () => InventoryMockRepoImpl(),
  );
  getIt.registerFactory<InventoryCubit>(
    () => InventoryCubit(
      repo: getIt<InventoryRepo>(),
    ),
  );

  // ─── HR & Doctor Settlements Feature ──────────────────────────────────────
  getIt.registerLazySingleton<HrRepo>(
    () => HrMockRepoImpl(seedInitialData: true),
  );
  getIt.registerLazySingleton<DoctorSettlementVisitsLookup>(
    () => DoctorSettlementVisitsMockLookup(),
  );

  getIt.registerLazySingleton<GetDoctorCompensationRulesUseCase>(
    () => GetDoctorCompensationRulesUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );
  getIt.registerLazySingleton<SaveDoctorCompensationRuleUseCase>(
    () => SaveDoctorCompensationRuleUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<GetActiveRuleForDoctorUseCase>(
    () => GetActiveRuleForDoctorUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );
  getIt.registerLazySingleton<CalculateDoctorSettlementDraftUseCase>(
    () => CalculateDoctorSettlementDraftUseCase(
      hrRepo: getIt<HrRepo>(),
      visitsLookup: getIt<DoctorSettlementVisitsLookup>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<ConfirmDoctorSettlementUseCase>(
    () => ConfirmDoctorSettlementUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<PayoutDoctorSettlementUseCase>(
    () => PayoutDoctorSettlementUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<GenerateStaffPayrollPeriodUseCase>(
    () => GenerateStaffPayrollPeriodUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );
  getIt.registerLazySingleton<SaveStaffPayrollProfileUseCase>(
    () => SaveStaffPayrollProfileUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );
  getIt.registerLazySingleton<ConfirmStaffPayrollPeriodUseCase>(
    () => ConfirmStaffPayrollPeriodUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );
  getIt.registerLazySingleton<PayoutStaffPayrollPeriodUseCase>(
    () => PayoutStaffPayrollPeriodUseCase(
      hrRepo: getIt<HrRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerFactory<HrCubit>(
    () => HrCubit(
      hrRepo: getIt<HrRepo>(),
      getDoctorCompensationRulesUseCase:
          getIt<GetDoctorCompensationRulesUseCase>(),
      saveDoctorCompensationRuleUseCase:
          getIt<SaveDoctorCompensationRuleUseCase>(),
      getActiveRuleForDoctorUseCase: getIt<GetActiveRuleForDoctorUseCase>(),
      calculateDoctorSettlementDraftUseCase:
          getIt<CalculateDoctorSettlementDraftUseCase>(),
      confirmDoctorSettlementUseCase: getIt<ConfirmDoctorSettlementUseCase>(),
      payoutDoctorSettlementUseCase: getIt<PayoutDoctorSettlementUseCase>(),
      generateStaffPayrollPeriodUseCase:
          getIt<GenerateStaffPayrollPeriodUseCase>(),
      saveStaffPayrollProfileUseCase: getIt<SaveStaffPayrollProfileUseCase>(),
      confirmStaffPayrollPeriodUseCase:
          getIt<ConfirmStaffPayrollPeriodUseCase>(),
      payoutStaffPayrollPeriodUseCase:
          getIt<PayoutStaffPayrollPeriodUseCase>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );

  // ─── 14. Analytics & Executive Reports Feature ──────────────────────────────
  getIt.registerLazySingleton<AnalyticsRepo>(
    () => const AnalyticsMockRepoImpl(),
  );

  getIt.registerLazySingleton<GetAnalyticsSummaryUseCase>(
    () => GetAnalyticsSummaryUseCase(
      analyticsRepo: getIt<AnalyticsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
      auditLogger: getIt<AuditLogger>(),
    ),
  );

  getIt.registerLazySingleton<GetRevenueTrendUseCase>(
    () => GetRevenueTrendUseCase(
      analyticsRepo: getIt<AnalyticsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );

  getIt.registerLazySingleton<GetBranchComparisonUseCase>(
    () => GetBranchComparisonUseCase(
      analyticsRepo: getIt<AnalyticsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );

  getIt.registerLazySingleton<GetDoctorPerformanceUseCase>(
    () => GetDoctorPerformanceUseCase(
      analyticsRepo: getIt<AnalyticsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );

  getIt.registerLazySingleton<GetHourlyTrafficUseCase>(
    () => GetHourlyTrafficUseCase(
      analyticsRepo: getIt<AnalyticsRepo>(),
      permissionEvaluator: getIt<PermissionEvaluator>(),
      currentUserProvider: getIt<SessionCubit>(),
    ),
  );

  getIt.registerFactory<AnalyticsCubit>(
    () => AnalyticsCubit(
      analyticsRepo: getIt<AnalyticsRepo>(),
      getAnalyticsSummaryUseCase: getIt<GetAnalyticsSummaryUseCase>(),
      getRevenueTrendUseCase: getIt<GetRevenueTrendUseCase>(),
      getBranchComparisonUseCase: getIt<GetBranchComparisonUseCase>(),
      getDoctorPerformanceUseCase: getIt<GetDoctorPerformanceUseCase>(),
      getHourlyTrafficUseCase: getIt<GetHourlyTrafficUseCase>(),
    ),
  );
}
