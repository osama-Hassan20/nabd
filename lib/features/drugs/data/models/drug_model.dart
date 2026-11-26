import 'package:equatable/equatable.dart';
import 'enums/drug_source_enum.dart';
import 'enums/review_status_enum.dart';

class DrugModel extends Equatable {
  final String? id;
  final String? name; // Trade name
  final String? scientificName; // Active ingredient / scientific name
  final String? categoryId;
  final String? concentration;
  final String? defaultDosage;
  final String? defaultFrequency;
  final String? defaultDuration;
  final String? description;
  final String? manufacturer;
  final bool? isActive;
  final bool? isQuickAdded;
  final bool unsafeInPregnancy;
  final bool unsafeInLactation;
  final ReviewStatusEnum? reviewStatus;
  final DrugSourceEnum? source;
  final String? createdByUserId;
  final DateTime? createdAt;
  final String? reviewedByUserId;
  final DateTime? reviewedAt;

  const DrugModel({
    this.id,
    this.name,
    this.scientificName,
    this.categoryId,
    this.concentration,
    this.defaultDosage,
    this.defaultFrequency,
    this.defaultDuration,
    this.description,
    this.manufacturer,
    this.isActive = true,
    this.isQuickAdded = false,
    this.unsafeInPregnancy = false,
    this.unsafeInLactation = false,
    this.reviewStatus = ReviewStatusEnum.approved,
    this.source = DrugSourceEnum.preset,
    this.createdByUserId,
    this.createdAt,
    this.reviewedByUserId,
    this.reviewedAt,
  });

  factory DrugModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DrugModel();
    return DrugModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      scientificName: json['scientificName'] as String?,
      categoryId: json['categoryId'] as String?,
      concentration: json['concentration'] as String?,
      defaultDosage: json['defaultDosage'] as String?,
      defaultFrequency: json['defaultFrequency'] as String?,
      defaultDuration: json['defaultDuration'] as String?,
      description: json['description'] as String?,
      manufacturer: json['manufacturer'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isQuickAdded: json['isQuickAdded'] as bool? ?? false,
      unsafeInPregnancy: json['unsafeInPregnancy'] as bool? ?? false,
      unsafeInLactation: json['unsafeInLactation'] as bool? ?? false,
      reviewStatus: ReviewStatusEnum.fromJson(json['reviewStatus'] as String?),
      source: DrugSourceEnum.fromJson(json['source'] as String?),
      createdByUserId: json['createdByUserId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (scientificName != null) 'scientificName': scientificName,
      if (categoryId != null) 'categoryId': categoryId,
      if (concentration != null) 'concentration': concentration,
      if (defaultDosage != null) 'defaultDosage': defaultDosage,
      if (defaultFrequency != null) 'defaultFrequency': defaultFrequency,
      if (defaultDuration != null) 'defaultDuration': defaultDuration,
      if (description != null) 'description': description,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (isActive != null) 'isActive': isActive,
      if (isQuickAdded != null) 'isQuickAdded': isQuickAdded,
      if (unsafeInPregnancy) 'unsafeInPregnancy': unsafeInPregnancy,
      if (unsafeInLactation) 'unsafeInLactation': unsafeInLactation,
      if (reviewStatus != null) 'reviewStatus': reviewStatus?.toJson(),
      if (source != null) 'source': source?.toJson(),
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (reviewedByUserId != null) 'reviewedByUserId': reviewedByUserId,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  DrugModel copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? categoryId,
    String? concentration,
    String? defaultDosage,
    String? defaultFrequency,
    String? defaultDuration,
    String? description,
    String? manufacturer,
    bool? isActive,
    bool? isQuickAdded,
    bool? unsafeInPregnancy,
    bool? unsafeInLactation,
    ReviewStatusEnum? reviewStatus,
    DrugSourceEnum? source,
    String? createdByUserId,
    DateTime? createdAt,
    String? reviewedByUserId,
    DateTime? reviewedAt,
  }) {
    return DrugModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      categoryId: categoryId ?? this.categoryId,
      concentration: concentration ?? this.concentration,
      defaultDosage: defaultDosage ?? this.defaultDosage,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      description: description ?? this.description,
      manufacturer: manufacturer ?? this.manufacturer,
      isActive: isActive ?? this.isActive,
      isQuickAdded: isQuickAdded ?? this.isQuickAdded,
      unsafeInPregnancy: unsafeInPregnancy ?? this.unsafeInPregnancy,
      unsafeInLactation: unsafeInLactation ?? this.unsafeInLactation,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      source: source ?? this.source,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        scientificName,
        categoryId,
        concentration,
        defaultDosage,
        defaultFrequency,
        defaultDuration,
        description,
        manufacturer,
        isActive,
        isQuickAdded,
        reviewStatus,
        source,
        createdByUserId,
        createdAt,
        reviewedByUserId,
        reviewedAt,
      ];
}

