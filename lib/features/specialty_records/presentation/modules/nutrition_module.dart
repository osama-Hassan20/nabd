import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/specialty_records/presentation/widgets/sessions_and_packages_widget.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class NutritionModule implements SpecialtyRecordModule {
  const NutritionModule();

  @override
  MedicalSpecialty get specialty => MedicalSpecialty.nutrition;

  @override
  String get tabLabelKey => specialty.labelKey;

  static double? computeBmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
      return null;
    }
    final m = heightCm / 100.0;
    return double.parse((weightKg / (m * m)).toStringAsFixed(1));
  }

  static String bmiCategoryAr(double? bmi) {
    if (bmi == null) return 'غير محدد';
    if (bmi < 18.5) return 'نقص وزن';
    if (bmi < 25.0) return 'وزن طبيعي';
    if (bmi < 30.0) return 'زيادة وزن';
    return 'سمنة';
  }

  @override
  Map<String, dynamic> emptyEntry() => {
        'weightKg': null,
        'heightCm': null,
        'bmi': null,
        'bmiCategory': '',
        'waistCm': null,
        'hipCm': null,
        'bodyFatPercent': null,
        'targetCalories': 1800,
        'proteinGrams': 110,
        'carbsGrams': 180,
        'fatGrams': 60,
        'intolerances': '',
        'supplements': '',
        'mealPlanNotes': '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) {
    final errors = <String>[];
    final w = entry['weightKg'] as num?;
    final h = entry['heightCm'] as num?;
    if (w != null && (w <= 0 || w > 350)) {
      errors.add('الوزن غير صالح');
    }
    if (h != null && (h <= 30 || h > 250)) {
      errors.add('الطول غير صالح');
    }
    return errors;
  }

  @override
  Widget buildPatientTab(PatientModel patient) {
    return _NutritionRecordWidget(
      patientId: patient.id ?? '',
      patientName: patient.name,
      patient: patient,
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _NutritionRecordWidget(
      patientId: visit.patientId ?? '',
      patientName: visit.patientName,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      initialWeight: visit.vitals?.weightKg?.toDouble(),
      initialHeight: visit.vitals?.heightCm?.toDouble(),
    );
  }
}

class _NutritionRecordWidget extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? visitId;
  final String? doctorId;
  final String? doctorName;
  final PatientModel? patient;
  final double? initialWeight;
  final double? initialHeight;

  const _NutritionRecordWidget({
    required this.patientId,
    this.patientName,
    this.visitId,
    this.doctorId,
    this.doctorName,
    this.patient,
    this.initialWeight,
    this.initialHeight,
  });

  @override
  State<_NutritionRecordWidget> createState() => _NutritionRecordWidgetState();
}

