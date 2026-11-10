import 'package:equatable/equatable.dart';
import '../../../../core/enums/staff_permission_enum.dart';

class RoleIds {
  static const String branchManager = 'role_branch_manager';
  static const String medicalDirector = 'role_medical_director';
  static const String doctor = 'role_doctor';
  static const String nurse = 'role_nurse';
  static const String reception = 'role_reception';
  static const String accountant = 'role_accountant';
  static const String hr = 'role_hr';
}

class RoleDefinitionModel extends Equatable {
  final String? id;
  final String? nameAr;
  final String? nameEn;
  final String? description;
  final bool? isSystemRole;
  final List<StaffPermissionEnum>? permissions;
  final num? maxDiscountPercent;
  final bool? canGrantFreeConsultation;

  const RoleDefinitionModel({
    this.id,
    this.nameAr,
    this.nameEn,
    this.description,
    this.isSystemRole,
    this.permissions,
    this.maxDiscountPercent,
    this.canGrantFreeConsultation,
  });

  RoleDefinitionModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? description,
    bool? isSystemRole,
    List<StaffPermissionEnum>? permissions,
    num? maxDiscountPercent,
    bool? canGrantFreeConsultation,
  }) {
    return RoleDefinitionModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      permissions: permissions ?? this.permissions,
      maxDiscountPercent: maxDiscountPercent ?? this.maxDiscountPercent,
      canGrantFreeConsultation:
          canGrantFreeConsultation ?? this.canGrantFreeConsultation,
    );
  }

  factory RoleDefinitionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RoleDefinitionModel();
    return RoleDefinitionModel(
      id: json['id'] as String?,
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      description: json['description'] as String?,
      isSystemRole: json['isSystemRole'] as bool?,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => StaffPermissionEnum.values.firstWhere(
                (p) => p.name == e,
                orElse: () => StaffPermissionEnum.accessLiveQueue,
              ))
          .toList(),
      maxDiscountPercent: json['maxDiscountPercent'] as num?,
      canGrantFreeConsultation: json['canGrantFreeConsultation'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'description': description,
      'isSystemRole': isSystemRole,
      'permissions': permissions?.map((p) => p.name).toList(),
      if (maxDiscountPercent != null) 'maxDiscountPercent': maxDiscountPercent,
      if (canGrantFreeConsultation != null)
        'canGrantFreeConsultation': canGrantFreeConsultation,
    };
  }

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        description,
        isSystemRole,
        permissions,
        maxDiscountPercent,
        canGrantFreeConsultation,
      ];

  static List<RoleDefinitionModel> defaultSystemRoles() {
    return const [
      // 1. Branch Manager (مدير الفرع)
      RoleDefinitionModel(
        id: RoleIds.branchManager,
        nameAr: 'مدير الفرع',
        nameEn: 'Branch Manager',
        description: 'إشراف تشغيلي وإداري ومالي شامل على مستوى الفرع المعين',
        isSystemRole: true,
        maxDiscountPercent: 100,
        canGrantFreeConsultation: true,
        permissions: [
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.createBooking,
          StaffPermissionEnum.editBooking,
          StaffPermissionEnum.cancelBooking,
          StaffPermissionEnum.reorderQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.createPatient,
          StaffPermissionEnum.editPatient,
          StaffPermissionEnum.viewVisitsQueue,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.viewConsultationNotes,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorSchedules,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.approveLeavesAndReferrals,
          StaffPermissionEnum.viewClinicalPerformance,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.refundPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.applyManualDiscount,
          StaffPermissionEnum.applyBookingDiscount,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.viewFinancialReports,
          StaffPermissionEnum.accessSettings,
          StaffPermissionEnum.manageMedicalServices,
        ],
      ),

      // 2. Medical Director (المدير الطبي)
      RoleDefinitionModel(
        id: RoleIds.medicalDirector,
        nameAr: 'المدير الطبي',
        nameEn: 'Medical Director',
        description: 'إشراف طبي وسريري واعتماد الإجازات والإحالات ومؤشرات الأداء دون الشق المالي',
        isSystemRole: true,
        permissions: [
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewVisitsQueue,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.viewConsultationNotes,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.approveLeavesAndReferrals,
          StaffPermissionEnum.viewClinicalPerformance,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.manageMedicalServices,
        ],
      ),

      // 3. Doctor (طبيب)
      RoleDefinitionModel(
        id: RoleIds.doctor,
        nameAr: 'طبيب',
        nameEn: 'Doctor',
        description: 'معاينة وفحص مرضاه وكتابة التشخيصات والروشتات وإدارة إجازاته',
        isSystemRole: true,
        permissions: [
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewVisitsQueue,
          StaffPermissionEnum.startConsultation,
          StaffPermissionEnum.recordVitals,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.viewConsultationNotes,
          StaffPermissionEnum.editMedicalDiagnosis,
          StaffPermissionEnum.issuePrescription,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.viewClinicalPerformance,
        ],
      ),

      // 4. Nurse (تمريض)
      RoleDefinitionModel(
        id: RoleIds.nurse,
        nameAr: 'تمريض',
        nameEn: 'Nurse',
        description: 'متابعة قائمة الانتظار، تسجيل القياسات الحيوية، والاطلاع على التشخيص',
        isSystemRole: true,
        permissions: [
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewVisitsQueue,
          StaffPermissionEnum.recordVitals,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
        ],
      ),

      // 5. Reception (استقبال)
      RoleDefinitionModel(
        id: RoleIds.reception,
        nameAr: 'استقبال',
        nameEn: 'Receptionist',
        description: 'إدارة الحجوزات والدور، تسجيل المرضى، وتحصيل كشوفات الخزينة',
        isSystemRole: true,
        maxDiscountPercent: 20,
        canGrantFreeConsultation: false,
        permissions: [
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.createBooking,
          StaffPermissionEnum.editBooking,
          StaffPermissionEnum.cancelBooking,
          StaffPermissionEnum.reorderQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.createPatient,
          StaffPermissionEnum.editPatient,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.applyBookingDiscount,
        ],
      ),

      // 6. Accountant (محاسب)
      RoleDefinitionModel(
        id: RoleIds.accountant,
        nameAr: 'محاسب',
        nameEn: 'Accountant',
        description: 'إدارة الخزينة والتحصيل والتقارير المالية وحسابات الأطباء',
        isSystemRole: true,
        permissions: [
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.refundPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.applyManualDiscount,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.viewFinancialReports,
        ],
      ),

      // 7. HR Specialist (مسؤول موارد بشرية)
      RoleDefinitionModel(
        id: RoleIds.hr,
        nameAr: 'مسؤول موارد بشرية',
        nameEn: 'HR Specialist',
        description: 'إدارة حسابات الطاقم، جداول وإجازات الأطباء، ومستحقات الكشوفات',
        isSystemRole: true,
        permissions: [
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorSchedules,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessSettings,
          StaffPermissionEnum.createStaffUser,
          StaffPermissionEnum.editStaffUser,
          StaffPermissionEnum.deleteStaffUser,
          StaffPermissionEnum.toggleStaffUserStatus,
        ],
      ),
    ];
  }
}

