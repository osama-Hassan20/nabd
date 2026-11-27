import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

/// Seeds [LocalServerDb] using JSON fixtures parsed through each model's
/// `fromJson` factory so local mode exercises real DTO deserialization.
class LocalServerSeeds {
  LocalServerSeeds._();

  static void seedAll(LocalServerDb db) {
    final now = CairoTimeHelper.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find next Friday for the clinic holiday fixture
    var friday = today;
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }

    // 1. Branches
    final branchFixtures = [
      {
        'id': 'branch_1',
        'name': 'فرع المهندسين (الرئيسي)',
        'nameKey': 'branch_main',
        'address': 'شارع جامعة الدول العربية، المهندسين',
        'phone': '0233001122',
        'isActive': true,
        'isMain': true,
        'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
      },
      {
        'id': 'branch_2',
        'name': 'فرع المعادي',
        'nameKey': 'branch_maadi',
        'address': 'شارع 9، المعادي',
        'phone': '0225251100',
        'isActive': true,
        'isMain': false,
        'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
      },
    ];
    db.replaceCollection(
      'branches',
      branchFixtures.map((j) => BranchModel.fromJson(j).toJson()).toList(),
    );

    // 2. Settings & Friday Holiday
    final settingsJson = CompanySettingsModel.fromJson({
      'companyName': 'عيادتي التخصصية',
      'companyPhone': '01000000000',
      'companyAddress': 'القاهرة، مصر',
      'clinicType': 'polyClinic',
      'currency': 'EGP',
      'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
    }).toJson();
    db.replaceCollection('settings', [settingsJson]);

    final holidayJson = SpecialHolidayModel.fromJson({
      'id': 'HOL-FRIDAY',
      'name': 'عطلة الجمعة الأسبوعية',
      'startDate': friday.toIso8601String(),
      'endDate': friday.toIso8601String(),
    }).toJson();
    db.replaceCollection('holidays', [holidayJson]);

    // 3. Roles & Staff Users
    final roles = RoleDefinitionModel.defaultSystemRoles();
    db.replaceCollection('roles', roles.map((r) => r.toJson()).toList());

    final staffFixtures = [
      {
        'id': 'USER-OWNER',
        'fullName': 'د. طارق (المالك)',
        'email': 'owner@eyadty.com',
        'phone': '01000000001',
        'jobTitle': 'المالك والمدير العام',
        'isActive': true,
        'isOwner': true,
        'isPracticingDoctor': true,
        'linkedDoctorId': 'DOC-01',
        'branchAssignments': [
          {'branchId': 'branch_1', 'roleIds': ['role_owner'], 'isPrimary': true},
        ],
      },
      {
        'id': 'USER-DOC',
        'fullName': 'د. حسام الدين مصطفى',
        'email': 'doctor@eyadty.com',
        'phone': '01000000004',
        'jobTitle': 'استشاري أمراض القلب',
        'isActive': true,
        'isPracticingDoctor': true,
        'linkedDoctorId': 'DOC-01',
        'branchAssignments': [
          {'branchId': 'branch_1', 'roleIds': ['role_doctor'], 'isPrimary': true},
        ],
      },
      {
        'id': 'USER-NURSE',
        'fullName': 'فاطمة علي (تمريض)',
        'email': 'nurse@eyadty.com',
        'phone': '01000000005',
        'jobTitle': 'ممرضة فرز ومتابعة',
        'isActive': true,
        'branchAssignments': [
          {'branchId': 'branch_1', 'roleIds': ['role_nurse'], 'isPrimary': true},
        ],
      },
      {
        'id': 'USER-RECEPTION',
        'fullName': 'سارة محمد (استقبال)',
        'email': 'reception@eyadty.com',
        'phone': '01000000003',
        'jobTitle': 'مسؤولة الاستقبال والحجوزات',
        'isActive': true,
        'branchAssignments': [
          {'branchId': 'branch_1', 'roleIds': ['role_reception'], 'isPrimary': true},
        ],
      },
      {
        'id': 'USER-ACC',
        'fullName': 'محمد كمال (محاسب)',
        'email': 'cashier@eyadty.com',
        'phone': '01000000006',
        'jobTitle': 'المحاسب المالي ومسؤول الخزينة',
        'isActive': true,
        'branchAssignments': [
          {'branchId': 'branch_1', 'roleIds': ['role_accountant'], 'isPrimary': true},
        ],
      },
    ];
    db.replaceCollection(
      'staffUsers',
      staffFixtures.map((j) => StaffUserModel.fromJson(j).toJson()).toList(),
    );

    // 4. Doctors & Schedules
    final doctorFixtures = [
      {
        'id': 'DOC-01',
        'name': 'د. حسام الدين مصطفى',
        'phone': '01011122233',
        'specialty': 'قلب وأوعية دموية',
        'specialties': [MedicalSpecialty.cardiology.value],
        'status': 'available',
      },
      {
        'id': 'DOC-02',
        'name': 'د. منى عبد الرحمن',
        'phone': '01022233344',
        'specialty': 'أمراض النساء والتوليد',
        'specialties': [MedicalSpecialty.obstetricsGynecology.value],
        'status': 'available',
      },
      {
        'id': 'DOC-03',
        'name': 'د. كريم محمود',
        'phone': '01033344455',
        'specialty': 'طب الأطفال وحديثي الولادة',
        'specialties': [MedicalSpecialty.pediatrics.value],
        'status': 'available',
      },
    ];
    db.replaceCollection(
      'doctors',
      doctorFixtures.map((j) => DoctorModel.fromJson(j).toJson()).toList(),
    );