class _NutritionRecordWidgetState extends State<_NutritionRecordWidget> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController(text: '1800');
  final _proteinCtrl = TextEditingController(text: '110');
  final _carbsCtrl = TextEditingController(text: '180');
  final _fatCtrl = TextEditingController(text: '60');
  final _intolerancesCtrl = TextEditingController();
  final _supplementsCtrl = TextEditingController();
  final _mealPlanCtrl = TextEditingController();

  PatientModel? _patient;
  List<SpecialtyRecordEntryModel> _entries = [];
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    if (widget.initialWeight != null) {
      _weightCtrl.text = widget.initialWeight.toString();
    } else if (_patient?.weightKg != null) {
      _weightCtrl.text = _patient!.weightKg.toString();
    }
    if (widget.initialHeight != null) {
      _heightCtrl.text = widget.initialHeight.toString();
    } else if (_patient?.heightCm != null) {
      _heightCtrl.text = _patient!.heightCm.toString();
    }
    _load();
  }

  Future<void> _load() async {
    if (_patient == null &&
        widget.patientId.isNotEmpty &&
        getIt.isRegistered<PatientsRepo>()) {
      final pRes = await getIt<PatientsRepo>().getPatientById(id: widget.patientId);
      pRes.fold((_) {}, (p) {
        if (mounted) setState(() => _patient = p);
      });
    }
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: MedicalSpecialty.nutrition,
    );
    res.fold((_) {}, (list) {
      if (mounted) {
        setState(() {
          _entries =
              list.where((e) => e.kind == 'nutrition_measurement').toList();
        });
      }
    });
  }

  Future<void> _saveMeasurement() async {
    final hasAny = _weightCtrl.text.trim().isNotEmpty ||
        _heightCtrl.text.trim().isNotEmpty ||
        _waistCtrl.text.trim().isNotEmpty ||
        _hipCtrl.text.trim().isNotEmpty ||
        _bodyFatCtrl.text.trim().isNotEmpty ||
        _intolerancesCtrl.text.trim().isNotEmpty ||
        _supplementsCtrl.text.trim().isNotEmpty ||
        _mealPlanCtrl.text.trim().isNotEmpty;
    if (!hasAny) {
      setState(() {
        _validationError = 'يرجى إدخال قياس أو خطة غذائية قبل الحفظ.';
      });
      return;
    }
    setState(() => _validationError = null);
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    final bmi = NutritionModule.computeBmi(w, h);
    final category = NutritionModule.bmiCategoryAr(bmi);

    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.nutrition,
      kind: 'nutrition_measurement',
      data: {
        'weightKg': w,
        'heightCm': h,
        'bmi': bmi,
        'bmiCategory': category,
        'waistCm': double.tryParse(_waistCtrl.text.trim()),
        'hipCm': double.tryParse(_hipCtrl.text.trim()),
        'bodyFatPercent': double.tryParse(_bodyFatCtrl.text.trim()),
        'targetCalories': int.tryParse(_caloriesCtrl.text.trim()),
        'proteinGrams': int.tryParse(_proteinCtrl.text.trim()),
        'carbsGrams': int.tryParse(_carbsCtrl.text.trim()),
        'fatGrams': int.tryParse(_fatCtrl.text.trim()),
        'intolerances': _intolerancesCtrl.text.trim(),
        'supplements': _supplementsCtrl.text.trim(),
        'mealPlanNotes': _mealPlanCtrl.text.trim(),
      },
      createdAt: DateTime.now(),
    );

    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _bodyFatCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _intolerancesCtrl.dispose();
    _supplementsCtrl.dispose();
    _mealPlanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    final liveBmi = NutritionModule.computeBmi(w, h);
    final bmiCat = NutritionModule.bmiCategoryAr(liveBmi);
    final allergies = _patient?.allergies ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ملف التغذية العلاجية', style: CustomAppFontStyle.bold14),
                  ),
                  if (liveBmi != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'مؤشر الكتلة: $liveBmi ($bmiCat)',
                        style: CustomAppFontStyle.semiBold12
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              if (allergies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تحذير حساسية غذائية/دوائية مسجلة: ${allergies.join('، ')}',
                          style: CustomAppFontStyle.semiBold12.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'الوزن (كجم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'الطول (سم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _waistCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الخصر (سم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hipCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الأرداف (سم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _bodyFatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'نسبة الدهون %',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_validationError != null) ...[
                Text(
                  _validationError!,
                  style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعرات المستهدفة',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'بروتين (جم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _carbsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'كربوهيدرات (جم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دهون (جم)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_validationError != null) ...[
                Text(
                  _validationError!,
                  style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _intolerancesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'حساسيات أو عدم تحمل غذائي',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _supplementsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'المكملات الغذائية',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_validationError != null) ...[
                Text(
                  _validationError!,
                  style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mealPlanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات الخطة الغذائية',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saveMeasurement,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('حفظ القياس والخطة'),
                  ),
                ],
              ),
              if (_entries.isNotEmpty) ...[
                const Divider(height: 20),
                Text('سجل المتابعة والاتجاه (${_entries.length}):',
                    style: CustomAppFontStyle.semiBold13),
                const SizedBox(height: 6),
                ..._entries.asMap().entries.map((item) {
                  final idx = item.key;
                  final e = item.value;
                  final weight = (e.data['weightKg'] as num?)?.toDouble();
                  final prevWeight = idx + 1 < _entries.length
                      ? (_entries[idx + 1].data['weightKg'] as num?)?.toDouble()
                      : null;
                  String deltaStr = '';
                  if (weight != null && prevWeight != null) {
                    final diff = weight - prevWeight;
                    final sign = diff > 0 ? '+' : '';
                    deltaStr = ' ($sign${diff.toStringAsFixed(1)} كجم)';
                  }
                  return Text(
                    '• الوزن: ${e.data['weightKg'] ?? '-'} كجم$deltaStr | BMI: ${e.data['bmi'] ?? '-'} (${e.data['bmiCategory'] ?? '-'}) | سعرات: ${e.data['targetCalories'] ?? '-'}',
                    style: CustomAppFontStyle.regular12,
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SessionsAndPackagesWidget(
          patientId: widget.patientId,
          patientName: widget.patientName,
          visitId: widget.visitId,
          doctorId: widget.doctorId,
          doctorName: widget.doctorName,
          specialty: MedicalSpecialty.nutrition,
          title: 'جلسات وباقات متابعة التغذية',
          procedureOptions: const ['خطة إنقاص وزن', 'خطة تغذية رياضية', 'متابعة تغذية علاجية'],
        ),
      ],
    );
  }
}
