import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import '../../domain/repo/patients_repo.dart';
import '../models/clinical_record_models.dart';
import '../models/enums/blood_group_enum.dart';
import '../../domain/contracts/patient_balance_lookup.dart';
import '../models/enums/gender_enum.dart';
import '../models/patient_model.dart';
import '../models/patient_treatment_plan_model.dart';
import '../models/patients_response_model.dart';

class PatientsRepoImpl implements PatientsRepo {
  final ApiConsumer? apiConsumer;
  final CurrentRoleProvider? roleProvider;
  final BookingsRepo? bookingsRepo;
  final PatientBalanceLookup? balanceLookup;

  PatientsRepoImpl({
    this.apiConsumer,
    this.roleProvider,
    this.bookingsRepo,
    this.balanceLookup,
  }) {
    _seedLocalData();
  }

  final List<PatientModel> _patients = [];
  int _sequenceCounter = 109;

  late final BookingsRepo _fallbackBookingsRepo = BookingsRepoImpl();

  BookingsRepo get _effectiveBookingsRepo {
    if (bookingsRepo != null) return bookingsRepo!;
    if (getIt.isRegistered<BookingsRepo>()) {
      return getIt<BookingsRepo>();
    }
    return _fallbackBookingsRepo;
  }

  PatientBalanceLookup? get _effectiveBalanceLookup {
    if (balanceLookup != null) return balanceLookup;
    if (getIt.isRegistered<PatientBalanceLookup>()) {
      return getIt<PatientBalanceLookup>();
    }
    return null;
  }

  PatientModel _enrichWithBookingStats(PatientModel patient) {
    List<BookingModel> allBookings = const [];
    final repo = _effectiveBookingsRepo;
    if (repo is BookingsRepoImpl) {
      allBookings = repo.bookings;
    }

    final patientBookings = allBookings.where((b) {
      return (b.patientId != null && b.patientId == patient.id) ||
          (b.fileNumber != null && b.fileNumber == patient.fileNumber) ||
          (b.customer?.id != null && b.customer!.id == patient.id);
    }).toList();

    final nonCancelled = patientBookings
        .where((b) => b.status != BookingStatusEnum.cancelled)
        .toList();

    final visitsCount = nonCancelled.length;

    final lookup = _effectiveBalanceLookup;
    num totalPaid;
    num outstanding;

    if (lookup != null) {
      totalPaid = lookup.calculateTotalPaid(
        patientId: patient.id ?? '',
        fileNumber: patient.fileNumber,
      );
      outstanding = lookup.calculateOutstandingBalance(
        patientId: patient.id ?? '',
        fileNumber: patient.fileNumber,
      );
    } else {
      totalPaid = nonCancelled.fold<num>(
        0,
        (sum, b) => sum + (b.paidAmount ?? 0),
      );
      // M-5 rule: debt / outstanding is strictly from completed bookings
      final completedBookings = patientBookings
          .where((b) => b.status == BookingStatusEnum.completed)
          .toList();
      outstanding = completedBookings.fold<num>(
        0,
        (sum, b) {
          final fee = b.consultationFee ?? b.totalPrice ?? 0;
          final paid = b.paidAmount ?? 0;
          final due = fee - paid;
          return sum + (due > 0 ? due : 0);
        },
      );
    }

    final now = CairoTimeHelper.now();
    DateTime? lastVisit;
    DateTime? nextAppointment;

    for (final b in nonCancelled) {
      final apt = b.appointmentTime ?? b.date;
      if (apt != null) {
        if (!apt.isAfter(now)) {
          if (lastVisit == null || apt.isAfter(lastVisit)) {
            lastVisit = apt;
          }
        } else {
          if (nextAppointment == null || apt.isBefore(nextAppointment)) {
            nextAppointment = apt;
          }
        }
      }
    }

    return patient.copyWith(
      totalVisitsCount: visitsCount,
      totalPaidAmount: totalPaid,
      outstandingBalance: outstanding,
      lastVisitDate: lastVisit,
      nextAppointmentDate: nextAppointment,
    );
  }

