import '../../data/models/enums/addendum_change_type_enum.dart';
import '../../data/models/prescription_item_model.dart';
import '../../data/models/visit_addendum_model.dart';
import '../../data/models/visit_model.dart';

class EffectivePrescriptionCalculator {
  EffectivePrescriptionCalculator._();

  static List<PrescriptionItemModel> calculateEffectivePrescription({
    required VisitModel visit,
  }) {
    final originalItems = List<PrescriptionItemModel>.from(
      visit.prescriptionItems ?? const [],
    );

    final addenda = List<VisitAddendumModel>.from(visit.addenda ?? const []);
    addenda.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });

    final effectiveList = List<PrescriptionItemModel>.from(originalItems);

    for (final addendum in addenda) {
      switch (addendum.changeType) {
        case AddendumChangeTypeEnum.add:
          if (addendum.newItemSnapshot != null) {
            final idx = effectiveList.indexWhere(
              (item) => item.id == addendum.newItemSnapshot!.id,
            );
            if (idx != -1) {
              effectiveList[idx] = addendum.newItemSnapshot!;
            } else {
              effectiveList.add(addendum.newItemSnapshot!);
            }
          }
          break;

        case AddendumChangeTypeEnum.discontinue:
          if (addendum.affectedItemId != null) {
            effectiveList.removeWhere(
              (item) => item.id == addendum.affectedItemId,
            );
          }
          break;

        case AddendumChangeTypeEnum.dose:
        case AddendumChangeTypeEnum.frequency:
        case AddendumChangeTypeEnum.duration:
        case AddendumChangeTypeEnum.instructions:
          if (addendum.affectedItemId != null &&
              addendum.newItemSnapshot != null) {
            final idx = effectiveList.indexWhere(
              (item) => item.id == addendum.affectedItemId,
            );
            if (idx != -1) {
              effectiveList[idx] = addendum.newItemSnapshot!;
            } else {
              effectiveList.add(addendum.newItemSnapshot!);
            }
          }
          break;

        case AddendumChangeTypeEnum.diagnosis:
        case null:
          // Does not affect prescription medications
          break;
      }
    }

    return List.unmodifiable(effectiveList);
  }

  static String? calculateEffectiveDiagnosis({
    required VisitModel visit,
  }) {
    String? currentDiagnosis = visit.diagnosis;

    final addenda = List<VisitAddendumModel>.from(visit.addenda ?? const []);
    addenda.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });

    for (final addendum in addenda) {
      if (addendum.changeType == AddendumChangeTypeEnum.diagnosis) {
        if (addendum.diagnosisAfter != null &&
            addendum.diagnosisAfter!.trim().isNotEmpty) {
          currentDiagnosis = addendum.diagnosisAfter;
        }
      }
    }

    return currentDiagnosis;
  }

  static bool isVisitAmended({required VisitModel visit}) {
    return visit.addenda != null && visit.addenda!.isNotEmpty;
  }
}

