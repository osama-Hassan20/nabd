import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:purexo/core/api/app_interceptor.dart';
import 'package:purexo/core/api/dio_consumer.dart';
import 'package:purexo/core/api/end_points.dart';
import 'package:purexo/core/services/notification_service.dart';
import 'package:purexo/shared/app_layout/data/repositories/layout_repo_impl.dart';
import 'package:purexo/shared/app_layout/domain/repositories/layout_repo.dart';
import 'package:purexo/shared/app_layout/domain/use_cases/get_profile_use_case.dart';
import 'package:purexo/shared/auth/data/repositories/login_repo_impl.dart';
import 'package:purexo/shared/auth/domain/repositories/login_repo.dart';
import 'package:purexo/shared/auth/domain/use_cases/login/login_use_case.dart';
import 'package:purexo/shared/cubit/basic_cubit.dart';

import 'package:purexo/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:purexo/features/bookings/domain/repo/bookings_repo.dart';
import 'package:purexo/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:purexo/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';

// Customers Feature
import 'package:purexo/features/customers/data/repo/customers_repo_impl.dart';
import 'package:purexo/features/customers/domain/repo/customers_repo.dart';
import 'package:purexo/features/customers/domain/use_cases/add_customer_use_case.dart';
import 'package:purexo/features/customers/domain/use_cases/delete_customer_use_case.dart';
import 'package:purexo/features/customers/domain/use_cases/get_customer_by_id_use_case.dart';
import 'package:purexo/features/customers/domain/use_cases/get_customers_use_case.dart';
import 'package:purexo/features/customers/domain/use_cases/update_customer_use_case.dart';
import 'package:purexo/features/customers/presentation/manager/customers_cubit.dart';

// Settings Feature
import 'package:purexo/features/settings/data/repo/settings_repo_impl.dart';
import 'package:purexo/features/settings/domain/repo/settings_repo.dart';
import 'package:purexo/features/settings/domain/use_cases/add_special_holiday_use_case.dart';
import 'package:purexo/features/settings/domain/use_cases/change_password_use_case.dart';
import 'package:purexo/features/settings/domain/use_cases/delete_special_holiday_use_case.dart';
import 'package:purexo/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:purexo/features/settings/domain/use_cases/update_company_settings_use_case.dart';
import 'package:purexo/features/settings/presentation/cubit/settings_cubit.dart';

// Technicians Feature
import 'package:purexo/features/technicians/data/repo/technicians_repo_impl.dart';
import 'package:purexo/features/technicians/domain/repo/technicians_repo.dart';
import 'package:purexo/features/technicians/domain/use_cases/add_technician_leave_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/add_technician_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/delete_technician_leave_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/delete_technician_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/get_technician_by_id_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/get_technician_leaves_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/get_technicians_use_case.dart';
import 'package:purexo/features/technicians/domain/use_cases/update_technician_use_case.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_cubit.dart';

// Features
import 'package:purexo/features/home_dashboard/presentation/cubit/home_dashboard_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
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
  getIt.registerLazySingleton<BookingsRepo>(
    () => BookingsRepoImpl(apiConsumer: getIt<DioConsumer>()),
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
    () => CreateBookingUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<UpdateBookingUseCase>(
    () => UpdateBookingUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<ChangeBookingStatusUseCase>(
    () => ChangeBookingStatusUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<ReassignTechnicianUseCase>(
    () => ReassignTechnicianUseCase(repo: getIt<BookingsRepo>()),
  );
  getIt.registerLazySingleton<DeleteBookingUseCase>(
    () => DeleteBookingUseCase(repo: getIt<BookingsRepo>()),
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
      getTechniciansUseCase: getIt<GetTechniciansUseCase>(),
      getCustomersUseCase: getIt<GetCustomersUseCase>(),
    ),
  );

  // ─── Customers Feature ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<CustomersRepo>(
    () => CustomersRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<GetCustomersUseCase>(
    () => GetCustomersUseCase(repo: getIt<CustomersRepo>()),
  );
  getIt.registerLazySingleton<GetCustomerByIdUseCase>(
    () => GetCustomerByIdUseCase(repo: getIt<CustomersRepo>()),
  );
  getIt.registerLazySingleton<AddCustomerUseCase>(
    () => AddCustomerUseCase(repo: getIt<CustomersRepo>()),
  );
  getIt.registerLazySingleton<UpdateCustomerUseCase>(
    () => UpdateCustomerUseCase(repo: getIt<CustomersRepo>()),
  );
  getIt.registerLazySingleton<DeleteCustomerUseCase>(
    () => DeleteCustomerUseCase(repo: getIt<CustomersRepo>()),
  );

  getIt.registerFactory<CustomersCubit>(
    () => CustomersCubit(
      getCustomersUseCase: getIt<GetCustomersUseCase>(),
      getCustomerByIdUseCase: getIt<GetCustomerByIdUseCase>(),
      addCustomerUseCase: getIt<AddCustomerUseCase>(),
      updateCustomerUseCase: getIt<UpdateCustomerUseCase>(),
      deleteCustomerUseCase: getIt<DeleteCustomerUseCase>(),
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      changeBookingStatusUseCase: getIt<ChangeBookingStatusUseCase>(),
      reassignTechnicianUseCase: getIt<ReassignTechnicianUseCase>(),
      deleteBookingUseCase: getIt<DeleteBookingUseCase>(),
    ),
  );

  // ─── Settings Feature ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<SettingsRepo>(
    () => SettingsRepoImpl(apiConsumer: getIt<DioConsumer>()),
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

  // ─── Technicians Feature ───────────────────────────────────────────────────
  getIt.registerLazySingleton<TechniciansRepo>(
    () => TechniciansRepoImpl(apiConsumer: getIt<DioConsumer>()),
  );

  getIt.registerLazySingleton<GetTechniciansUseCase>(
    () => GetTechniciansUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<GetTechnicianByIdUseCase>(
    () => GetTechnicianByIdUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<AddTechnicianUseCase>(
    () => AddTechnicianUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<UpdateTechnicianUseCase>(
    () => UpdateTechnicianUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<DeleteTechnicianUseCase>(
    () => DeleteTechnicianUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<GetTechnicianLeavesUseCase>(
    () => GetTechnicianLeavesUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<AddTechnicianLeaveUseCase>(
    () => AddTechnicianLeaveUseCase(repo: getIt<TechniciansRepo>()),
  );
  getIt.registerLazySingleton<DeleteTechnicianLeaveUseCase>(
    () => DeleteTechnicianLeaveUseCase(repo: getIt<TechniciansRepo>()),
  );

  // ─── Features Cubits ───────────────────────────────────────────────────────
  getIt.registerFactory<HomeDashboardCubit>(
    () => HomeDashboardCubit(),
  );

  getIt.registerFactory<TechniciansCubit>(
    () => TechniciansCubit(
      getTechniciansUseCase: getIt<GetTechniciansUseCase>(),
      getTechnicianByIdUseCase: getIt<GetTechnicianByIdUseCase>(),
      addTechnicianUseCase: getIt<AddTechnicianUseCase>(),
      updateTechnicianUseCase: getIt<UpdateTechnicianUseCase>(),
      deleteTechnicianUseCase: getIt<DeleteTechnicianUseCase>(),
      getTechnicianLeavesUseCase: getIt<GetTechnicianLeavesUseCase>(),
      addTechnicianLeaveUseCase: getIt<AddTechnicianLeaveUseCase>(),
      deleteTechnicianLeaveUseCase: getIt<DeleteTechnicianLeaveUseCase>(),
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
    ),
  );
}
