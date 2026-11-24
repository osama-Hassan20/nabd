import 'package:equatable/equatable.dart';

/// 1. دواء مستمر / علاج مزمن يتناوله المريض بانتظام
class ActiveMedicationModel extends Equatable {
  final String id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String? prescribedFor; // دواعي الاستعمال (مثل: لتنظيم السكر، للضغط)
  final DateTime? startDate;
  final String? instructions;

  const ActiveMedicationModel({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    this.prescribedFor,
    this.startDate,
    this.instructions,
  });

  factory ActiveMedicationModel.fromJson(Map<String, dynamic> json) {
    return ActiveMedicationModel(
      id: json['id']?.toString() ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      prescribedFor: json['prescribedFor'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationName': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'prescribedFor': prescribedFor,
        'startDate': startDate?.toIso8601String(),
        'instructions': instructions,
      };

  @override
  List<Object?> get props => [
        id,
        medicationName,
        dosage,
        frequency,
        prescribedFor,
        startDate,
        instructions,
      ];
}

/// 2. عملية جراحية سابقة في السجل الطبي
class SurgicalProcedureModel extends Equatable {
  final String id;
  final String procedureName;
  final DateTime date;
  final String? hospital;
  final String? surgeonName;
  final String? notes;

  const SurgicalProcedureModel({
    required this.id,
    required this.procedureName,
    required this.date,
    this.hospital,
    this.surgeonName,
    this.notes,
  });

  factory SurgicalProcedureModel.fromJson(Map<String, dynamic> json) {
    return SurgicalProcedureModel(
      id: json['id']?.toString() ?? '',
      procedureName: json['procedureName'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      hospital: json['hospital'] as String?,
      surgeonName: json['surgeonName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'procedureName': procedureName,
        'date': date.toIso8601String(),
        'hospital': hospital,
        'surgeonName': surgeonName,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, procedureName, date, hospital, surgeonName, notes];
}

/// 3. فحص معملي أو أشعة تشخيصية مع مرفقات
class LabRadiologyModel extends Equatable {
  final String id;
  final String title;
  final String type; // 'lab' (تحليل مخبري) أو 'radiology' (أشعة تشخيصية)
  final DateTime date;
  final String? centerName;
  final String? requestingDoctor;
  final String? resultSummary;
  final String? normalRange;
  final String? attachmentBase64;
  final String? fileUrl;

  const LabRadiologyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.centerName,
    this.requestingDoctor,
    this.resultSummary,
    this.normalRange,
    this.attachmentBase64,
    this.fileUrl,
  });

  factory LabRadiologyModel.fromJson(Map<String, dynamic> json) {
    return LabRadiologyModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'lab',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      centerName: json['centerName'] as String?,
      requestingDoctor: json['requestingDoctor'] as String?,
      resultSummary: json['resultSummary'] as String?,
      normalRange: json['normalRange'] as String?,
      attachmentBase64: json['attachmentBase64'] as String?,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'date': date.toIso8601String(),
        'centerName': centerName,
        'requestingDoctor': requestingDoctor,
        'resultSummary': resultSummary,
        'normalRange': normalRange,
        'attachmentBase64': attachmentBase64,
        'fileUrl': fileUrl,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        date,
        centerName,
        requestingDoctor,
        resultSummary,
        normalRange,
        attachmentBase64,
        fileUrl,
      ];
}

/// 4. فحص دوري متخصص للعيون (Ophthalmology Tracking)
class EyeTrackingExamModel extends Equatable {
  final String id;
  final DateTime examDate;
  final String? doctorName;
  final double? iopRight; // ضغط العين اليمنى mmHg (IOP OD)
  final double? iopLeft; // ضغط العين اليسرى mmHg (IOP OS)
  final String? visualAcuityRight; // حدة إبصار اليمنى (مثال: 6/6)
  final String? visualAcuityLeft; // حدة إبصار اليسرى
  final String? fundusNotes; // فحص قاع العين والشبكية
  final String? notes;

  const EyeTrackingExamModel({
    required this.id,
    required this.examDate,
    this.doctorName,
    this.iopRight,
    this.iopLeft,
    this.visualAcuityRight,
    this.visualAcuityLeft,
    this.fundusNotes,
    this.notes,
  });

  factory EyeTrackingExamModel.fromJson(Map<String, dynamic> json) {
    return EyeTrackingExamModel(
      id: json['id']?.toString() ?? '',
      examDate: json['examDate'] != null
          ? DateTime.tryParse(json['examDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      doctorName: json['doctorName'] as String?,
      iopRight: (json['iopRight'] as num?)?.toDouble(),
      iopLeft: (json['iopLeft'] as num?)?.toDouble(),
      visualAcuityRight: json['visualAcuityRight'] as String?,
      visualAcuityLeft: json['visualAcuityLeft'] as String?,
      fundusNotes: json['fundusNotes'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examDate': examDate.toIso8601String(),
        'doctorName': doctorName,
        'iopRight': iopRight,
        'iopLeft': iopLeft,
        'visualAcuityRight': visualAcuityRight,
        'visualAcuityLeft': visualAcuityLeft,
        'fundusNotes': fundusNotes,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        examDate,
        doctorName,
        iopRight,
        iopLeft,
        visualAcuityRight,
        visualAcuityLeft,
        fundusNotes,
        notes,
      ];
}

/// 5. معرض الصور السريري ومقارنة البداية والنهاية (Before / After & Progress)
class BeforeAfterGalleryItemModel extends Equatable {
  final String id;
  final String title;
  final String specialty; // 'dermatology', 'orthodontics', 'dental', 'surgery', 'general'
  final DateTime startDate;
  final DateTime? latestDate;
  final String? beforeImageBase64;
  final String? afterImageBase64;
  final int totalSessionsSoFar;
  final String? doctorName;
  final String? clinicalNotes;

  const BeforeAfterGalleryItemModel({
    required this.id,
    required this.title,
    required this.specialty,
    required this.startDate,
    this.latestDate,
    this.beforeImageBase64,
    this.afterImageBase64,
    this.totalSessionsSoFar = 1,
    this.doctorName,
    this.clinicalNotes,
  });

  factory BeforeAfterGalleryItemModel.fromJson(Map<String, dynamic> json) {
    return BeforeAfterGalleryItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'general',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latestDate: json['latestDate'] != null
          ? DateTime.tryParse(json['latestDate'].toString())
          : null,
      beforeImageBase64: json['beforeImageBase64'] as String?,
      afterImageBase64: json['afterImageBase64'] as String?,
      totalSessionsSoFar: (json['totalSessionsSoFar'] as num?)?.toInt() ?? 1,
      doctorName: json['doctorName'] as String?,
      clinicalNotes: json['clinicalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'specialty': specialty,
        'startDate': startDate.toIso8601String(),
        'latestDate': latestDate?.toIso8601String(),
        'beforeImageBase64': beforeImageBase64,
        'afterImageBase64': afterImageBase64,
        'totalSessionsSoFar': totalSessionsSoFar,
        'doctorName': doctorName,
        'clinicalNotes': clinicalNotes,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        specialty,
        startDate,
        latestDate,
        beforeImageBase64,
        afterImageBase64,
        totalSessionsSoFar,
        doctorName,
        clinicalNotes,
      ];
}
