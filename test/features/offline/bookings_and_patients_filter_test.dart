import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_bookings_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';

void main() {
  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late OfflineFirstBookingsRepo bookingsRepo;
  late OfflineFirstPatientsRepo patientsRepo;

  setUp(() {
    store = InMemoryTransactionalStore();
    dataModeService = DataModeService()..setReachability(false); // offline mode
    bookingsRepo = OfflineFirstBookingsRepo(
      localStore: store,
      remoteRepo: null,
      dataModeService: dataModeService,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch-1',
    );
    patientsRepo = OfflineFirstPatientsRepo(
      localStore: store,
      remoteRepo: null,
      dataModeService: dataModeService,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch-1',
    );
  });

  group('A5o & A5p: Bookings and Patients search & date filter', () {
    test('OfflineFirstBookingsRepo filters by date and search query', () async {
      final b1 = BookingModel(
        id: 'B1',
        patientName: 'أحمد محمود',
        appointmentTime: DateTime(2026, 11, 26, 10, 0),
        status: BookingStatusEnum.waiting,
      );
      final b2 = BookingModel(
        id: 'B2',
        patientName: 'سارة خالد',
        appointmentTime: DateTime(2026, 11, 27, 11, 0),
        status: BookingStatusEnum.waiting,
      );

      await bookingsRepo.createBooking(b1);
      await bookingsRepo.createBooking(b2);

      // 1. Date filter
      final dateRes = await bookingsRepo.getBookings(
        const PaginationParams(
          filterList: [FilterParam(key: 'date', value: '2026-11-26')],
        ),
      );
      final dateBookings = dateRes.getOrElse(() => throw 'failed').bookings ?? [];
      expect(dateBookings.length, equals(1));
      expect(dateBookings.first.id, equals('B1'));

      // 2. Search query filter
      final searchRes = await bookingsRepo.getBookings(
        const PaginationParams(
          filterList: [FilterParam(key: 'search', value: 'سارة')],
        ),
      );
      final searchBookings = searchRes.getOrElse(() => throw 'failed').bookings ?? [];
      expect(searchBookings.length, equals(1));
      expect(searchBookings.first.id, equals('B2'));
    });

    test('OfflineFirstPatientsRepo filters by search query', () async {
      const p1 = PatientModel(id: 'P1', name: 'محمد علي', phone: '01011111111');
      const p2 = PatientModel(id: 'P2', name: 'فاطمة حسن', phone: '01022222222');

      await patientsRepo.addPatient(patient: p1);
      await patientsRepo.addPatient(patient: p2);

      final searchRes = await patientsRepo.getPatients(
        params: const PaginationParams(),
        search: 'فاطمة',
      );
      final items = searchRes.getOrElse(() => throw 'failed').items ?? [];
      expect(items.length, equals(1));
      expect(items.first.name, equals('فاطمة حسن'));
    });

    test('A5j: Marking booking as noShow persists and updates getBookingSummary noShowCount', () async {
      final today = DateTime.now();
      final b = BookingModel(
        id: 'B-NOSHOW-1',
        patientId: 'P1',
        patientName: 'عميل لم يحضر',
        date: DateTime(today.year, today.month, today.day, 10, 0),
        appointmentTime: DateTime(today.year, today.month, today.day, 10, 0),
        status: BookingStatusEnum.scheduled,
        branchId: 'branch-1',
      );

      await bookingsRepo.createBooking(b);
      final changeRes = await bookingsRepo.changeBookingStatus(
        const ChangeBookingStatusParams(
          bookingId: 'B-NOSHOW-1',
          newStatus: BookingStatusEnum.noShow,
        ),
      );
      expect(changeRes.isRight(), isTrue);

      final listRes = await bookingsRepo.getBookings(const PaginationParams());
      final found = (listRes.getOrElse(() => throw 'err').bookings ?? [])
          .firstWhere((item) => item.id == 'B-NOSHOW-1');
      expect(found.status, equals(BookingStatusEnum.noShow));

      final summaryRes = await bookingsRepo.getBookingSummary(
        date: today,
        branchId: 'branch-1',
      );
      final summary = summaryRes.getOrElse(() => throw 'err');
      expect(summary.noShowCount, equals(1));
    });
  });
}
