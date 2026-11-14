import 'package:equatable/equatable.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';

/// Structured result of an allergy cross-check.
class AllergyMatchResult extends Equatable {
  final bool hasConflict;
  final String? matchedAllergy; // The raw patient allergy string that triggered the conflict
  final String? catalogItemId; // ID of the catalog item (e.g. 'CAT-ALL-001') or null if free text
  final String? matchSource; // 'catalog_item' | 'free_text'
  final String? matchedTerm; // The exact matching term / alias (e.g. 'amoxicillin')

  const AllergyMatchResult({
    required this.hasConflict,
    this.matchedAllergy,
    this.catalogItemId,
    this.matchSource,
    this.matchedTerm,
  });

  static const AllergyMatchResult none = AllergyMatchResult(hasConflict: false);

  @override
  List<Object?> get props => [
        hasConflict,
        matchedAllergy,
        catalogItemId,
        matchSource,
        matchedTerm,
      ];
}

/// Pure clinical drug-allergy matching engine.
///
/// Implements full-word token matching with strict normalization, Arabic stop-word
/// stripping, guarded prefix removal, and zero intra-word substring false positives.
class DrugAllergyMatcher {
  static const Set<String> _stopWords = {
    // Arabic stop words
    'حساسية',
    'حساسيه',
    'شديدة',
    'شديده',
    'من',
    'ضد',
    'تجاه',
    'مرض',
    // English stop words
    'allergy',
    'allergic',
    'severe',
    'to',
    'against',
  };

