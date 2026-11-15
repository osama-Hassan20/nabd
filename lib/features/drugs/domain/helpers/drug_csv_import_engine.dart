import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/drug_import_preview_model.dart';
import '../../data/models/drug_model.dart';
import '../../data/models/enums/drug_source_enum.dart';
import '../../data/models/enums/review_status_enum.dart';
import 'drug_name_validator.dart';

class DrugCsvImportEngine {
  /// Strips UTF-8 BOM if present: [0xEF, 0xBB, 0xBF]
  static List<int> stripBom(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return bytes.sublist(3);
    }
    return bytes;
  }

  /// Parses CSV bytes into an import preview model with validation and deduplication.
  static Either<Failures, DrugImportPreviewModel> parseCsvBytes(
    List<int> bytes, {
    List<DrugModel> existingDrugs = const [],
  }) {
    final cleanBytes = stripBom(bytes);

    String content;
    try {
      content = utf8.decode(cleanBytes, allowMalformed: false);
    } catch (_) {
      return const Left(ValidationFailure(errMessage: 'drugs_import_encoding_error'));
    }

    return parseCsvString(content, existingDrugs: existingDrugs);
  }

  /// Parses CSV text content.
  static Either<Failures, DrugImportPreviewModel> parseCsvString(
    String content, {
    List<DrugModel> existingDrugs = const [],
  }) {
    final lines = _splitCsvLines(content);
    if (lines.isEmpty) {
      return const Right(
        DrugImportPreviewModel(
          totalRows: 0,
          validRows: [],
          invalidRows: [],
          duplicateRows: [],
          previewRows: [],
        ),
      );
    }

    // Parse header row
    final headerTokens = _parseCsvRow(lines.first);
    final headerIndices = _mapHeaderIndices(headerTokens);

    if (!headerIndices.containsKey('name')) {
      return const Left(ValidationFailure(errMessage: 'drugs_validation_name_required'));
    }

    final validRows = <DrugModel>[];
    final invalidRows = <DrugImportErrorModel>[];
    final duplicateRows = <DrugModel>[];

    // Build lookup set for existing catalog drugs
    final existingNames = <String>{};
    for (final d in existingDrugs) {
      if (d.name != null && d.name!.trim().isNotEmpty) {
        existingNames.add(_normalize(d.name!));
      }
    }

    final seenInFileNames = <String>{};

    for (int i = 1; i < lines.length; i++) {
      final rawLine = lines[i].trim();
      if (rawLine.isEmpty) continue;

      final tokens = _parseCsvRow(lines[i]);
      final name = _getField(tokens, headerIndices['name']);

      final nameValidationError = DrugNameValidator.validate(name);
      if (nameValidationError != null) {
        invalidRows.add(
          DrugImportErrorModel(
            rowIndex: i + 1,
            rawText: rawLine,
            reason: nameValidationError,
          ),
        );
        continue;
      }

      final normalizedName = _normalize(name!);

      final drugModel = DrugModel(
        name: name.trim(),
        scientificName: _getField(tokens, headerIndices['scientificName']),
        concentration: _getField(tokens, headerIndices['concentration']),
        defaultDosage: _getField(tokens, headerIndices['defaultDosage']),
        defaultFrequency: _getField(tokens, headerIndices['defaultFrequency']),
        defaultDuration: _getField(tokens, headerIndices['defaultDuration']),
        manufacturer: _getField(tokens, headerIndices['manufacturer']),
        categoryId: _getField(tokens, headerIndices['categoryId']),
        source: DrugSourceEnum.imported,
        reviewStatus: ReviewStatusEnum.approved,
        isActive: true,
      );

      // Check duplicates
      if (existingNames.contains(normalizedName) || seenInFileNames.contains(normalizedName)) {
        duplicateRows.add(drugModel);
      } else {
        seenInFileNames.add(normalizedName);
        validRows.add(drugModel);
      }
    }

    final previewRows = validRows.take(5).toList();

    return Right(
      DrugImportPreviewModel(
        totalRows: validRows.length + invalidRows.length + duplicateRows.length,
        validRows: validRows,
        invalidRows: invalidRows,
        duplicateRows: duplicateRows,
        previewRows: previewRows,
      ),
    );
  }

  static String? _getField(List<String> tokens, int? index) {
    if (index == null || index < 0 || index >= tokens.length) return null;
    final val = tokens[index].trim();
    return val.isEmpty ? null : val;
  }

  static Map<String, int> _mapHeaderIndices(List<String> headers) {
    final map = <String, int>{};

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');

      if (h == 'name' || h == 'tradename' || h == 'الاسم' || h == 'الاسمالتجاري' || h == 'اسمالدواء') {
        map['name'] = i;
      } else if (h == 'scientificname' || h == 'genericname' || h == 'activeingredient' || h == 'الاسمالعلمي' || h == 'المادةالفعالة') {
        map['scientificName'] = i;
      } else if (h == 'concentration' || h == 'strength' || h == 'التركيز') {
        map['concentration'] = i;
      } else if (h == 'dosage' || h == 'defaultdosage' || h == 'الجرعة' || h == 'الجرعةالمقترحة') {
        map['defaultDosage'] = i;
      } else if (h == 'frequency' || h == 'defaultfrequency' || h == 'التكرار' || h == 'التكرارالمقترح') {
        map['defaultFrequency'] = i;
      } else if (h == 'duration' || h == 'defaultduration' || h == 'المدة' || h == 'المدةالمقترحة') {
        map['defaultDuration'] = i;
      } else if (h == 'manufacturer' || h == 'company' || h == 'الشركةالمصنعة' || h == 'المصنع') {
        map['manufacturer'] = i;
      } else if (h == 'categoryid' || h == 'category' || h == 'التصنيف' || h == 'معرفالتصنيف') {
        map['categoryId'] = i;
      }
    }

    return map;
  }

  static List<String> _splitCsvLines(String content) {
    final lines = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++; // skip \n of \r\n
        }
        final line = buffer.toString().trim();
        if (line.isNotEmpty) {
          lines.add(line);
        }
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      lines.add(remaining);
    }

    return lines;
  }

  static List<String> _parseCsvRow(String line) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        tokens.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    tokens.add(buffer.toString());
    return tokens;
  }

  static String _normalize(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