  void _seedLocalData() {
    final now = CairoTimeHelper.now();

    _patients.addAll([
      // PAT-000101: سارة أحمد عبد الله (31 سنة, O+, حساسية بنسلين)
      PatientModel(
        id: 'PAT-000101',
        fileNumber: 'PAT-000101',
        name: 'سارة أحمد عبد الله',
        phone: '+201012345678',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1995, 5, 12),
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.oPositive,
        allergies: const ['حساسية بنسلين شديدة'],
        chronicDiseases: const [],
        heightCm: 165,
        weightKg: 62,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'المعادي',
        detailedAddress: 'شارع 9، عمارة 42، الدور الثالث',
        emergencyContactName: 'أحمد عبد الله (الوالد)',
        emergencyContactPhone: '+201001122334',
        emergencyContactRelation: 'relation_father',
        insuranceCompany: 'بوبا مصر',
        insurancePolicyNumber: 'BUP-2024-9812',
        insuranceCoveragePercent: 80,
        internalNotes: 'متابعة باطنة دورية وتاريخ عائلي للسكري',
        isArchived: false,
        treatmentPlans: [
          PatientTreatmentPlanModel(
            id: 'TRP-101',
            patientId: 'PAT-000101',
            serviceId: 'SRV-09',
            serviceName: 'باقة ليزر إزالة شعر - جسم كامل (6 جلسات)',
            category: 'جلدية وليزر',
            doctorName: 'د. سارة عادل',
            totalAgreedPrice: 4500,
            totalPaidAmount: 3000,
            totalSessions: 6,
            completedSessions: 4,
            paymentMode: 'flexibleInstallments',
            status: 'active',
            startDate: now.subtract(const Duration(days: 60)),
            notes: 'خطة ليزر شهرية بنظام التبريد الفائق مع رتوش مجانية بعد الجلسة الرابعة',
            sessions: [
              TreatmentSessionRecordModel(
                id: 'SES-01',
                sessionNumber: 1,
                date: now.subtract(const Duration(days: 60)),
                doctorNotes: 'جلسة ليزر أولى تجريبية واختبار حساسية الجلد - ممتازة بدون تحسس',
                performedBy: 'د. سارة عادل',
              ),
              TreatmentSessionRecordModel(
                id: 'SES-02',
                sessionNumber: 2,
                date: now.subtract(const Duration(days: 45)),
                doctorNotes: 'جلسة ثانية بكفاءة أعلى 16 جول',
                performedBy: 'د. سارة عادل',
              ),
              TreatmentSessionRecordModel(
                id: 'SES-03',
                sessionNumber: 3,
                date: now.subtract(const Duration(days: 30)),
                doctorNotes: 'جلسة ثالثة - استجابة ممتازة ونقص كثافة الشعر بنسبة 40%',
                performedBy: 'د. سارة عادل',
              ),
              TreatmentSessionRecordModel(
                id: 'SES-04',
                sessionNumber: 4,
                date: now.subtract(const Duration(days: 15)),
                doctorNotes: 'جلسة رابعة شاملة الرتوش في المناطق الحساسة',
                performedBy: 'د. سارة عادل',
              ),
            ],
            payments: [
              TreatmentPaymentRecordModel(
                id: 'PAY-01',
                amount: 2000,
                date: now.subtract(const Duration(days: 60)),
                paymentMethod: 'نقدي',
                notes: 'دفعة أولى عند فتح الخطة العلاجية',
              ),
              TreatmentPaymentRecordModel(
                id: 'PAY-02',
                amount: 1000,
                date: now.subtract(const Duration(days: 30)),
                paymentMethod: 'إنستاباي',
                notes: 'دفعة ثانية مرنة بعد الجلسة الثالثة',
              ),
            ],
          ),
        ],
        activeMedications: [
          ActiveMedicationModel(
            id: 'MED-1',
            medicationName: 'Panadol Extra 500mg',
            dosage: 'قرص واحد',
            frequency: 'عند اللزوم / الصداع الشديد',
            prescribedFor: 'مسكن للصداع وآلام الظهر',
            instructions: 'بعد الأكل مع كوب ماء كبير ولا يتكرر إلا بعد 6 ساعات',
            startDate: now.subtract(const Duration(days: 90)),
          ),
          ActiveMedicationModel(
            id: 'MED-2',
            medicationName: 'Vitamin D3 5,000 IU',
            dosage: 'كبسولة أسبوعياً',
            frequency: 'مرة واحدة كل أسبوع بعد وجبة دسمة',
            prescribedFor: 'علاج نقص فيتامين د المزمن وإجهاد العظام',
            instructions: 'الاستمرار لمدة 3 أشهر ثم إعادة فحص النسبة بالدم',
            startDate: now.subtract(const Duration(days: 45)),
          ),
        ],
        surgicalHistory: [
          SurgicalProcedureModel(
            id: 'SURG-1',
            procedureName: 'استئصال الزائدة الدودية بالمنظار (Laparoscopic Appendectomy)',
            date: DateTime(2021, 6, 14),
            hospital: 'مستشفى دار الفؤاد - السادس من أكتوبر',
            surgeonName: 'أ.د. محمد الشناوي (استشاري جراحة عامة)',
            notes: 'تمت بنجاح كامل بدون أي مضاعفات جراحية والتئام ممتاز للجرح',
          ),
          SurgicalProcedureModel(
            id: 'SURG-2',
            procedureName: 'تصحيح الإبصار بالفيمتو ليزك (Femto-LASIK Custom Refraction)',
            date: DateTime(2023, 11, 20),
            hospital: 'مركز مغربي الدولي للعيون',
            surgeonName: 'د. عبد الحميد فتحي (أخصائي طب وجراحة العيون)',
            notes: 'حدة إبصار مستقرة 6/6 لكلا العينين مع متابعة دورية لضغط وقاع العين',
          ),
        ],
        labAndRadiology: [
          LabRadiologyModel(
            id: 'LAB-1',
            title: 'صورة دم كاملة (Complete Blood Count - CBC)',
            type: 'lab',
            date: now.subtract(const Duration(days: 20)),
            centerName: 'معامل المختبر - فرع المعادي',
            requestingDoctor: 'د. حسام الدين مصطفى',
            resultSummary: 'الهيموجلوبين 12.8 g/dL (طبيعي)، كرات الدم البيضاء 6,400 (طبيعي)',
            normalRange: 'Hb: 12.0 - 15.5 g/dL | WBC: 4,000 - 11,000',
          ),
          LabRadiologyModel(
            id: 'LAB-2',
            title: 'تحليل السكر التراكمي في الدم (HbA1c Blood Test)',
            type: 'lab',
            date: now.subtract(const Duration(days: 20)),
            centerName: 'معامل البرج - فرع المعادي',
            requestingDoctor: 'د. حسام الدين مصطفى',
            resultSummary: 'النتيجة 5.4% (طبيعي وممتاز ولا يوجد مؤشر سكري)',
            normalRange: 'Normal: < 5.7% | Prediabetes: 5.7 - 6.4%',
          ),
          LabRadiologyModel(
            id: 'RAD-1',
            title: 'أشعة موجات فوق صوتية على البطن والحوض (Abdominal Ultrasound)',
            type: 'radiology',
            date: now.subtract(const Duration(days: 120)),
            centerName: 'مركز كايرو سكان للأشعة التخصصية',
            requestingDoctor: 'د. حسام الدين مصطفى',
            resultSummary: 'الكبد والكلى والمرارة والبنكرياس بحجم وبنية طبيعية، ولا توجد أي حصوات أو تضخم',
            normalRange: 'Normal organ dimensions and echogenicity',
          ),
        ],
        eyeExams: [
          EyeTrackingExamModel(
            id: 'EYE-1',
            examDate: now.subtract(const Duration(days: 15)),
            doctorName: 'د. عبد الحميد فتحي',
            iopRight: 15.0,
            iopLeft: 14.5,
            visualAcuityRight: '6/6',
            visualAcuityLeft: '6/6',
            fundusNotes: 'فحص قاع العين والشبكية والعصب البصري سليم تماماً بدون ارتشاح',
            notes: 'ضغط العين طبيعي ومستقر ومطابق للمعدل الفسيولوجي (المعدل 10-21 mmHg)',
          ),
          EyeTrackingExamModel(
            id: 'EYE-2',
            examDate: now.subtract(const Duration(days: 75)),
            doctorName: 'د. عبد الحميد فتحي',
            iopRight: 16.0,
            iopLeft: 15.5,
            visualAcuityRight: '6/6',
            visualAcuityLeft: '6/6',
            fundusNotes: 'فحص دوري بعد الليزك - القرنية صافية والتئام ممتاز للفلاب',
            notes: 'ينصح بالاستمرار على قطرات الترطيب (Hyfresh) عند استخدام الشاشات',
          ),
        ],
        beforeAfterGallery: [
          BeforeAfterGalleryItemModel(
            id: 'GAL-1',
            title: 'جلسات إزالة التصبغات وتوحيد لون البشرة ونضارة الوجه',
            specialty: 'dermatology',
            startDate: now.subtract(const Duration(days: 60)),
            latestDate: now.subtract(const Duration(days: 15)),
            totalSessionsSoFar: 4,
            doctorName: 'د. سارة عادل',
            clinicalNotes: 'تحسن ملحوظ في نقاء البشرة واختفاء التصبغات السطحية بنسبة 80% مع تجدد الكولاجين',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // PAT-000102: يوسف إبراهيم المنصوري (38 سنة, A+, سكري وضغط, مديونية 300 ج.م)
      PatientModel(
        id: 'PAT-000102',
        fileNumber: 'PAT-000102',
        name: 'يوسف إبراهيم المنصوري',
        phone: '+201123456789',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1988, 9, 23),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.aPositive,
        allergies: const [],
        chronicDiseases: const ['سكري النوع الثاني', 'ارتفاع ضغط الدم'],
        heightCm: 178,
        weightKg: 86,
        isPregnant: false,
        isNursing: false,
        governorate: 'الجيزة',
        city: 'الدقي',
        detailedAddress: 'شارع مصدق، برج الأطباء، الدور السادس',
        emergencyContactName: 'منى المنصوري (الزوجة)',
        emergencyContactPhone: '+201144556677',
        emergencyContactRelation: 'relation_spouse',
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: 0,
        internalNotes: 'عليه مديونية سابقة قدرها 300 ج.م لكشف مستعجل',
        isArchived: false,
        treatmentPlans: [
          PatientTreatmentPlanModel(
            id: 'TRP-102',
            patientId: 'PAT-000102',
            serviceId: 'SRV-11',
            serviceName: 'علاج جذور وحشو عصب ضرس سفلي (3 جلسات)',
            category: 'طب الأسنان',
            doctorName: 'د. طارق المنشاوي',
            totalAgreedPrice: 2200,
            totalPaidAmount: 1500,
            totalSessions: 3,
            completedSessions: 2,
            paymentMode: 'perSession',
            status: 'active',
            startDate: now.subtract(const Duration(days: 14)),
            notes: 'تم تعديل السعر من 1800 إلى 2200 ج.م نظراً لوجود قناة إضافية منحنية وحاجة لدعامة فايبر بوست',
            sessions: [
              TreatmentSessionRecordModel(
                id: 'SES-10',
                sessionNumber: 1,
                date: now.subtract(const Duration(days: 14)),
                doctorNotes: 'فتح الحجرة اللبية وسحب العصب وتوسيع القنوات وحشو مؤقت',
                performedBy: 'د. طارق المنشاوي',
              ),
              TreatmentSessionRecordModel(
                id: 'SES-11',
                sessionNumber: 2,
                date: now.subtract(const Duration(days: 7)),
                doctorNotes: 'تعقيم القنوات بأجهزة الروتاري وتحديد الطول الإلكتروني بدقة Apex Locator',
                performedBy: 'د. طارق المنشاوي',
              ),
            ],
            payments: [
              TreatmentPaymentRecordModel(
                id: 'PAY-10',
                amount: 1000,
                date: now.subtract(const Duration(days: 14)),
                paymentMethod: 'نقدي',
                notes: 'سداد دفعة الجلسة الأولى',
              ),
              TreatmentPaymentRecordModel(
                id: 'PAY-11',
                amount: 500,
                date: now.subtract(const Duration(days: 7)),
                paymentMethod: 'بطاقة بنكية',
                notes: 'سداد جزئي للجلسة الثانية',
              ),
            ],
          ),
        ],
        activeMedications: [
          ActiveMedicationModel(
            id: 'MED-10',
            medicationName: 'Glucophage 1,000mg (Metformin)',
            dosage: 'قرص واحد',
            frequency: 'مرتين يومياً (بعد الإفطار والعشاء)',
            prescribedFor: 'تنظيم مستوى السكر في الدم لمرضى السكري من النوع الثاني',
            instructions: 'تناول الدواء مع أو بعد الأكل مباشرة لتجنب اضطراب المعدة',
            startDate: now.subtract(const Duration(days: 360)),
          ),
          ActiveMedicationModel(
            id: 'MED-11',
            medicationName: 'Concor 5mg (Bisoprolol)',
            dosage: 'قرص واحد',
            frequency: 'مرة واحدة يومياً صباحاً',
            prescribedFor: 'تنظيم ضغط الدم ومعدل ضربات القلب',
            instructions: 'تناول الدواء في نفس الموعد يومياً صباحاً قبل الإفطار',
            startDate: now.subtract(const Duration(days: 300)),
          ),
        ],
        surgicalHistory: [
          SurgicalProcedureModel(
            id: 'SURG-10',
            procedureName: 'قسطرة قلبية تشخيصية وتركيب دعامة دوائية للشريان التاجي',
            date: DateTime(2022, 3, 10),
            hospital: 'مستشفى السلام الدولي بالمعادي',
            surgeonName: 'أ.د. شريف وجدي (استشاري قسطرة القلب والأوعية)',
            notes: 'تم تركيب دعامة دوائية بنجاح، تدفق الدم ممتاز وتوصية بالالتزام بمضادات التجلط',
          ),
        ],
        labAndRadiology: [
          LabRadiologyModel(
            id: 'LAB-10',
            title: 'تحليل السكر التراكمي في الدم (HbA1c Periodic)',
            type: 'lab',
            date: now.subtract(const Duration(days: 10)),
            centerName: 'معامل البرج - فرع الدقي',
            requestingDoctor: 'د. حسام الدين مصطفى',
            resultSummary: '7.1% (متحكم به نسبياً مع توصية بتكثيف النشاط البدني)',
            normalRange: 'Target for Diabetics: < 7.0%',
          ),
          LabRadiologyModel(
            id: 'LAB-11',
            title: 'فحص وظائف الكلى (Kidney Function Tests: Creatinine & Urea)',
            type: 'lab',
            date: now.subtract(const Duration(days: 10)),
            centerName: 'معامل البرج - فرع الدقي',
            requestingDoctor: 'د. حسام الدين مصطفى',
            resultSummary: 'الكرياتينين 1.0 mg/dL (طبيعي)، اليوريا 28 mg/dL (طبيعي)',
            normalRange: 'Creatinine: 0.7 - 1.3 mg/dL',
          ),
          LabRadiologyModel(
            id: 'RAD-10',
            title: 'أشعة بانوراما رقمية للفكين والأسنان (Digital Dental OPG)',
            type: 'radiology',
            date: now.subtract(const Duration(days: 14)),
            centerName: 'مركز الترا سكان لأشعة الأسنان',
            requestingDoctor: 'د. طارق المنشاوي',
            resultSummary: 'الضرس السفلي الأيمن رقم 46 به نخر عميق ممتد للعصب مع عظم فك سليم تماماً',
            normalRange: 'Intact bone structure without peri-apical cyst',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 240)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),

      // PAT-000103: مريم محمود حسن (10 سنوات, طفل قاصر, B-, حساسية سلفا وأسبرين, ولي أمر)
      PatientModel(
        id: 'PAT-000103',
        fileNumber: 'PAT-000103',
        name: 'مريم محمود حسن',
        phone: '+201234567890',
        phoneHasWhatsapp: false,
        dateOfBirth: DateTime(2016, 2, 15),
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.bNegative,
        allergies: const ['حساسية سلفا', 'حساسية أسبرين'],
        chronicDiseases: const [],
        heightCm: 135,
        weightKg: 32,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'مدينة نصر',
        detailedAddress: 'حي السفارات، عمارة 14',
        emergencyContactName: 'محمود حسن (الأب)',
        emergencyContactPhone: '+201288990011',
        emergencyContactRelation: 'relation_father',
        guardianName: 'محمود حسن',
        guardianPhone: '+201288990011',
        guardianRelation: 'relation_father',
        insuranceCompany: 'مصر للتأمين التكافلي',
        insurancePolicyNumber: 'MISR-CH-7741',
        insuranceCoveragePercent: 90,
        internalNotes: 'طفلة قاصرة - التواصل حصراً عبر ولي الأمر المسجل',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),

      // PAT-000104: طارق عبد الرحمن علي (56 سنة, AB+, أمراض قلب وشرايين, بوبا مصر 80%)
      PatientModel(
        id: 'PAT-000104',
        fileNumber: 'PAT-000104',
        name: 'طارق عبد الرحمن علي',
        phone: '+201545678901',
        phoneHasWhatsapp: null,
        dateOfBirth: DateTime(1970, 11, 5),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.abPositive,
        allergies: const [],
        chronicDiseases: const ['أمراض قلب وشرايين', 'قصور الشريان التاجي'],
        heightCm: 172,
        weightKg: 79,
        isPregnant: false,
        isNursing: false,
        governorate: 'القاهرة',
        city: 'التجمع الخامس',
        detailedAddress: 'شارع التسعين الشمالي، كمبوند الياسمين',
        emergencyContactName: 'كريم طارق (الابن)',
        emergencyContactPhone: '+201599887766',
        emergencyContactRelation: 'relation_child',
        insuranceCompany: 'بوبا مصر',
        insurancePolicyNumber: 'BUP-EG-99214',
        insuranceCoveragePercent: 80,
        internalNotes: 'يحتاج قياس دوري للضغط ورسم قلب قبل أي إجراء',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),

      // PAT-000105: منى فاروق الشناوي (ملف غير مكتمل, بدون تاريخ ميلاد)
      PatientModel(
        id: 'PAT-000105',
        fileNumber: 'PAT-000105',
        name: 'منى فاروق الشناوي',
        phone: '+201098765432',
        phoneHasWhatsapp: true,
        dateOfBirth: null,
        gender: GenderEnum.female,
        bloodGroup: BloodGroupEnum.unknown,
        allergies: const [],
        chronicDiseases: const [],
        heightCm: null,
        weightKg: null,
        isPregnant: null,
        isNursing: null,
        governorate: 'الجيزة',
        city: 'الشيخ زايد',
        detailedAddress: 'الحي الأول، مجاورة 2',
        emergencyContactName: null,
        emergencyContactPhone: null,
        emergencyContactRelation: null,
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: null,
        internalNotes: 'سجل مريض سابق من النظام القديم - يتطلب استكمال البيانات',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),

      // PAT-000106: خالد سعيد عبد الرازق (44 سنة, O-, ربو شعبي, مؤرشف)
      PatientModel(
        id: 'PAT-000106',
        fileNumber: 'PAT-000106',
        name: 'خالد سعيد عبد الرازق',
        phone: '+201187654321',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1982, 4, 18),
        gender: GenderEnum.male,
        bloodGroup: BloodGroupEnum.oNegative,
        allergies: const [],
        chronicDiseases: const ['ربو شعبي مزمن'],
        heightCm: 175,
        weightKg: 74,
        isPregnant: false,
        isNursing: false,
        governorate: 'الإسكندرية',
        city: 'سموحة',
        detailedAddress: 'شارع فوزي معاذ، برج النور',
        emergencyContactName: 'سعيد عبد الرازق (أخ)',
        emergencyContactPhone: '+201133221100',
        emergencyContactRelation: 'relation_sibling',
        insuranceCompany: null,
        insurancePolicyNumber: null,
        insuranceCoveragePercent: null,
        internalNotes: 'انتقل للعيش بالإسكندرية وتمت أرشفة الملف بناء على طلبه',
        isArchived: true,
        archivedAt: now.subtract(const Duration(days: 60)),
        archiveReason: 'انتقل للعيش بمحافظة الإسكندرية',
        createdAt: now.subtract(const Duration(days: 400)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),

      // PAT-000107: كريم عادل الشريف (مسجل بالاسم والهاتف فقط - شارة بيانات ناقصة)
      PatientModel(
        id: 'PAT-000107',
        fileNumber: 'PAT-000107',
        name: 'كريم عادل الشريف',
        phone: '+201066778899',
        phoneHasWhatsapp: true,
        dateOfBirth: null,
        gender: null,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),

      // PAT-000108: نادية إبراهيم سالم (أم - هاتف عائلي مشترك)
      PatientModel(
        id: 'PAT-000108',
        fileNumber: 'PAT-000108',
        name: 'نادية إبراهيم سالم',
        phone: '+201555123456',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(1990, 8, 14),
        gender: GenderEnum.female,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // PAT-000109: عمر شريف الدسوقي (طفل - يشترك في نفس هاتف الأم +201555123456)
      PatientModel(
        id: 'PAT-000109',
        fileNumber: 'PAT-000109',
        name: 'عمر شريف الدسوقي',
        phone: '+201555123456',
        phoneHasWhatsapp: true,
        dateOfBirth: DateTime(2018, 3, 20),
        gender: GenderEnum.male,
        guardianName: 'نادية إبراهيم سالم',
        guardianPhone: '+201555123456',
        guardianRelation: 'relation_mother',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    for (int i = 0; i < _patients.length; i++) {
      _patients[i] = _enrichWithBookingStats(_patients[i]);
    }
  }

  @override
  Future<Either<Failures, PatientsResponseModel>> getPatients({
    required PaginationParams params,
    String? search,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    bool? hasDebt,
    bool isArchived = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final allEnriched = _patients.map(_enrichWithBookingStats).toList();
      List<PatientModel> filtered =
          allEnriched.where((p) => (p.isArchived ?? false) == isArchived).toList();

      // Search (by explicit param or filterList)
      String? searchQuery = search;
      if (searchQuery == null || searchQuery.isEmpty) {
        for (final f in params.filterList) {
          if (f.key == 'search' && f.value != null) {
            searchQuery = f.value.toString();
            break;
          }
        }
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final normalizedQuery = EgyptianPhoneHelper.normalize(query) ?? query;

        filtered = filtered.where((p) {
          final nameMatch = (p.name ?? '').toLowerCase().contains(query);
          final phoneClean = (p.phone ?? '').replaceAll(' ', '');
          final queryClean = normalizedQuery.replaceAll(' ', '');
          final phoneMatch =
              phoneClean.contains(queryClean) ||
              (p.phone ?? '').contains(query);
          final fileMatch = (p.fileNumber ?? '').toLowerCase().contains(query);
          return nameMatch || phoneMatch || fileMatch;
        }).toList();
      }

      // Gender filter
      if (gender != null && gender != GenderEnum.unknown) {
        filtered = filtered.where((p) => p.gender == gender).toList();
      }

      // Blood group filter
      if (bloodGroup != null && bloodGroup != BloodGroupEnum.unknown) {
        filtered = filtered.where((p) => p.bloodGroup == bloodGroup).toList();
      }

      // Debt filter
      if (hasDebt == true) {
        filtered =
            filtered.where((p) => (p.outstandingBalance ?? 0) > 0).toList();
      }

      final totalCount = filtered.length;
      final limit = (params.limit ?? 10) > 0 ? (params.limit ?? 10) : 10;
      final totalPages = (totalCount / limit).ceil().clamp(1, 999);
      final page = params.page ?? 1;
      final currentPage = page.clamp(1, totalPages);

      final startIndex = (currentPage - 1) * limit;
      final paginated = startIndex < totalCount
          ? filtered.skip(startIndex).take(limit).toList()
          : <PatientModel>[];

      return Right(
        PatientsResponseModel(
          items: paginated,
          totalCount: totalCount,
          totalPages: totalPages,
          currentPage: currentPage,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب سجلات المرضى'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> getPatientById({
    required String id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      return Right(_enrichWithBookingStats(_patients[index]));
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر جلب تفاصيل المريض'));
    }
  }

  @override
  Future<Either<Failures, List<PatientModel>>> findPatientsByPhone({
    required String phone,
    String? excludePatientId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final normalized = EgyptianPhoneHelper.normalize(phone.trim());
      if (normalized == null) {
        return const Right([]);
      }

      final matches = _patients.where((p) {
        if (p.isArchived ?? false) return false;
        if (excludePatientId != null && p.id == excludePatientId) return false;
        final pPhone = EgyptianPhoneHelper.normalize(p.phone);
        return pPhone == normalized;
      }).map(_enrichWithBookingStats).toList();

      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر البحث بالهاتف'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> addPatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      // 1. Phone validation & normalization
      final rawPhone = patient.phone?.trim();
      if (rawPhone == null || rawPhone.isEmpty) {
        return Left(ValidationFailure(errMessage: 'رقم الهاتف مطلوب'));
      }

      final normalizedPhone = EgyptianPhoneHelper.normalize(rawPhone);
      if (normalizedPhone == null || !EgyptianPhoneHelper.isValid(normalizedPhone)) {
        return Left(ValidationFailure(
            errMessage: 'رقم الهاتف غير صالح، يجب أن يكون رقم هاتف مصري صحيح'));
      }

      // Check duplicate phone against active patients (warning only if allowDuplicatePhone is false)
      if (!allowDuplicatePhone) {
        final matches = _patients.where((p) {
          if (p.isArchived ?? false) return false;
          final pPhone = EgyptianPhoneHelper.normalize(p.phone);
          return pPhone == normalizedPhone;
        }).toList();

        if (matches.isNotEmpty) {
          return Left(
            DuplicatePhoneWarningFailure(
              errMessage: 'duplicate_phone_warning',
              matchingPatients: matches
                  .map((p) => DuplicatePhonePatientInfo(
                        id: p.id,
                        name: p.name,
                        fileNumber: p.fileNumber,
                        phone: p.phone,
                      ))
                  .toList(),
            ),
          );
        }
      }

      // 2. Child guardian check (< 18 requires guardian)
      if (patient.isChild()) {
        final gName = patient.guardianName?.trim();
        final gPhone = patient.guardianPhone?.trim();
        if (gName == null || gName.isEmpty || gPhone == null || gPhone.isEmpty) {
          return Left(ValidationFailure(
              errMessage:
                  'بيانات ولي الأمر (الاسم ورقم الهاتف) إلزامية للأطفال دون 18 عامًا'));
        }
      }

      // 3. Generate sequential ID & fileNumber
      _sequenceCounter++;
      final seqStr = _sequenceCounter.toString().padLeft(6, '0');
      final newId = 'PAT-$seqStr';
      final now = CairoTimeHelper.now();

      final created = patient.copyWith(
        id: newId,
        fileNumber: newId,
        phone: normalizedPhone,
        phoneHasWhatsapp: patient.phoneHasWhatsapp,
        isArchived: false,
        totalVisitsCount: 0,
        outstandingBalance: 0,
        totalPaidAmount: 0,
        createdAt: now,
        updatedAt: now,
      );

      _patients.insert(0, created);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل إضافة المريض'));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> updatePatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final existing = _patients[index];

      // 1. Phone validation & duplicate check (ignoring self)
      String updatedPhone = existing.phone ?? '';
      final candidatePhone = patient.phone?.trim();

      if (candidatePhone != null && candidatePhone.isNotEmpty) {
        final normalized = EgyptianPhoneHelper.normalize(candidatePhone);
        if (normalized == null || !EgyptianPhoneHelper.isValid(normalized)) {
          return Left(ValidationFailure(
              errMessage: 'رقم الهاتف غير صالح، يجب أن يكون رقم هاتف مصري'));
        }

        if (!allowDuplicatePhone) {
          final matches = _patients.where((p) {
            if (p.id == patient.id) return false;
            if (p.isArchived ?? false) return false;
            final pPhone = EgyptianPhoneHelper.normalize(p.phone);
            return pPhone == normalized;
          }).toList();

          if (matches.isNotEmpty) {
            return Left(
              DuplicatePhoneWarningFailure(
                errMessage: 'duplicate_phone_warning',
                matchingPatients: matches
                    .map((p) => DuplicatePhonePatientInfo(
                          id: p.id,
                          name: p.name,
                          fileNumber: p.fileNumber,
                          phone: p.phone,
                        ))
                    .toList(),
              ),
            );
          }
        }
        updatedPhone = normalized;
      }

      // 2. Child guardian check if DOB set
      final candidatePatient = existing.copyWith(
        dateOfBirth: patient.dateOfBirth ?? existing.dateOfBirth,
        guardianName: patient.guardianName ?? existing.guardianName,
        guardianPhone: patient.guardianPhone ?? existing.guardianPhone,
      );
      if (candidatePatient.isChild()) {
        final gName = candidatePatient.guardianName?.trim();
        final gPhone = candidatePatient.guardianPhone?.trim();
        if (gName == null || gName.isEmpty || gPhone == null || gPhone.isEmpty) {
          return Left(ValidationFailure(
              errMessage:
                  'بيانات ولي الأمر (الاسم ورقم الهاتف) إلزامية للأطفال دون 18 عامًا'));
        }
      }

      final updated = existing.copyWith(
        name: patient.name ?? existing.name,
        phone: updatedPhone,
        phoneHasWhatsapp: patient.phoneHasWhatsapp ?? existing.phoneHasWhatsapp,
        lastMenstrualPeriodDate: patient.lastMenstrualPeriodDate ?? existing.lastMenstrualPeriodDate,
        dateOfBirth: patient.dateOfBirth ?? existing.dateOfBirth,
        gender: patient.gender ?? existing.gender,
        bloodGroup: patient.bloodGroup ?? existing.bloodGroup,
        allergies: patient.allergies ?? existing.allergies,
        chronicDiseases: patient.chronicDiseases ?? existing.chronicDiseases,
        heightCm: patient.heightCm ?? existing.heightCm,
        weightKg: patient.weightKg ?? existing.weightKg,
        isPregnant: patient.isPregnant ?? existing.isPregnant,
        isNursing: patient.isNursing ?? existing.isNursing,
        governorate: patient.governorate ?? existing.governorate,
        city: patient.city ?? existing.city,
        detailedAddress: patient.detailedAddress ?? existing.detailedAddress,
        emergencyContactName:
            patient.emergencyContactName ?? existing.emergencyContactName,
        emergencyContactPhone:
            patient.emergencyContactPhone ?? existing.emergencyContactPhone,
        emergencyContactRelation:
            patient.emergencyContactRelation ?? existing.emergencyContactRelation,
        guardianName: patient.guardianName ?? existing.guardianName,
        guardianPhone: patient.guardianPhone ?? existing.guardianPhone,
        guardianRelation:
            patient.guardianRelation ?? existing.guardianRelation,
        insuranceCompany:
            patient.insuranceCompany ?? existing.insuranceCompany,
        insurancePolicyNumber:
            patient.insurancePolicyNumber ?? existing.insurancePolicyNumber,
        insuranceCoveragePercent:
            patient.insuranceCoveragePercent ?? existing.insuranceCoveragePercent,
        internalNotes: patient.internalNotes ?? existing.internalNotes,
        updatedAt: CairoTimeHelper.now(),
      );

      _patients[index] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تحديث بيانات المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> archivePatient({
    required String id,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final patient = _enrichWithBookingStats(_patients[index]);

      // Rejection rules: outstanding balance > 0 or upcoming appointments
      if ((patient.outstandingBalance ?? 0) > 0) {
        return Left(ValidationFailure(
            errMessage:
                'لا يمكن أرشفة ملف المريض لوجود مديونية مستحقة (${patient.outstandingBalance} ج.م)'));
      }

      final now = CairoTimeHelper.now();
      final hasUpcoming = patient.nextAppointmentDate != null &&
          patient.nextAppointmentDate!.isAfter(now);
      if (hasUpcoming) {
        return Left(ValidationFailure(
            errMessage:
                'لا يمكن أرشفة ملف المريض لوجود كشوفات قادمة مجدولة'));
      }

      _patients[index] = patient.copyWith(
        isArchived: true,
        archivedAt: now,
        archiveReason: reason ?? 'أرشفة إدارية',
        updatedAt: now,
      );

      return const Right('تم أرشفة ملف المريض بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل أرشفة ملف المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> unarchivePatient({
    required String id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }

      final patient = _enrichWithBookingStats(_patients[index]);
      _patients[index] = patient.copyWith(
        isArchived: false,
        archivedAt: null,
        archiveReason: null,
        updatedAt: CairoTimeHelper.now(),
      );

      return const Right('تم استعادة ملف المريض بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل استعادة ملف المريض'));
    }
  }

  @override
  Future<Either<Failures, String>> deletePatient({
    required String id,
  }) async {
    // Soft archive instead of permanent deletion
    return archivePatient(id: id, reason: 'حذف عبر النظام');
  }

  @override
  Future<Either<Failures, bool>> checkDuplicate({
    String? phone,
    String? excludePatientId,
  }) async {
    try {
      if (phone != null && phone.trim().isNotEmpty) {
        final normalized = EgyptianPhoneHelper.normalize(phone.trim());
        final exists = _patients.any((p) =>
            p.id != excludePatientId &&
            !(p.isArchived ?? false) &&
            EgyptianPhoneHelper.normalize(p.phone) == normalized);
        if (exists) return const Right(true);
      }

      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'تعذر التحقق من تكرار البيانات'));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> addTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      final currentPlans = List<PatientTreatmentPlanModel>.from(_patients[index].treatmentPlans ?? []);
      currentPlans.insert(0, plan);
      _patients[index] = _patients[index].copyWith(
        treatmentPlans: currentPlans,
        updatedAt: CairoTimeHelper.now(),
      );
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل إضافة الخطة العلاجية للمريض'));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> updateTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      final currentPlans = List<PatientTreatmentPlanModel>.from(_patients[index].treatmentPlans ?? []);
      final planIndex = currentPlans.indexWhere((p) => p.id == plan.id);
      if (planIndex == -1) {
        return Left(ServerFailure(errMessage: 'الخطة العلاجية غير موجودة'));
      }
      currentPlans[planIndex] = plan;
      _patients[index] = _patients[index].copyWith(
        treatmentPlans: currentPlans,
        updatedAt: CairoTimeHelper.now(),
      );
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تعديل الخطة العلاجية'));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentSession({
    required String patientId,
    required String planId,
    required TreatmentSessionRecordModel session,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      final currentPlans = List<PatientTreatmentPlanModel>.from(_patients[index].treatmentPlans ?? []);
      final planIndex = currentPlans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) {
        return Left(ServerFailure(errMessage: 'الخطة العلاجية غير موجودة'));
      }
      final targetPlan = currentPlans[planIndex];
      final newSessions = List<TreatmentSessionRecordModel>.from(targetPlan.sessions)..add(session);
      final newCompletedCount = (targetPlan.completedSessions + 1).clamp(0, targetPlan.totalSessions);
      final isNowCompleted = newCompletedCount >= targetPlan.totalSessions;
      final updatedPlan = targetPlan.copyWith(
        completedSessions: newCompletedCount,
        status: isNowCompleted ? 'completed' : targetPlan.status,
        sessions: newSessions,
      );
      currentPlans[planIndex] = updatedPlan;
      _patients[index] = _patients[index].copyWith(
        treatmentPlans: currentPlans,
        updatedAt: CairoTimeHelper.now(),
      );
      return Right(updatedPlan);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تسجيل الجلسة المنجزة'));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentPayment({
    required String patientId,
    required String planId,
    required TreatmentPaymentRecordModel payment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Left(ServerFailure(errMessage: 'المريض غير موجود'));
      }
      final currentPlans = List<PatientTreatmentPlanModel>.from(_patients[index].treatmentPlans ?? []);
      final planIndex = currentPlans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) {
        return Left(ServerFailure(errMessage: 'الخطة العلاجية غير موجودة'));
      }
      final targetPlan = currentPlans[planIndex];
      final newPayments = List<TreatmentPaymentRecordModel>.from(targetPlan.payments)..add(payment);
      final newPaidAmount = targetPlan.totalPaidAmount + payment.amount;
      final updatedPlan = targetPlan.copyWith(
        totalPaidAmount: newPaidAmount,
        payments: newPayments,
      );
      currentPlans[planIndex] = updatedPlan;
      _patients[index] = _patients[index].copyWith(
        treatmentPlans: currentPlans,
        updatedAt: CairoTimeHelper.now(),
      );
      return Right(updatedPlan);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تسجيل الدفعة المالية'));
    }
  }
}