  /// Normalizes Arabic and Latin text: lowercase, strip tashkeel, unify alefs/yaa/taa-marbuta.
  static String normalize(String? text) {
    if (text == null) return '';
    var s = text.toLowerCase().trim();
    // Remove Arabic diacritics (tashkeel): \u064B-\u065F, \u0670
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Remove tatweel (ـ)
    s = s.replaceAll('\u0640', '');
    // Unify alefs (أ, إ, آ -> ا)
    s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Unify yaa (ى -> ي)
    s = s.replaceAll('ى', 'ي');
    // Unify taa marbuta (ة -> ه)
    s = s.replaceAll('ة', 'ه');
    // Collapse multiple whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  /// Strips guarded prefixes ("ال", "وال", "بال", "لل", "وا") while protecting root letters.
  static String stripPrefix(String token) {
    var t = token;
    if (t.startsWith('وال') && t.length >= 6) {
      t = t.substring(3);
    } else if ((t.startsWith('بال') || t.startsWith('لل')) && t.length >= 6) {
      t = t.substring(3);
    } else if (t.startsWith('ال') && t.length >= 5) {
      t = t.substring(2);
    } else if (t.startsWith('و') && t.startsWith('وا') && t.length >= 5) {
      // Conjunction waaw before alef: e.g. 'واسبرين' -> 'اسبرين'
      t = t.substring(1);
    }
    return t;
  }

  /// Tokenizes a string by splitting numbers, dosage units, punctuation, and whitespace.
  static Set<String> tokenize(String? text) {
    if (text == null || text.trim().isEmpty) return {};

    // Remove dosage units attached to numbers: 1000mg, 1g, 500 mg, etc.
    var cleaned = text.replaceAll(
      RegExp(r'\d+(\.\d+)?\s*(mg|mcg|ml|g|iu|جم|ملغ|مل|جرام)\b', caseSensitive: false),
      ' ',
    );

    // Replace punctuation with space
    cleaned = cleaned.replaceAll(RegExp(r'[/\\+\-_,;:|()\[\]{}،.]'), ' ');
    // Remove standalone digits
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\b'), ' ');

    final rawTokens = cleaned.split(RegExp(r'\s+'));
    final tokens = <String>{};

    for (final raw in rawTokens) {
      final norm = normalize(raw);
      if (norm.isEmpty || _stopWords.contains(norm)) continue;

      tokens.add(norm);

      // Stripped prefix variant
      final stripped = stripPrefix(norm);
      if (stripped.isNotEmpty && !_stopWords.contains(stripped)) {
        tokens.add(stripped);
      }

      // Conjunction waaw without alef (e.g. 'وبنسلين' -> 'بنسلين') with root guard
      if (norm.startsWith('و') && norm.length >= 5 && !norm.startsWith('وارف')) {
        final withoutW = norm.substring(1);
        final strippedWithoutW = stripPrefix(withoutW);
        if (withoutW.isNotEmpty && !_stopWords.contains(withoutW)) {
          tokens.add(withoutW);
        }
        if (strippedWithoutW.isNotEmpty && !_stopWords.contains(strippedWithoutW)) {
          tokens.add(strippedWithoutW);
        }
      }
    }

    return tokens;
  }

  /// Cross-checks a prescribed drug against a patient's documented allergies.
  static AllergyMatchResult checkAllergy({
    required String drugName,
    String? scientificName,
    List<String>? patientAllergies,
    List<MedicalCatalogItemModel>? allergyCatalogItems,
    Map<String, List<String>>? customAliases,
  }) {
    if (patientAllergies == null || patientAllergies.isEmpty) {
      return AllergyMatchResult.none;
    }

    // 1. Build drug tokens (trade name + scientific name)
    final drugTokens = <String>{};
    drugTokens.addAll(tokenize(drugName));
    if (scientificName != null) {
      drugTokens.addAll(tokenize(scientificName));
    }

    if (drugTokens.isEmpty) {
      return AllergyMatchResult.none;
    }

    final normalizedDrugFullName = normalize('$drugName ${scientificName ?? ''}');

    // 2. Iterate through each recorded patient allergy
    for (final rawAllergy in patientAllergies) {
      final trimmedAllergy = rawAllergy.trim();
      if (trimmedAllergy.isEmpty) continue;

      final allergyTokens = tokenize(trimmedAllergy);
      if (allergyTokens.isEmpty) continue;

      // Check if allergy tokens match any catalog items
      MedicalCatalogItemModel? matchedCatalogItem;
      final expandedCandidateTerms = <String>{};

      if (allergyCatalogItems != null) {
        for (final item in allergyCatalogItems) {
          if (item.type != null && item.type != 'allergy') continue;

          final itemTokens = tokenize(item.name);
          final itemAliases = (item.aliases ?? [])
              .map(normalize)
              .where((a) => a.isNotEmpty)
              .toSet();

          // Check if any patient allergy token matches the catalog item name or its aliases
          final matchesCatalog = allergyTokens.any((t) =>
              itemTokens.contains(t) ||
              itemAliases.contains(t) ||
              (item.name != null && normalize(item.name) == t));

          if (matchesCatalog) {
            matchedCatalogItem = item;
            // Add all aliases and tokens of this catalog item as candidates
            expandedCandidateTerms.addAll(itemTokens);
            for (final alias in itemAliases) {
              expandedCandidateTerms.addAll(tokenize(alias));
            }
            break;
          }
        }
      }

      // Check custom aliases dictionary
      if (customAliases != null) {
        for (final entry in customAliases.entries) {
          final keyTokens = tokenize(entry.key);
          if (allergyTokens.any((t) => keyTokens.contains(t))) {
            for (final alias in entry.value) {
              expandedCandidateTerms.addAll(tokenize(alias));
            }
          }
        }
      }

      // Also include the original allergy tokens as direct candidates (free text matching)
      final allCandidates = <String>{...allergyTokens, ...expandedCandidateTerms};

      // 3. Strict full-word token comparison against drug tokens
      for (final candidate in allCandidates) {
        if (_stopWords.contains(candidate) || candidate.length < 2) continue;

        // Exact full-word token equality
        if (drugTokens.contains(candidate)) {
          return AllergyMatchResult(
            hasConflict: true,
            matchedAllergy: trimmedAllergy,
            catalogItemId: matchedCatalogItem?.id,
            matchSource: matchedCatalogItem != null ? 'catalog_item' : 'free_text',
            matchedTerm: candidate,
          );
        }

        // Multi-word phrase matching (e.g. 'acetylsalicylic acid')
        if (candidate.contains(' ') && normalizedDrugFullName.contains(candidate)) {
          return AllergyMatchResult(
            hasConflict: true,
            matchedAllergy: trimmedAllergy,
            catalogItemId: matchedCatalogItem?.id,
            matchSource: matchedCatalogItem != null ? 'catalog_item' : 'free_text',
            matchedTerm: candidate,
          );
        }
      }

      // Check if catalog item aliases contain multi-word phrases that match the drug text
      if (matchedCatalogItem?.aliases != null) {
        for (final rawAlias in matchedCatalogItem!.aliases!) {
          final normAlias = normalize(rawAlias);
          if (normAlias.isNotEmpty &&
              !_stopWords.contains(normAlias) &&
              normAlias.length >= 3) {
            // If alias is a multi-word phrase or compound phrase
            if (normAlias.contains(' ')) {
              if (RegExp(r'\b' + RegExp.escape(normAlias) + r'\b')
                  .hasMatch(normalizedDrugFullName)) {
                return AllergyMatchResult(
                  hasConflict: true,
                  matchedAllergy: trimmedAllergy,
                  catalogItemId: matchedCatalogItem.id,
                  matchSource: 'catalog_item',
                  matchedTerm: normAlias,
                );
              }
            } else {
              if (drugTokens.contains(normAlias)) {
                return AllergyMatchResult(
                  hasConflict: true,
                  matchedAllergy: trimmedAllergy,
                  catalogItemId: matchedCatalogItem.id,
                  matchSource: 'catalog_item',
                  matchedTerm: normAlias,
                );
              }
            }
          }
        }
      }
    }

    return AllergyMatchResult.none;
  }
}
