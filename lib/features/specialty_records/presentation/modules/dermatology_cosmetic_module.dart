import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  String? _beforePath;
  String? _afterPath;
  Uint8List? _beforeBytes;
  Uint8List? _afterBytes;
  String? _validationError;
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

  Future<void> _pickImage(bool isBefore) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (isBefore) {
          _beforePath = file.path;
          _beforeBytes = bytes;
          _beforeCtrl.text = file.name;
        } else {
          _afterPath = file.path;
          _afterBytes = bytes;
          _afterCtrl.text = file.name;
        }
        _validationError = null;
      });
    } catch (_) {}
  }

  Future<void> _savePhotoEntry() async {
    final hasAny = _beforeBytes != null ||
        _afterBytes != null ||
        (_beforePath != null && _beforePath!.isNotEmpty) ||
        (_afterPath != null && _afterPath!.isNotEmpty) ||
        _beforeCtrl.text.trim().isNotEmpty ||
        _afterCtrl.text.trim().isNotEmpty;
    if (!hasAny) {
      setState(() {
        _validationError = 'يرجى إرفاق صورة أو وصف واحد على الأقل قبل الحفظ.';
      });
      return;
    }
    setState(() => _validationError = null);
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'before_after_photo',
        data: {
          'beforeLabel': _beforeCtrl.text.trim(),
          'afterLabel': _afterCtrl.text.trim(),
          if (_beforePath != null) 'beforePath': _beforePath,
          if (_afterPath != null) 'afterPath': _afterPath,
          if (_beforeBytes != null) 'beforeBase64': base64Encode(_beforeBytes!),
          if (_afterBytes != null) 'afterBase64': base64Encode(_afterBytes!),
          'capturedAt': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
      ),
    );
    _beforeCtrl.clear();
    _afterCtrl.clear();
    _beforePath = null;
    _afterPath = null;
    _beforeBytes = null;
    _afterBytes = null;
    await _load();
  }

  Widget _buildThumbnail(String? b64) {
    if (b64 == null || b64.isEmpty) return const SizedBox.shrink();
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(b64),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
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
              if (_beforeBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    _beforeBytes!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: TextField(
                  controller: _beforeCtrl,
                  decoration: InputDecoration(
                    labelText: 'صورة قبل',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: 'اختيار صورة قبل',
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      onPressed: () => _pickImage(true),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_afterBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    _afterBytes!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: TextField(
                  controller: _afterCtrl,
                  decoration: InputDecoration(
                    labelText: 'صورة بعد',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: 'اختيار صورة بعد',
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      onPressed: () => _pickImage(false),
                    ),
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
          if (_validationError != null) ...[
            const SizedBox(height: 6),
            Text(
              _validationError!,
              style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
            ),
          ],
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._photos.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      _buildThumbnail(p.data['beforeBase64']?.toString()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'قبل: ${p.data['beforeLabel'] ?? '-'} ← بعد: ${p.data['afterLabel'] ?? '-'}',
                          style: CustomAppFontStyle.regular12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildThumbnail(p.data['afterBase64']?.toString()),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
