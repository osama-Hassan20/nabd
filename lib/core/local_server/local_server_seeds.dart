import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

/// Seeds [LocalServerDb] using JSON fixtures parsed through each model's
/// `fromJson` factory so local mode exercises real DTO deserialization.
class LocalServerSeeds {
  LocalServerSeeds._();

  static void seedAll(LocalServerDb db) {
    final now = CairoTimeHelper.now();
    final today = DateTime(now.year, now.month, now.day);

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

    // 4. Doctors (DOC-01..DOC-13), Schedules (SCHED-01..SCHED-13), Leaves (LEAVE-01..LEAVE-04)
    final doctorFixtures = [
      {'id': 'DOC-01', 'name': 'د. حسام الدين مصطفى', 'phone': '+20 10 1122 3344', 'specialty': 'باطنة وقلب', 'specialties': [MedicalSpecialty.internalMedicine.value, MedicalSpecialty.cardiology.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 4, 'upcomingBookingsCount': 6, 'completedBookingsCount': 42},
      {'id': 'DOC-02', 'name': 'د. أحمد الشافعي', 'phone': '+20 11 2233 4455', 'specialty': 'جراحة عامة ومناظير', 'specialties': [MedicalSpecialty.generalSurgery.value], 'gender': 'male', 'status': 'busy', 'todayTasksCount': 5, 'upcomingBookingsCount': 7, 'completedBookingsCount': 58},
      {'id': 'DOC-03', 'name': 'د. سارة المنشاوي', 'phone': '+20 12 3344 5566', 'specialty': 'أطفال وحديثي الولادة', 'specialties': [MedicalSpecialty.pediatrics.value], 'gender': 'female', 'status': 'on_leave', 'todayTasksCount': 0, 'upcomingBookingsCount': 2, 'completedBookingsCount': 31},
      {'id': 'DOC-04', 'name': 'د. محمود خليل', 'phone': '+20 15 4455 6677', 'specialty': 'عظام ومفاصل', 'specialties': [MedicalSpecialty.orthopedics.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 3, 'upcomingBookingsCount': 5, 'completedBookingsCount': 29},
      {'id': 'DOC-05', 'name': 'د. ريم عبد الوهاب', 'phone': '+20 10 5566 7788', 'specialty': 'جلدية وتجميل', 'specialties': [MedicalSpecialty.dermatology.value, MedicalSpecialty.cosmeticPlasticSurgery.value], 'gender': 'female', 'status': 'available', 'todayTasksCount': 6, 'upcomingBookingsCount': 8, 'completedBookingsCount': 64},
      {'id': 'DOC-06', 'name': 'د. طارق العوضي', 'phone': '+20 11 6677 8899', 'specialty': 'أنف وأذن وحنجرة', 'specialties': [MedicalSpecialty.ent.value], 'gender': 'male', 'status': 'busy', 'todayTasksCount': 4, 'upcomingBookingsCount': 6, 'completedBookingsCount': 47},
      {'id': 'DOC-07', 'name': 'د. نادية الشربيني', 'phone': '+20 10 7788 9900', 'specialty': 'نساء وتوليد', 'specialties': [MedicalSpecialty.obstetricsGynecology.value], 'gender': 'female', 'status': 'available', 'todayTasksCount': 5, 'upcomingBookingsCount': 7, 'completedBookingsCount': 50},
      {'id': 'DOC-08', 'name': 'د. كريم البنا', 'phone': '+20 11 8899 0011', 'specialty': 'أسنان وتقويم أسنان', 'specialties': [MedicalSpecialty.dentistry.value, MedicalSpecialty.orthodontics.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 4, 'upcomingBookingsCount': 5, 'completedBookingsCount': 38},
      {'id': 'DOC-09', 'name': 'د. ياسر الفقي', 'phone': '+20 12 9900 1122', 'specialty': 'عيون ورمد', 'specialties': [MedicalSpecialty.ophthalmology.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 3, 'upcomingBookingsCount': 4, 'completedBookingsCount': 22},
      {'id': 'DOC-10', 'name': 'د. هبة علام', 'phone': '+20 15 0011 2233', 'specialty': 'علاج طبيعي وتغذية علاجية', 'specialties': [MedicalSpecialty.physiotherapy.value, MedicalSpecialty.nutrition.value], 'gender': 'female', 'status': 'available', 'todayTasksCount': 3, 'upcomingBookingsCount': 3, 'completedBookingsCount': 19},
      {'id': 'DOC-11', 'name': 'د. شريف زيدان', 'phone': '+20 10 1100 2299', 'specialty': 'مسالك بولية وغدد صماء', 'specialties': [MedicalSpecialty.urology.value, MedicalSpecialty.endocrinology.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 2, 'upcomingBookingsCount': 3, 'completedBookingsCount': 15},
      {'id': 'DOC-12', 'name': 'د. دينا راشد', 'phone': '+20 11 2200 3388', 'specialty': 'مخ وأعصاب ونفسية', 'specialties': [MedicalSpecialty.neurology.value, MedicalSpecialty.psychiatry.value], 'gender': 'female', 'status': 'available', 'todayTasksCount': 2, 'upcomingBookingsCount': 2, 'completedBookingsCount': 14},
      {'id': 'DOC-13', 'name': 'د. عمر فاروق', 'phone': '+20 12 3300 4477', 'specialty': 'طب عام', 'specialties': [MedicalSpecialty.generalPractice.value, MedicalSpecialty.other.value], 'gender': 'male', 'status': 'available', 'todayTasksCount': 3, 'upcomingBookingsCount': 4, 'completedBookingsCount': 27},
    ];
    db.replaceCollection(
      'doctors',
      doctorFixtures.map((j) => DoctorModel.fromJson(j).toJson()).toList(),
    );

    final schedules = <Map<String, dynamic>>[];
    for (var i = 0; i < 13; i++) {
      if (i == 5) continue; // DOC-06 has no schedule initially
      final numStr = (i + 1).toString().padLeft(2, '0');
      final docId = 'DOC-$numStr';
      final breakStart = i == 0 ? '12:00' : '14:00';
      final breakEnd = i == 0 ? '13:00' : '15:00';
      schedules.add(DoctorScheduleModel.fromJson({
        'id': 'SCHED-$numStr',
        'doctorId': docId,
        'slotDurationMinutes': i == 1 ? 30 : (i == 2 ? 15 : 20),
        'bufferDurationMinutes': 5,
        'isAcceptingWalkIns': i != 2,
        'workDays': [
          for (final day in ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'])
            {
              'dayOfWeek': day,
              'isWorking': true,
              'startTime': '09:00',
              'endTime': '21:00',
              'breaks': [
                {'startTime': breakStart, 'endTime': breakEnd, 'title': 'استراحة'}
              ],
            },
          {'dayOfWeek': 'friday', 'isWorking': false},
        ],
      }).toJson());
    }
    db.replaceCollection('doctorSchedules', schedules);

    final leaveFixtures = [
      DoctorLeaveModel(id: 'LEAVE-01', doctorId: 'DOC-03', startDate: now.subtract(const Duration(days: 1)), endDate: now.add(const Duration(days: 2)), reason: 'إجازة سنوية اعتيادية', createdAt: now.subtract(const Duration(days: 5))).toJson(),
      DoctorLeaveModel(id: 'LEAVE-02', doctorId: 'DOC-01', startDate: now.add(const Duration(days: 10)), endDate: now.add(const Duration(days: 14)), reason: 'مؤتمر طبي تخصصي', createdAt: now.subtract(const Duration(days: 2))).toJson(),
      DoctorLeaveModel(id: 'LEAVE-03', doctorId: 'DOC-05', startDate: now.subtract(const Duration(days: 30)), endDate: now.subtract(const Duration(days: 25)), reason: 'إجازة مرضية سابقة', createdAt: now.subtract(const Duration(days: 35))).toJson(),
      DoctorLeaveModel(id: 'LEAVE-04', doctorId: 'DOC-04', startDate: now.add(const Duration(days: 12)), endDate: now.add(const Duration(days: 16)), reason: 'إجازة عائلية قادمة', createdAt: now.subtract(const Duration(days: 3))).toJson(),
    ];
    db.replaceCollection('doctorLeaves', leaveFixtures);

    // 5. Medical Services
    final serviceFixtures = [
      {'id': 'SRV-01', 'name': 'كشف باطنة وقلب', 'specialty': MedicalSpecialty.cardiology.value, 'consultationFee': 300, 'revisitFee': 150, 'durationMinutes': 20, 'isActive': true},
      {'id': 'SRV-02', 'name': 'متابعة حمل وسونار', 'specialty': MedicalSpecialty.obstetricsGynecology.value, 'consultationFee': 350, 'revisitFee': 200, 'durationMinutes': 20, 'isActive': true},
      {'id': 'SRV-03', 'name': 'كشف أطفال', 'specialty': MedicalSpecialty.pediatrics.value, 'consultationFee': 250, 'revisitFee': 120, 'durationMinutes': 15, 'isActive': true},
    ];
    db.replaceCollection(
      'services',
      serviceFixtures.map((j) => MedicalServiceModel.fromJson(j).toJson()).toList(),
    );

    // 6. Medical Catalog Items (Allergies & Chronic Diseases)
    final catalogItems = <Map<String, dynamic>>[
      const MedicalCatalogItemModel(id: 'CAT-ALL-001', name: 'بنسلين', type: 'allergy', aliases: ['بنسلين', 'penicillin', 'اموكسيسيلين', 'amoxicillin', 'اوجمنتين', 'augmentin']).toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-003', name: 'أسبرين', type: 'allergy', aliases: ['اسبرين', 'aspirin', 'ريفو', 'rivo']).toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-005', name: 'سلفا', type: 'allergy', aliases: ['سلفا', 'sulfa', 'سبترين', 'septrin']).toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-007', name: 'مضادات الالتهاب غير الستيرويدية', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-008', name: 'لاتكس', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-009', name: 'بيض', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-010', name: 'لبن', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-011', name: 'فول سوداني', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-012', name: 'مكسرات', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-013', name: 'مأكولات بحرية', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-014', name: 'غبار الطلع', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-015', name: 'غبار المنزل', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-ALL-016', name: 'لسعات الحشرات', type: 'allergy').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-001', name: 'سكري النوع الأول', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-002', name: 'سكري النوع الثاني', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-003', name: 'ارتفاع ضغط الدم', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-004', name: 'ربو شعبي مزمن', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-005', name: 'قصور الغدة الدرقية', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-006', name: 'أمراض القلب المزمنة', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-007', name: 'قصور كلوي مزمن', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-008', name: 'التهاب المفاصل الروماتويدي', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-009', name: 'الصرع', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-010', name: 'فقر الدم المزمن', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-011', name: 'هشاشة العظام', type: 'chronic_disease').toJson(),
      const MedicalCatalogItemModel(id: 'CAT-CHR-012', name: 'ارتجاع المريء المزمن', type: 'chronic_disease').toJson(),
    ];
    db.replaceCollection('medicalCatalogItems', catalogItems);

    // 7. Patients (8 active + 1 archived PAT-000106)
    final patientFixtures = [
      {'id': 'PAT-000101', 'fileNumber': 'PAT-000101', 'name': 'سارة أحمد عبد الله', 'phone': '+201012345678', 'phoneHasWhatsapp': true, 'gender': 'female', 'bloodGroup': 'o_positive', 'allergies': ['حساسية بنسلين شديدة'], 'isPregnant': true, 'dateOfBirth': DateTime(1995, 5, 12).toIso8601String(), 'isArchived': false, 'outstandingBalance': 0},
      {'id': 'PAT-000102', 'fileNumber': 'PAT-000102', 'name': 'يوسف إبراهيم المنصوري', 'phone': '+201123456789', 'phoneHasWhatsapp': true, 'gender': 'male', 'bloodGroup': 'a_positive', 'dateOfBirth': DateTime(1988, 9, 23).toIso8601String(), 'isArchived': false, 'outstandingBalance': 150},
      {'id': 'PAT-000103', 'fileNumber': 'PAT-000103', 'name': 'مريم محمود حسن', 'phone': '+201234567890', 'phoneHasWhatsapp': false, 'gender': 'female', 'bloodGroup': 'b_negative', 'allergies': ['حساسية سلفا', 'حساسية أسبرين'], 'dateOfBirth': DateTime(2016, 2, 15).toIso8601String(), 'isArchived': false, 'outstandingBalance': 0},
      {'id': 'PAT-000104', 'fileNumber': 'PAT-000104', 'name': 'طارق عبد الرحمن علي', 'phone': '+201545678901', 'gender': 'male', 'bloodGroup': 'ab_positive', 'dateOfBirth': DateTime(1970, 11, 5).toIso8601String(), 'isArchived': false, 'outstandingBalance': 0},
      {'id': 'PAT-000105', 'fileNumber': 'PAT-000105', 'name': 'منى فاروق الشناوي', 'phone': '+201098765432', 'phoneHasWhatsapp': true, 'gender': 'female', 'isArchived': false, 'outstandingBalance': 0},
      {'id': 'PAT-000106', 'fileNumber': 'PAT-000106', 'name': 'خالد سعيد عبد الرازق', 'phone': '+201187654321', 'phoneHasWhatsapp': true, 'gender': 'male', 'bloodGroup': 'o_negative', 'dateOfBirth': DateTime(1982, 4, 18).toIso8601String(), 'isArchived': true, 'archivedAt': now.subtract(const Duration(days: 30)).toIso8601String(), 'archiveReason': 'انتقل لمحافظة أخرى'},
      {'id': 'PAT-000107', 'fileNumber': 'PAT-000107', 'name': 'كريم عادل الشريف', 'phone': '+201066778899', 'phoneHasWhatsapp': true, 'isArchived': false, 'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(), 'outstandingBalance': 0},
      {'id': 'PAT-000108', 'fileNumber': 'PAT-000108', 'name': 'نادية إبراهيم سالم', 'phone': '+201555123456', 'phoneHasWhatsapp': true, 'gender': 'female', 'dateOfBirth': DateTime(1990, 8, 14).toIso8601String(), 'isArchived': false, 'createdAt': now.subtract(const Duration(days: 45)).toIso8601String(), 'outstandingBalance': 0},
      {'id': 'PAT-000109', 'fileNumber': 'PAT-000109', 'name': 'عمر شريف الدسوقي', 'phone': '+201555123456', 'phoneHasWhatsapp': true, 'gender': 'male', 'dateOfBirth': DateTime(2018, 3, 20).toIso8601String(), 'guardianName': 'نادية إبراهيم سالم', 'guardianPhone': '+201555123456', 'isArchived': false, 'outstandingBalance': 0},
    ];
    db.replaceCollection(
      'patients',
      patientFixtures.map((j) => PatientModel.fromJson(j).toJson()).toList(),
    );

    // 8. Bookings (MED-101..MED-111)
    final bookingFixtures = [
      {
        'id': 'MED-101',
        'branchId': 'branch_1',
        'queueNumber': 1,
        'patientId': 'PAT-000101',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '+201012345678',
        'fileNumber': 'PAT-000101',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'clinicRoom': 'عيادة الباطنة (غرفة 1)',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'visitType': 'new_visit',
        'status': 'in_consultation',
        'paymentStatus': 'paid',
        'consultationFee': 300,
        'paidAmount': 300,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 10)).toIso8601String(),
      },
      {
        'id': 'MED-102',
        'branchId': 'branch_1',
        'queueNumber': 2,
        'patientId': 'PAT-000102',
        'patientName': 'يوسف إبراهيم المنصوري',
        'patientPhone': '+201123456789',
        'fileNumber': 'PAT-000102',
        'doctorId': 'DOC-02',
        'doctorName': 'د. أحمد الشافعي',
        'clinicRoom': 'عيادة الأطفال (غرفة 2)',
        'specialty': 'أخصائية طب الأطفال وحديثي الولادة',
        'visitType': 'revisit',
        'status': 'waiting',
        'paymentStatus': 'unpaid',
        'consultationFee': 150,
        'paidAmount': 0,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 10, minutes: 30)).toIso8601String(),
      },
      {
        'id': 'MED-103',
        'branchId': 'branch_1',
        'queueNumber': 3,
        'patientId': 'PAT-000103',
        'patientName': 'مريم محمود حسن',
        'patientPhone': '+201234567890',
        'fileNumber': 'PAT-000103',
        'doctorId': 'DOC-03',
        'doctorName': 'د. سارة المنشاوي',
        'clinicRoom': 'عيادة العظام (غرفة 3)',
        'specialty': 'استشاري جراحة العظام والمفاصل',
        'visitType': 'emergency',
        'status': 'waiting',
        'paymentStatus': 'paid',
        'consultationFee': 450,
        'paidAmount': 450,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 11)).toIso8601String(),
      },
      {
        'id': 'MED-104',
        'branchId': 'branch_1',
        'queueNumber': 4,
        'patientId': 'PAT-000104',
        'patientName': 'طارق عبد الرحمن علي',
        'patientPhone': '+201545678901',
        'fileNumber': 'PAT-000104',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'clinicRoom': 'عيادة الباطنة (غرفة 1)',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'visitType': 'revisit',
        'status': 'completed',
        'paymentStatus': 'paid',
        'consultationFee': 150,
        'paidAmount': 150,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 9)).toIso8601String(),
      },
      {
        'id': 'MED-105',
        'branchId': 'branch_1',
        'queueNumber': 5,
        'patientId': 'PAT-000105',
        'patientName': 'منى فاروق الشناوي',
        'patientPhone': '+201098765432',
        'fileNumber': 'PAT-000105',
        'doctorId': 'DOC-04',
        'doctorName': 'د. محمود خليل',
        'clinicRoom': 'عيادة الرمد (غرفة 4)',
        'specialty': 'أخصائية طب وجراحة العيون',
        'visitType': 'new_visit',
        'status': 'postponed',
        'originalAppointmentTime': today.add(const Duration(hours: 11, minutes: 30)).toIso8601String(),
        'rescheduledTo': today.add(const Duration(days: 3, hours: 14)).toIso8601String(),
        'postponedAt': today.add(const Duration(hours: 10)).toIso8601String(),
      },
      {
        'id': 'MED-106',
        'branchId': 'branch_1',
        'queueNumber': 6,
        'patientId': 'PAT-000101',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '+201012345678',
        'fileNumber': 'PAT-000101',
        'doctorId': 'DOC-03',
        'doctorName': 'د. سارة المنشاوي',
        'clinicRoom': 'عيادة العظام (غرفة 3)',
        'specialty': 'استشاري جراحة العظام والمفاصل',
        'visitType': 'new_visit',
        'status': 'waiting',
        'paymentStatus': 'paid',
        'consultationFee': 350,
        'paidAmount': 350,
        'date': today.add(const Duration(days: 2)).toIso8601String(),
        'appointmentTime': today.add(const Duration(days: 2, hours: 12)).toIso8601String(),
      },
      {
        'id': 'MED-107',
        'branchId': 'branch_1',
        'queueNumber': 7,
        'patientId': 'PAT-000102',
        'patientName': 'يوسف إبراهيم المنصوري',
        'patientPhone': '+201123456789',
        'fileNumber': 'PAT-000102',
        'doctorId': 'DOC-02',
        'doctorName': 'د. أحمد الشافعي',
        'clinicRoom': 'عيادة الأطفال (غرفة 2)',
        'specialty': 'أخصائية طب الأطفال وحديثي الولادة',
        'visitType': 'emergency',
        'status': 'completed',
        'paymentStatus': 'partially_paid',
        'consultationFee': 300,
        'paidAmount': 150,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 9, minutes: 15)).toIso8601String(),
      },
      {
        'id': 'MED-108',
        'branchId': 'branch_2',
        'queueNumber': 8,
        'patientId': 'PAT-000103',
        'patientName': 'مريم محمود حسن',
        'patientPhone': '+201234567890',
        'fileNumber': 'PAT-000103',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'clinicRoom': 'عيادة الباطنة (غرفة 1)',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'visitType': 'new_visit',
        'status': 'waiting',
        'paymentStatus': 'paid',
        'consultationFee': 300,
        'paidAmount': 300,
        'date': today.toIso8601String(),
      },
      {
        'id': 'MED-109',
        'branchId': 'branch_1',
        'queueNumber': 9,
        'patientId': 'PAT-000104',
        'patientName': 'طارق عبد الرحمن علي',
        'patientPhone': '+201545678901',
        'fileNumber': 'PAT-000104',
        'doctorId': 'DOC-04',
        'doctorName': 'د. محمود خليل',
        'clinicRoom': 'عيادة الرمد (غرفة 4)',
        'specialty': 'أخصائية طب وجراحة العيون',
        'visitType': 'revisit',
        'status': 'waiting',
        'paymentStatus': 'paid',
        'consultationFee': 150,
        'paidAmount': 150,
        'date': today.toIso8601String(),
        'appointmentTime': today.add(const Duration(hours: 13)).toIso8601String(),
      },
    ];
    db.replaceCollection(
      'bookings',
      bookingFixtures.map((j) => BookingModel.fromJson(j).toJson()).toList(),
    );

    // 9. Visits (VIS-001..VIS-005)
    final visitFixtures = [
      {
        'id': 'VIS-001',
        'bookingId': 'MED-101',
        'patientId': 'PAT-000101',
        'branchId': 'branch_1',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '+201012345678',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'status': 'in_progress',
        'startedAt': today.add(const Duration(hours: 10)).toIso8601String(),
        'lastSavedAt': today.add(const Duration(hours: 10, minutes: 5)).toIso8601String(),
        'vitals': {
          'systolicBp': 145,
          'diastolicBp': 92,
          'heartRate': 88,
          'temperature': 37.1,
          'oxygenSaturation': 98,
          'weightKg': 72.0,
          'heightCm': 165.0,
          'recordedAt': today.add(const Duration(hours: 9, minutes: 45)).toIso8601String(),
          'recordedByUserId': 'USR-02',
        },
        'chiefComplaint': 'صداع نصفي متكرر وارتفاع في ضغط الدم منذ يومين',
        'medicalHistory': 'تاريخ عائلي لارتفاع ضغط الدم، لا توجد حساسيات دوائية معروفة',
      },
      {
        'id': 'VIS-002',
        'bookingId': 'MED-104',
        'patientId': 'PAT-000104',
        'branchId': 'branch_1',
        'patientName': 'طارق عبد الرحمن علي',
        'patientPhone': '+201545678901',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'status': 'finalized',
        'startedAt': today.add(const Duration(hours: 9)).toIso8601String(),
        'finalizedAt': today.add(const Duration(hours: 9, minutes: 25)).toIso8601String(),
        'lastSavedAt': today.add(const Duration(hours: 9, minutes: 25)).toIso8601String(),
        'chiefComplaint': 'مغص معوي حاد وإسهال متكرر منذ يومين',
        'diagnosis': 'نزلة معوية حادة مع جفاف خفيف',
        'treatmentPlan': 'محلول معالجة الجفاف + مضاد للتقلصات مع راحة تامة',
        'followUpDays': 3,
      },
      {
        'id': 'VIS-003',
        'bookingId': 'MED-107',
        'patientId': 'PAT-000102',
        'branchId': 'branch_1',
        'patientName': 'يوسف إبراهيم المنصوري',
        'patientPhone': '+201123456789',
        'doctorId': 'DOC-02',
        'doctorName': 'د. أحمد الشافعي',
        'specialty': 'أخصائي طب وجراحة العيون',
        'status': 'finalized',
        'startedAt': today.subtract(const Duration(days: 2)).toIso8601String(),
        'finalizedAt': today.subtract(const Duration(days: 2)).toIso8601String(),
        'lastSavedAt': today.subtract(const Duration(days: 2)).toIso8601String(),
        'chiefComplaint': 'ألم شديد بالحلق وصعوبة في البلع وارتفاع في درجة الحرارة',
        'diagnosis': 'التهاب حاد في اللوزتين',
        'treatmentPlan': 'مضاد حيوي مناسب للوزن + خافض حرارة عند اللزوم',
        'followUpDays': 5,
        'vitals': {
          'systolicBp': 135,
          'diastolicBp': 85,
          'heartRate': 82,
          'temperature': 38.4,
        },
      },
      {
        'id': 'VIS-004',
        'bookingId': 'MED-110',
        'patientId': 'PAT-000101',
        'branchId': 'branch_1',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '+201012345678',
        'doctorId': 'DOC-01',
        'doctorName': 'د. حسام الدين مصطفى',
        'specialty': 'استشاري أمراض باطنة وسكري',
        'status': 'finalized',
        'startedAt': today.subtract(const Duration(days: 30)).toIso8601String(),
        'finalizedAt': today.subtract(const Duration(days: 30)).toIso8601String(),
        'lastSavedAt': today.subtract(const Duration(days: 30)).toIso8601String(),
        'chiefComplaint': 'ارتفاع في ضغط الدم، صداع بالجهة الخلفية للرأس وخمول عام',
        'medicalHistory': 'تاريخ عائلي للضغط والسكري، حساسية بنسلين شديدة',
        'diagnosis': 'ارتفاع ضغط الدم الأساسي (Essential Hypertension Grade 1)',
        'treatmentPlan': 'تنظيم نمط الغذاء قليل الصوديوم، المشي اليومي، ومتابعة قياسات الضغط اليومية بالمنزل',
        'followUpDays': 14,
      },
      {
        'id': 'VIS-005',
        'bookingId': 'MED-111',
        'patientId': 'PAT-000101',
        'branchId': 'branch_1',
        'patientName': 'سارة أحمد عبد الله',
        'patientPhone': '+201012345678',
        'doctorId': 'DOC-03',
        'doctorName': 'د. عبد الحميد فتحي',
        'specialty': 'أخصائي طب وجراحة العيون',
        'status': 'finalized',
        'startedAt': today.subtract(const Duration(days: 75)).toIso8601String(),
        'finalizedAt': today.subtract(const Duration(days: 75)).toIso8601String(),
        'lastSavedAt': today.subtract(const Duration(days: 75)).toIso8601String(),
        'chiefComplaint': 'فحص دوري بعد عملية تصحيح الإبصار وجفاف خفيف بالعين مع العمل على الكمبيوتر',
        'diagnosis': 'جفاف سطحي بالعين بعد الفيمتو ليزك (Post-LASIK Dry Eye Syndrome)',
        'treatmentPlan': 'قطرات مرطبة خالية من المواد الحافظة ونظارة حماية من الشاشات الزرقاء',
        'followUpDays': 60,
        'vitals': {
          'systolicBp': 125,
          'diastolicBp': 80,
          'heartRate': 76,
        },
      },
    ];
    db.replaceCollection(
      'visits',
      visitFixtures.map((j) => VisitModel.fromJson(j).toJson()).toList(),
    );
  }
}
