import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/cashier/data/models/cash_movement_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_category_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/drug_source_enum.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_profile_model.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/medical_catalogs/data/models/enums/medical_catalog_kind_enum.dart';
import 'package:eyadty/features/medical_catalogs/data/models/medical_catalog_entry_model.dart';
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
    final branchHolidays = [
      SpecialHolidayModel(id: 'HOL-01', name: 'عيد الشرطة وثورة 25 يناير', startDate: DateTime(2026, 1, 25), endDate: DateTime(2026, 1, 25)).toJson(),
      SpecialHolidayModel(id: 'HOL-02', name: 'عيد الفطر المبارك', startDate: DateTime(2026, 3, 20), endDate: DateTime(2026, 3, 23)).toJson(),
    ];
    final branchFixtures = [
      {
        'id': 'branch_1',
        'name': 'فرع المعادي',
        'nameKey': 'branch_main',
        'address': 'مصر - القاهرة، المعادي، شارع النصر',
        'phone': '+20 2 2750 8800',
        'email': 'maadi@eyadty.com',
        'isActive': true,
        'isMain': true,
        'openingTime': '09:00',
        'closingTime': '22:00',
        'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
        'specialHolidays': branchHolidays,
        'activeRoomsCount': 4,
        'staffMembersCount': 6,
      },
      {
        'id': 'branch_2',
        'name': 'فرع مدينة نصر',
        'nameKey': 'branch_second',
        'address': 'مصر - القاهرة، مدينة نصر، شارع عباس العقاد',
        'phone': '+20 2 2260 4400',
        'email': 'nasrcity@eyadty.com',
        'isActive': true,
        'isMain': false,
        'openingTime': '10:00',
        'closingTime': '23:00',
        'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
        'specialHolidays': branchHolidays,
      },
      {
        'id': 'branch_3',
        'name': 'فرع الإسكندرية (سموحة)',
        'nameKey': 'branch_alexandria',
        'address': 'ميدان فيكتور عمانويل، سموحة',
        'phone': '+20 3 4200 550',
        'isActive': false,
        'isMain': false,
        'openingTime': '12:00',
        'closingTime': '21:00',
        'workingDays': ['sunday', 'tuesday', 'thursday'],
        'specialHolidays': branchHolidays,
      },
    ];
    db.replaceCollection(
      'branches',
      branchFixtures.map((j) => BranchModel.fromJson(j).toJson()).toList(),
    );

    // 2. Per-Branch Company Settings & Friday Holiday
    final defaultHolidays = [
      SpecialHolidayModel(id: 'HOL-FRIDAY', name: 'عطلة الجمعة الأسبوعية', startDate: friday, endDate: friday).toJson(),
    ];
    db.replaceCollection('companySettings', [
      {
        ...CompanySettingsModel.fromJson({
          'id': 'SETT-001',
          'companyName': 'عيادتي التخصصية - المهندسين',
          'companyPhone': '0233001122',
          'companyAddress': 'شارع جامعة الدول العربية، المهندسين',
          'clinicType': 'polyClinic',
          'currency': 'EGP',
          'openingTime': '09:00',
          'closingTime': '22:00',
          'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
        }).toJson(),
        'branchId': 'branch_1',
        'specialHolidays': defaultHolidays,
      },
      {
        ...CompanySettingsModel.fromJson({
          'id': 'SETT-002',
          'companyName': 'عيادتي - فرع المعادي',
          'companyPhone': '0225251100',
          'companyAddress': 'شارع 9، المعادي',
          'clinicType': 'polyClinic',
          'currency': 'EGP',
          'openingTime': '10:00',
          'closingTime': '20:00',
          'workingDays': ['saturday', 'monday', 'wednesday'],
        }).toJson(),
        'branchId': 'branch_2',
        'specialHolidays': defaultHolidays,
      },
      {
        ...CompanySettingsModel.fromJson({
          'id': 'SETT-003',
          'companyName': 'عيادتي - فرع الإسكندرية (سموحة)',
          'companyPhone': '+20 3 4200 550',
          'companyAddress': 'ميدان فيكتور عمانويل، سموحة',
          'clinicType': 'polyClinic',
          'currency': 'EGP',
          'openingTime': '12:00',
          'closingTime': '21:00',
          'workingDays': ['sunday', 'tuesday', 'thursday'],
        }).toJson(),
        'branchId': 'branch_3',
        'specialHolidays': defaultHolidays,
      },
    ]);
    db.replaceCollection('settings', [db.collection('companySettings').first]);

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
        'fullName': 'د. طارق المنشاوي (المالك)',
        'email': 'owner@eyadty.com',
        'phone': '01000000001',
        'jobTitle': 'المدير التنفيذي وصاحب المنشأة',
        'isOwner': true,
        'linkedDoctorId': null,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_branch_manager']},
          {'branchId': 'branch_2', 'isPrimary': false, 'roleIds': ['role_branch_manager']},
        ],
      },
      {
        'id': 'USER-MED-DIR',
        'fullName': 'د. شريف نبيل (المدير الطبي)',
        'email': 'med_dir@eyadty.com',
        'phone': '01000000002',
        'jobTitle': 'المدير الطبي واستشاري الجودة السريرية',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_medical_director']},
        ],
      },
      {
        'id': 'USER-MGR',
        'fullName': 'م. أحمد مهران (مدير الفرع)',
        'email': 'manager@eyadty.com',
        'phone': '01000000003',
        'jobTitle': 'مدير فرع المعادي',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_branch_manager']},
        ],
      },
      {
        'id': 'USER-REC',
        'fullName': 'منى إبراهيم (استقبال)',
        'email': 'reception@eyadty.com',
        'phone': '01000000004',
        'jobTitle': 'مسؤول الاستقبال والحجوزات',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_reception']},
        ],
      },
      {
        'id': 'USER-NURSE',
        'fullName': 'فاطمة الزهراء (تمريض)',
        'email': 'nurse@eyadty.com',
        'phone': '01000000005',
        'jobTitle': 'أخصائية تمريض وعلامات حيوية',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_nurse']},
        ],
      },
      {
        'id': 'USER-ACC',
        'fullName': 'محمد كمال (محاسب)',
        'email': 'cashier@eyadty.com',
        'phone': '01000000006',
        'jobTitle': 'المحاسب المالي ومسؤول الخزينة',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_accountant']},
        ],
      },
      {
        'id': 'USER-HR',
        'fullName': 'ياسمين محمود (موارد بشرية)',
        'email': 'hr@eyadty.com',
        'phone': '01000000007',
        'jobTitle': 'مسؤول الموارد البشرية وشؤون الطاقم',
        'isOwner': false,
        'isActive': true,
        'mustChangePassword': false,
        'isDeleted': false,
        'branchAssignments': [
          {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_hr']},
        ],
      },
      for (final doc in const [
        ('DOC-01', 'د. حسام الدين مصطفى', 'doctor@eyadty.com', '+20 10 1122 3344', 'استشاري باطنة وقلب'),
        ('DOC-02', 'د. أحمد الشافعي', 'shafey@eyadty.com', '+20 11 2233 4455', 'أخصائي جراحة عامة ومناظير'),
        ('DOC-03', 'د. سارة المنشاوي', 'sara@eyadty.com', '+20 12 3344 5566', 'أخصائية طب الأطفال وحديثي الولادة'),
        ('DOC-04', 'د. محمود خليل', 'mahmoud@eyadty.com', '+20 15 4455 6677', 'استشاري جراحة العظام والمفاصل'),
        ('DOC-05', 'د. ريم عبد الوهاب', 'reem@eyadty.com', '+20 10 5566 7788', 'أخصائية جلدية وتجميل وليزر'),
        ('DOC-06', 'د. طارق العوضي', 'tarek@eyadty.com', '+20 11 6677 8899', 'استشاري جراحة الأنف والأذن والحنجرة'),
      ])
        {
          'id': 'USER-${doc.$1}',
          'fullName': doc.$2,
          'email': doc.$3,
          'phone': doc.$4,
          'jobTitle': doc.$5,
          'isOwner': false,
          'linkedDoctorId': doc.$1,
          'isActive': true,
          'mustChangePassword': false,
          'isDeleted': false,
          'branchAssignments': [
            {'branchId': 'branch_1', 'isPrimary': true, 'roleIds': ['role_doctor']},
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
      {'id': 'SRV-01', 'name': 'كشف جديد', 'specialty': MedicalSpecialty.cardiology.value, 'consultationFee': 300, 'revisitFee': 150, 'durationMinutes': 20, 'isActive': true},
      {'id': 'SRV-02', 'name': 'متابعة حمل وسونار', 'specialty': MedicalSpecialty.obstetricsGynecology.value, 'consultationFee': 350, 'revisitFee': 200, 'durationMinutes': 20, 'isActive': true},
      {'id': 'SRV-03', 'name': 'كشف أطفال', 'specialty': MedicalSpecialty.pediatrics.value, 'consultationFee': 250, 'revisitFee': 120, 'durationMinutes': 15, 'isActive': true},
      {'id': 'SRV-04', 'name': 'استشارة قلب متخصصة', 'specialty': MedicalSpecialty.cardiology.value, 'consultationFee': 400, 'revisitFee': 200, 'durationMinutes': 30, 'assignedDoctorId': 'DOC-01', 'assignedDoctorName': 'د. حسام الدين مصطفى', 'isActive': true},
      {'id': 'SRV-05', 'name': 'جراحة مناظير', 'specialty': MedicalSpecialty.generalSurgery.value, 'consultationFee': 500, 'revisitFee': 250, 'durationMinutes': 30, 'assignedDoctorId': 'DOC-02', 'assignedDoctorName': 'د. أحمد الشافعي', 'isActive': true},
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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
        'paymentStatus': 'unpaid',
        'consultationFee': 200,
        'paidAmount': 0,
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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
        'serviceId': 'SRV-01',
        'serviceName': 'كشف جديد',
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

    // 10. Medical Catalogs (Radiology, Lab Tests, Chronic Diseases, Allergies, Surgeries)
    final catalogNow = DateTime(2026, 1, 15);
    final medCatalogs = <Map<String, dynamic>>[
      for (final s in const [
        ('RAD-001', 'أشعة سينية رقمية على الصدر', 'CXR-01', 'أشعة سينية (X-Ray)', 'وضعان أمامي وخلفي لتقييم الرئتين والقلب'),
        ('RAD-002', 'أشعة سينية على العمود الفقري القطني', 'LSS-02', 'أشعة سينية (X-Ray)', 'تقييم الفقرات والانزلاق الغضروفي'),
        ('RAD-003', 'رنين مغناطيسي على المخ', 'MRI-01', 'رنين مغناطيسي (MRI)', 'بدون صبغة مع تسلسلات انتشار متقدمة'),
      ])
        MedicalCatalogEntryModel(id: s.$1, name: s.$2, code: s.$3, kind: MedicalCatalogKindEnum.radiology, category: s.$4, notes: s.$5, isActive: true, createdAt: catalogNow).toJson(),
      for (final s in const [
        ('LAB-001', 'صورة دم كاملة شاملة', 'CBC-01', 'أمراض الدم (Hematology)', 'تحليل كريات الدم والصفائح والهيموجلوبين'),
        ('LAB-002', 'سكر تراكمي في الدم', 'HBA1C-01', 'كيمياء الدم (Biochemistry)', 'معدل السكر التراكمي خلال 3 أشهر'),
      ])
        MedicalCatalogEntryModel(id: s.$1, name: s.$2, code: s.$3, kind: MedicalCatalogKindEnum.labTests, category: s.$4, notes: s.$5, isActive: true, createdAt: catalogNow).toJson(),
      for (final s in const [
        ('CHR-001', 'سكري النوع الأول', 'DM-T1', 'أمراض الغدد والسكري', 'معتمد على الأنسولين'),
        ('CHR-002', 'سكري النوع الثاني', 'DM-T2', 'أمراض الغدد والسكري', 'متابعة الحمية والأدوية الفموية'),
      ])
        MedicalCatalogEntryModel(id: s.$1, name: s.$2, code: s.$3, kind: MedicalCatalogKindEnum.chronicDiseases, category: s.$4, notes: s.$5, isActive: true, createdAt: catalogNow).toJson(),
      for (final s in const [
        ('ALL-001', 'بنسلين ومشتقات البيتالاكتام', 'MED-PEN', 'حساسية دوائية', 'صدمة تحسسية وحكة'),
        ('ALL-002', 'مركبات السلفا ومضادات السلفوناميد', 'MED-SULF', 'حساسية دوائية', 'طفح جلدي'),
      ])
        MedicalCatalogEntryModel(id: s.$1, name: s.$2, code: s.$3, kind: MedicalCatalogKindEnum.allergies, category: s.$4, notes: s.$5, isActive: true, createdAt: catalogNow).toJson(),
      for (final s in const [
        ('SUR-001', 'استئصال الزائدة الدودية بالمنظار', 'GS-APP', 'جراحة عامة ومناظير', 'تدخل طارئ'),
        ('SUR-002', 'استئصال المرارة وحصواتها بالمنظار', 'GS-CHOL', 'جراحة عامة ومناظير', 'جراحة شائعة'),
      ])
        MedicalCatalogEntryModel(id: s.$1, name: s.$2, code: s.$3, kind: MedicalCatalogKindEnum.surgeries, category: s.$4, notes: s.$5, isActive: true, createdAt: catalogNow).toJson(),
    ];
    db.replaceCollection('medicalCatalogs', medCatalogs);

    // 11. Inventory Items & Transactions
    final invItems = [
      InventoryItemModel(
        id: 'INV-DEN-01',
        name: 'كاربولات بنج موضعي (Articaine 4% + Adrenaline)',
        code: 'DEN-ANES-01',
        category: 'طب الأسنان',
        unit: 'أمبولة / كاربولة',
        currentStock: 8,
        minStockAlert: 15,
        unitCost: 28,
        shelfLocation: 'دولاب مستلزمات الأسنان - رف 1',
        expiryDate: now.add(const Duration(days: 365)),
      ).toJson(),
      InventoryItemModel(
        id: 'INV-DEN-02',
        name: 'شفرات مشارط جراحية رقم 15 معقمة',
        code: 'DEN-SCAL-15',
        category: 'طب الأسنان',
        unit: 'شفرة معقمة',
        currentStock: 25,
        minStockAlert: 10,
        unitCost: 12,
        shelfLocation: 'درج الأدوات الجراحية المعقمة',
        expiryDate: now.add(const Duration(days: 700)),
      ).toJson(),
      InventoryItemModel(
        id: 'INV-DERM-01',
        name: 'أسطوانات غاز تبريد أجهزة ليزر كانديلا (Cryogen DCD)',
        code: 'LSR-CRYO-01',
        category: 'الجلدية والليزر والتجميل',
        unit: 'أسطوانة 1000 جم',
        currentStock: 1,
        minStockAlert: 3,
        unitCost: 1250,
        shelfLocation: 'غرفة أجهزة الليزر - وحدة كانديلا',
        expiryDate: now.add(const Duration(days: 600)),
      ).toJson(),
    ];
    db.replaceCollection('inventoryItems', invItems);
    db.replaceCollection('inventoryTransactions', []);

    // 12. Drugs, Categories, Allergy Aliases & Prescription Templates
    db.replaceCollection('allergyAliases', [
      {
        'catalogItemId': 'CAT-ALL-001',
        'aliases': ['بنسلين', 'penicillin', 'اموكسيسيلين', 'amoxicillin', 'اموكسيل', 'amoxil', 'اوجمنتين', 'augmentin', 'هاي بيوتك', 'hibiotic', 'امبيسيلين', 'ampicillin'],
      },
      {
        'catalogItemId': 'CAT-ALL-003',
        'aliases': ['اسبرين', 'aspirin', 'اسبوسيد', 'aspocid', 'حمض اسيتيل ساليسيليك', 'acetylsalicylic acid', 'ريفو', 'rivo'],
      },
      {
        'catalogItemId': 'CAT-ALL-005',
        'aliases': ['سلفا', 'sulfa', 'سلفاميثوكسازول', 'sulfamethoxazole', 'سبترين', 'septrin', 'سوتريم', 'sutrim'],
      },
    ]);
    db.replaceCollection('drugCategories', [
      const DrugCategoryModel(id: 'CAT-DRUG-01', nameAr: 'المضادات الحيوية', nameEn: 'Antibiotics').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-02', nameAr: 'المسكنات ومضادات الالتهاب', nameEn: 'Analgesics & NSAIDs').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-03', nameAr: 'أدوية الجهاز الهضمي', nameEn: 'Gastrointestinal').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-04', nameAr: 'أدوية القلب والضغط', nameEn: 'Cardiovascular').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-05', nameAr: 'أدوية السكري', nameEn: 'Antidiabetics').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-06', nameAr: 'أدوية الجهاز التنفسي', nameEn: 'Respiratory').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-07', nameAr: 'مضادات الحساسية', nameEn: 'Antihistamines').toJson(),
      const DrugCategoryModel(id: 'CAT-DRUG-08', nameAr: 'الفيتامينات والمكملات', nameEn: 'Vitamins & Supplements').toJson(),
    ]);
    final drugSeedDate = now.subtract(const Duration(days: 30));
    db.replaceCollection('drugs', [
      for (final d in const [
        ('DRUG-001', 'Augmentin 1g', 'Amoxicillin / Clavulanic Acid', 'CAT-DRUG-01', '1g', 'قرص واحد', 'مرتان يومياً (كل 12 ساعة)', '7 أيام'),
        ('DRUG-002', 'Amoxil 500mg', 'Amoxicillin', 'CAT-DRUG-01', '500mg', 'كبسولة واحدة', '3 مرات يومياً (كل 8 ساعات)', '7 أيام'),
        ('DRUG-003', 'Hibiotic 1g', 'Amoxicillin / Clavulanic Acid', 'CAT-DRUG-01', '1g', 'قرص واحد', 'مرتان يومياً (كل 12 ساعة)', '7 أيام'),
        ('DRUG-004', 'Septrin', 'Sulfamethoxazole / Trimethoprim', 'CAT-DRUG-01', '480mg', 'قرص واحد', 'مرتان يومياً (كل 12 ساعة)', '5 أيام'),
        ('DRUG-005', 'Sutrim', 'Sulfamethoxazole / Trimethoprim', 'CAT-DRUG-01', '400mg/80mg', 'قرص واحد', 'مرتان يومياً (كل 12 ساعة)', '5 أيام'),
        ('DRUG-006', 'Zithrokan 500mg', 'Azithromycin', 'CAT-DRUG-01', '500mg', 'كبسولة واحدة', 'مرة واحدة يومياً', '3 أيام'),
        ('DRUG-007', 'Ciprodar 500mg', 'Ciprofloxacin', 'CAT-DRUG-01', '500mg', 'قرص واحد', 'مرتان يومياً (كل 12 ساعة)', '7 أيام'),
        ('DRUG-008', 'Cataflam 50mg', 'Diclofenac Potassium', 'CAT-DRUG-02', '50mg', 'قرص واحد', 'عند اللزوم', '5 أيام'),
        ('DRUG-009', 'Brufen 400mg', 'Ibuprofen', 'CAT-DRUG-02', '400mg', 'قرص واحد', '3 مرات يومياً (بعد الأكل)', '5 أيام'),
        ('DRUG-010', 'Panadol Extra', 'Paracetamol / Caffeine', 'CAT-DRUG-02', '500mg/65mg', 'قرصان', 'عند اللزوم', '3 أيام'),
        ('DRUG-011', 'Aspocid 75mg', 'Acetylsalicylic Acid', 'CAT-DRUG-02', '75mg', 'قرص واحد', 'مرة واحدة يومياً', 'مستمر (علاج مزمن)'),
        ('DRUG-012', 'Ketofan 50mg', 'Ketoprofen', 'CAT-DRUG-02', '50mg', 'كبسولة واحدة', 'مرتان يومياً (بعد الأكل)', '5 أيام'),
        ('DRUG-013', 'Omeprazole 20mg', 'Omeprazole', 'CAT-DRUG-03', '20mg', 'كبسولة واحدة', 'مرة واحدة يومياً (قبل الأكل)', '14 يوماً'),
        ('DRUG-014', 'Controloc 40mg', 'Pantoprazole', 'CAT-DRUG-03', '40mg', 'قرص واحد', 'مرة واحدة يومياً (قبل الإفطار)', '14 يوماً'),
        ('DRUG-015', 'Motinorm 10mg', 'Domperidone', 'CAT-DRUG-03', '10mg', 'قرص واحد', '3 مرات يومياً (قبل الأكل)', '5 أيام'),
        ('DRUG-016', 'Visceralgine', 'Tiemonium Methylsulfate', 'CAT-DRUG-03', '50mg', 'قرص واحد', '3 مرات يومياً', '5 أيام'),
        ('DRUG-017', 'Concor 5mg', 'Bisoprolol Fumarate', 'CAT-DRUG-04', '5mg', 'قرص واحد', 'مرة واحدة يومياً (صباحاً)', 'مستمر (علاج مزمن)'),
        ('DRUG-018', 'Capoten 25mg', 'Captopril', 'CAT-DRUG-04', '25mg', 'نصف قرص', 'مرتان يومياً', 'مستمر (علاج مزمن)'),
        ('DRUG-019', 'Norvasc 5mg', 'Amlodipine', 'CAT-DRUG-04', '5mg', 'قرص واحد', 'مرة واحدة يومياً', 'مستمر (علاج مزمن)'),
        ('DRUG-020', 'Glucophage 1000mg', 'Metformin Hydrochloride', 'CAT-DRUG-05', '1000mg', 'قرص واحد', 'مرتان يومياً (مع الأكل)', 'مستمر (علاج مزمن)'),
        ('DRUG-021', 'Amaryl 2mg', 'Glimepiride', 'CAT-DRUG-05', '2mg', 'قرص واحد', 'مرة واحدة يومياً (قبل الإفطار)', 'مستمر (علاج مزمن)'),
        ('DRUG-022', 'Ventolin Inhaler', 'Salbutamol', 'CAT-DRUG-06', '100mcg/dose', 'بختان', 'عند اللزوم', 'مستمر (علاج مزمن)'),
        ('DRUG-023', 'Zyrtec 10mg', 'Cetirizine Dihydrochloride', 'CAT-DRUG-07', '10mg', 'قرص واحد', 'مرة واحدة يومياً (مساءً)', '7 أيام'),
        ('DRUG-024', 'Claritine 10mg', 'Loratadine', 'CAT-DRUG-07', '10mg', 'قرص واحد', 'مرة واحدة يومياً', '10 أيام'),
        ('DRUG-025', 'Neurobion', 'Vitamin B1, B6, B12', 'CAT-DRUG-08', 'Forte', 'قرص واحد', 'مرة واحدة يومياً', 'شهر واحد'),
      ])
        DrugModel(
          id: d.$1,
          name: d.$2,
          scientificName: d.$3,
          categoryId: d.$4,
          concentration: d.$5,
          defaultDosage: d.$6,
          defaultFrequency: d.$7,
          defaultDuration: d.$8,
          isActive: true,
          source: DrugSourceEnum.preset,
          reviewStatus: ReviewStatusEnum.approved,
          createdAt: drugSeedDate,
        ).toJson(),
    ]);
    db.replaceCollection('prescriptionTemplates', [
      PrescriptionTemplateModel(
        id: 'TPL-001',
        doctorId: 'DOC-01',
        name: 'بروتوكول نزلة معوية',
        isActive: true,
        createdAt: drugSeedDate,
        updatedAt: drugSeedDate,
        items: const [
          PrescriptionTemplateItemModel(drugId: 'DRUG-015', drugName: 'Motinorm 10mg', scientificName: 'Domperidone', concentration: '10mg', dosage: 'قرص واحد', frequency: '3 مرات يومياً (قبل الأكل)', duration: '5 أيام', orderIndex: 0),
        ],
      ).toJson(),
      PrescriptionTemplateModel(
        id: 'TPL-002',
        doctorId: 'DOC-01',
        name: 'بروتوكول نزلة شعبية',
        isActive: true,
        createdAt: drugSeedDate,
        updatedAt: drugSeedDate,
        items: const [
          PrescriptionTemplateItemModel(drugId: 'DRUG-001', drugName: 'Augmentin 1g', scientificName: 'Amoxicillin / Clavulanic Acid', concentration: '1g', dosage: 'قرص واحد', frequency: 'مرتان يومياً (كل 12 ساعة)', duration: '7 أيام', orderIndex: 0),
          PrescriptionTemplateItemModel(drugId: 'DRUG-022', drugName: 'Ventolin Inhaler', scientificName: 'Salbutamol', concentration: '100mcg/dose', dosage: 'بختان', frequency: 'عند اللزوم', duration: 'مستمر (علاج مزمن)', orderIndex: 1),
        ],
      ).toJson(),
      PrescriptionTemplateModel(
        id: 'TPL-003',
        doctorId: 'DOC-02',
        name: 'بروتوكول حساسية موسمية',
        isActive: true,
        createdAt: drugSeedDate,
        updatedAt: drugSeedDate,
        items: const [
          PrescriptionTemplateItemModel(drugId: 'DRUG-023', drugName: 'Zyrtec 10mg', scientificName: 'Cetirizine Dihydrochloride', concentration: '10mg', dosage: 'قرص واحد', frequency: 'مرة واحدة يومياً (مساءً)', duration: '7 أيام', orderIndex: 0),
        ],
      ).toJson(),
    ]);

    final cashierToday = DateTime(now.year, now.month, now.day);
    db.replaceCollection('cashierShifts', [
      CashierShiftModel(
        id: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        status: ShiftStatusEnum.open,
        openedAt: now.subtract(const Duration(hours: 4)),
        businessDate: cashierToday,
        openingBalancePiastres: 100000,
        expectedCashPiastres: 205000,
        totalCashCollectedPiastres: 120000,
        totalCardCollectedPiastres: 65000,
        totalBankTransferPiastres: 0,
        totalExpensesPiastres: 15000,
        totalRefundsPiastres: 0,
        totalCapitalInjectionsPiastres: 0,
        totalBankDepositsPiastres: 0,
        totalOwnerWithdrawalsPiastres: 0,
        transactionCount: 8,
      ).toJson(),
      CashierShiftModel(
        id: 'SHIFT-NASR-01',
        branchId: 'branch_2',
        cashierUserId: 'USER-REC-2',
        cashierName: 'هدى مصطفى',
        status: ShiftStatusEnum.open,
        openedAt: now.subtract(const Duration(hours: 3)),
        businessDate: cashierToday,
        openingBalancePiastres: 50000,
        expectedCashPiastres: 50000,
        totalCashCollectedPiastres: 0,
        totalCardCollectedPiastres: 0,
        totalBankTransferPiastres: 30000,
        totalExpensesPiastres: 0,
        totalRefundsPiastres: 0,
        totalCapitalInjectionsPiastres: 0,
        totalBankDepositsPiastres: 0,
        totalOwnerWithdrawalsPiastres: 0,
        transactionCount: 1,
      ).toJson(),
      CashierShiftModel(
        id: 'SHIFT-TAG-01',
        branchId: 'branch_3',
        cashierUserId: 'USER-REC-TAG',
        cashierName: 'سارة العزازي',
        status: ShiftStatusEnum.open,
        openedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        businessDate: cashierToday,
        openingBalancePiastres: 50000,
        expectedCashPiastres: 50000,
        totalCashCollectedPiastres: 0,
        totalCardCollectedPiastres: 0,
        totalBankTransferPiastres: 0,
        totalExpensesPiastres: 0,
        totalRefundsPiastres: 0,
        totalCapitalInjectionsPiastres: 0,
        totalBankDepositsPiastres: 0,
        totalOwnerWithdrawalsPiastres: 0,
        transactionCount: 0,
      ).toJson(),
    ]);

    db.replaceCollection('cashierPayments', [
      PaymentTransactionModel(
        id: 'PAY-CAI-01',
        clientRequestId: 'REQ-SEED-101',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.card,
        referenceNumber: 'POS-89214',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 50)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-02',
        clientRequestId: 'REQ-SEED-103',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-103',
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        amountPiastres: 45000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-03',
        clientRequestId: 'REQ-SEED-104',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-104',
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-04',
        clientRequestId: 'REQ-SEED-106',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-106',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 35000,
        paymentMethod: PaymentMethod.card,
        referenceNumber: 'POS-89222',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-05',
        clientRequestId: 'REQ-SEED-107',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-107',
        patientId: 'PAT-000102',
        patientName: 'يوسف إبراهيم المنصوري',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-06',
        clientRequestId: 'REQ-SEED-109',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-109',
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-CAI-07',
        clientRequestId: 'REQ-SEED-111',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-111',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
      PaymentTransactionModel(
        id: 'PAY-NASR-01',
        clientRequestId: 'REQ-SEED-108',
        shiftId: 'SHIFT-NASR-01',
        branchId: 'branch_2',
        bookingId: 'MED-108',
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.bankTransfer,
        referenceNumber: 'INSTA-99120',
        cashierUserId: 'USER-REC-2',
        cashierName: 'هدى مصطفى',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ).toJson(),
    ]);

    db.replaceCollection('cashierMovements', [
      CashMovementModel(
        id: 'CSM-CAI-01',
        clientRequestId: 'REQ-SEED-CSM-01',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense,
        amountPiastres: 15000,
        reason: 'شراء مستلزمات ضيافة ومياه للعيادة',
        recipientName: 'عامل الخدمات',
        performedByUserId: 'USER-REC',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 45)),
      ).toJson(),
    ]);

    db.replaceCollection('cashierRefunds', []);
    db.replaceCollection('cashierIdempotency', []);

    final hrEffectiveBase = DateTime(now.year, 1, 1);
    db.replaceCollection('hrCompensationRules', [
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-02',
        doctorId: 'DOC-02',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryPlusPercentage,
        monthlyBaseSalaryPiastres: 1000000,
        commissionPercentage: 30,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-03',
        doctorId: 'DOC-03',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-04',
        doctorId: 'DOC-04',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-05',
        doctorId: 'DOC-05',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: 1500000,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-06',
        doctorId: 'DOC-06',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: hrEffectiveBase,
        createdAt: hrEffectiveBase,
        isActive: true,
      ).toJson(),
    ]);

    db.replaceCollection('hrPayrollProfiles', [
      const StaffPayrollProfileModel(
        id: 'PRF-001',
        staffUserId: 'usr_reception_1',
        fullName: 'سارة أحمد',
        jobTitle: 'موظف استقبال',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 600000,
        housingAllowancePiastres: 50000,
        transportationAllowancePiastres: 50000,
        insuranceDeductionPiastres: 40000,
        taxDeductionPiastres: 20000,
        isActive: true,
      ).toJson(),
      const StaffPayrollProfileModel(
        id: 'PRF-002',
        staffUserId: 'usr_nurse_1',
        fullName: 'مريم علي',
        jobTitle: 'تمريض أول',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 750000,
        housingAllowancePiastres: 60000,
        transportationAllowancePiastres: 60000,
        insuranceDeductionPiastres: 50000,
        taxDeductionPiastres: 25000,
        isActive: true,
      ).toJson(),
      const StaffPayrollProfileModel(
        id: 'PRF-003',
        staffUserId: 'usr_accountant_1',
        fullName: 'أحمد محمود',
        jobTitle: 'محاسب مالي',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 900000,
        housingAllowancePiastres: 80000,
        transportationAllowancePiastres: 80000,
        insuranceDeductionPiastres: 60000,
        taxDeductionPiastres: 35000,
        isActive: true,
      ).toJson(),
    ]);

    final hrPastMonthStart = DateTime(now.year, now.month - 1, 1);
    final hrPastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    db.replaceCollection('hrSettlements', [
      DoctorSettlementModel(
        id: 'SET-SEED-001',
        settlementNumber:
            'SET-DOC-${now.year}${(now.month - 1).toString().padLeft(2, '0')}-001',
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد خالد',
        branchId: 'branch_1',
        periodStart: hrPastMonthStart,
        periodEnd: hrPastMonthEnd,
        status: SettlementStatusEnum.paid,
        totalVisitsCount: 15,
        totalNetRevenuePiastres: 450000,
        totalDoctorCommissionPiastres: 225000,
        totalClinicSharePiastres: 225000,
        baseSalaryPiastres: 0,
        totalBonusesPiastres: 0,
        totalDeductionsPiastres: 0,
        totalAdvancesDeductedPiastres: 0,
        netPayablePiastres: 225000,
        confirmedByUserId: 'usr_owner_1',
        confirmedAt: hrPastMonthEnd.add(const Duration(days: 1)),
        paidAt: hrPastMonthEnd.add(const Duration(days: 2)),
        paymentMethod: PaymentMethod.bankTransfer,
        source: 'mockSeed',
        createdAt: hrPastMonthEnd,
      ).toJson(),
    ]);

    db.replaceCollection('hrLedgerEntries', []);
    db.replaceCollection('hrPayrollPeriods', []);
  }
}