    final schedules = ['DOC-01', 'DOC-02', 'DOC-03'].map((docId) {
      return DoctorScheduleModel.fromJson({
        'id': 'SCH-$docId',
        'doctorId': docId,
        'slotDurationMinutes': 20,
        'workDays': [
          for (final day in ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'])
            {'day': day, 'isWorkingDay': true, 'startTime': '09:00', 'endTime': '21:00'},
          {'day': 'friday', 'isWorkingDay': false},
        ],
      }).toJson();
    }).toList();
    db.replaceCollection('doctorSchedules', schedules);
    db.replaceCollection('doctorLeaves', []);

    // 5. Medical Services
    final serviceFixtures = [
      {
        'id': 'SRV-01',
        'name': 'كشف باطنة وقلب',
        'specialty': MedicalSpecialty.cardiology.value,
        'consultationFee': 300,
        'revisitFee': 150,
        'durationMinutes': 20,
        'isActive': true,
      },
      {
        'id': 'SRV-02',
        'name': 'متابعة حمل وسونار',
        'specialty': MedicalSpecialty.obstetricsGynecology.value,
        'consultationFee': 350,
        'revisitFee': 200,
        'durationMinutes': 20,
        'isActive': true,
      },
      {
        'id': 'SRV-03',
        'name': 'كشف أطفال',
        'specialty': MedicalSpecialty.pediatrics.value,
        'consultationFee': 250,
        'revisitFee': 120,
        'durationMinutes': 15,
        'isActive': true,
      },
    ];
    db.replaceCollection(
      'services',
      serviceFixtures.map((j) => MedicalServiceModel.fromJson(j).toJson()).toList(),
    );

    // 6. Patients (8 active patients)
    final patientFixtures = [
      {'id': 'PAT-000101', 'fileNumber': 'PAT-000101', 'name': 'سارة أحمد عبد الله', 'phone': '01012345678', 'gender': 'female', 'isPregnant': true, 'dateOfBirth': DateTime(1995, 5, 12).toIso8601String()},
      {'id': 'PAT-000102', 'fileNumber': 'PAT-000102', 'name': 'محمد علي حسن', 'phone': '01023456789', 'gender': 'male', 'dateOfBirth': DateTime(1988, 3, 20).toIso8601String()},
      {'id': 'PAT-000103', 'fileNumber': 'PAT-000103', 'name': 'يوسف كريم محمود', 'phone': '01034567890', 'gender': 'male', 'dateOfBirth': DateTime(2022, 7, 1).toIso8601String(), 'guardianName': 'كريم محمود', 'guardianPhone': '01034567890'},
      {'id': 'PAT-000104', 'fileNumber': 'PAT-000104', 'name': 'فاطمة الزهراء سعيد', 'phone': '01045678901', 'gender': 'female', 'dateOfBirth': DateTime(1992, 11, 8).toIso8601String()},
      {'id': 'PAT-000105', 'fileNumber': 'PAT-000105', 'name': 'عمر خالد إبراهيم', 'phone': '01056789012', 'gender': 'male', 'dateOfBirth': DateTime(1980, 1, 15).toIso8601String()},
      {'id': 'PAT-000107', 'fileNumber': 'PAT-000107', 'name': 'نور الهدى مصطفى', 'phone': '01078901234', 'gender': 'female', 'dateOfBirth': DateTime(1998, 9, 25).toIso8601String()},
      {'id': 'PAT-000108', 'fileNumber': 'PAT-000108', 'name': 'أحمد حسام الدين', 'phone': '01089012345', 'gender': 'male', 'dateOfBirth': DateTime(1975, 4, 3).toIso8601String()},
      {'id': 'PAT-000109', 'fileNumber': 'PAT-000109', 'name': 'مريم طارق جمال', 'phone': '01090123456', 'gender': 'female', 'dateOfBirth': DateTime(2001, 12, 19).toIso8601String()},
    ];
    db.replaceCollection(
      'patients',
      patientFixtures.map((j) => PatientModel.fromJson(j).toJson()).toList(),
    );

    // 7. Bookings (initial waiting queue item for today)
    final apptToday = DateTime(today.year, today.month, today.day, 10, 0);
    final bookingFixtures = [
      {
        'id': 'BOOK-001',
        'queueNumber': 1,
        'patientId': 'PAT-000101',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '01012345678',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'serviceId': 'SRV-01',
        'serviceName': 'كشف باطنة وقلب',
        'visitType': 'new_visit',
        'bookingType': 'one_time',
        'status': 'waiting',
        'paymentStatus': 'unpaid',
        'consultationFee': 300,
        'totalPrice': 300,
        'date': today.toIso8601String(),
        'appointmentTime': apptToday.toIso8601String(),
        'startTime': '10:00',
        'endTime': '10:20',
        'durationMinutes': 20,
        'branchId': 'branch_1',
      },
    ];
    db.replaceCollection(
      'bookings',
      bookingFixtures.map((j) => BookingModel.fromJson(j).toJson()).toList(),
    );
    db.replaceCollection('visits', []);
  }
}
