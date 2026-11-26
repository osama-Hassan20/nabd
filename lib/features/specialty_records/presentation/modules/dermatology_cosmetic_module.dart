import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_specialty_tracking_section.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/specialty_records/presentation/widgets/sessions_and_packages_widget.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class DermatologyCosmeticModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;

  const DermatologyCosmeticModule(this.specialty);

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'area': '',
        'procedure': '',
        'deviceOrProduct': '',
        'energyOrUnits': '',
        'batchNumber': '',
        'consentSigned': false,
        'sessionIndex': 1,
        'totalSessions': 4,
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionsAndPackagesWidget(
          patientId: patient.id ?? '',
          patientName: patient.name,
          specialty: specialty,
          title: specialty == MedicalSpecialty.dermatology
              ? 'جلسات الجلدية والليزر'
              : (specialty == MedicalSpecialty.orthodontics
                  ? 'جلسات تعديل وتقويم الأسنان'
                  : 'باقات وجلسات التجميل'),
          procedureOptions: specialty == MedicalSpecialty.dermatology
              ? const ['ليزر إزالة شعر', 'تقشير كيميائي', 'فراكشنال ليزر', 'ميزوثيرابي']
              : (specialty == MedicalSpecialty.orthodontics
                  ? const ['شد سلك التقويم', 'تغيير أستيك', 'متابعة تقويم شفاف']
                  : const ['حقن بوتوكس', 'حقن فيلر', 'شد خيوط', 'متابعة جراحية']),
        ),
        const SizedBox(height: 12),
        _BeforeAfterPhotoUploadCard(
          patientId: patient.id ?? '',
          specialty: specialty,
        ),
        if (patient.beforeAfterGallery != null &&
            patient.beforeAfterGallery!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const PatientSpecialtyTrackingSection(),
        ],
      ],
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionsAndPackagesWidget(
          patientId: visit.patientId ?? '',
          patientName: visit.patientName,
          visitId: visit.id,
          doctorId: visit.doctorId,
          doctorName: visit.doctorName,
          specialty: specialty,
          title: specialty == MedicalSpecialty.dermatology
              ? 'جلسات الجلدية والليزر'
              : (specialty == MedicalSpecialty.orthodontics
                  ? 'جلسات تقويم الأسنان'
                  : 'جلسات التجميل والحقن'),
          procedureOptions: specialty == MedicalSpecialty.dermatology
              ? const ['ليزر إزالة شعر', 'تقشير كيميائي', 'ميزوثيرابي']
              : (specialty == MedicalSpecialty.orthodontics
                  ? const ['شد سلك التقويم', 'متابعة تقويم']
                  : const ['حقن بوتوكس', 'حقن فيلر', 'متابعة تجميل']),
        ),
        const SizedBox(height: 12),
        _BeforeAfterPhotoUploadCard(
          patientId: visit.patientId ?? '',
          visitId: visit.id,
          specialty: specialty,
        ),
      ],
    );
  }
}

class _BeforeAfterPhotoUploadCard extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final MedicalSpecialty specialty;

  const _BeforeAfterPhotoUploadCard({
    required this.patientId,
    this.visitId,
    required this.specialty,
  });

  @override
  State<_BeforeAfterPhotoUploadCard> createState() =>
      _BeforeAfterPhotoUploadCardState();
}

class _BeforeAfterPhotoUploadCardState
    extends State<_BeforeAfterPhotoUploadCard> {
  final _beforeCtrl = TextEditingController();
  final _afterCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<SpecialtyRecordEntryModel> _photos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: widget.specialty,
    );
    res.fold((_) {}, (list) {
      if (mounted) {
        setState(() {
          _photos = list.where((e) => e.kind == 'before_after_photo').toList();
        });
      }
    });
  }

  Future<void> _savePhotoEntry() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'before_after_photo',
        data: {
          'beforeLabel': _beforeCtrl.text.trim().isEmpty
              ? 'صورة قبل الإجراء'
              : _beforeCtrl.text.trim(),
          'afterLabel': _afterCtrl.text.trim().isEmpty
              ? 'صورة بعد الإجراء'
              : _afterCtrl.text.trim(),
          'notes': _notesCtrl.text.trim(),
          'capturedAt': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
      ),
    );
    _beforeCtrl.clear();
    _afterCtrl.clear();
    _notesCtrl.clear();
    await _load();
  }

  @override
  void dispose() {
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('before_after_photos'.tr(), style: CustomAppFontStyle.bold14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beforeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'وصف / ملف صورة قبل',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _afterCtrl,
                  decoration: const InputDecoration(
                    labelText: 'وصف / ملف صورة بعد',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _savePhotoEntry,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('إرفاق وحفظ'),
              ),
            ],
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._photos.map((p) => Text(
                  '• قبل: ${p.data['beforeLabel']} ← بعد: ${p.data['afterLabel']}',
                  style: CustomAppFontStyle.regular12,
                )),
          ],
        ],
      ),
    );
  }
}
