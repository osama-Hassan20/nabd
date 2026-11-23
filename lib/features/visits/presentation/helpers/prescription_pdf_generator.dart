import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../settings/data/models/company_settings_model.dart';
import '../../../settings/data/models/enums/print_format_enum.dart';
import '../../data/models/prescription_item_model.dart';
import '../../data/models/visit_model.dart';
import 'effective_prescription_calculator.dart';

class PrescriptionPdfGenerator {
  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
  static Future<Uint8List> generate({
    required VisitModel visit,
    PatientModel? patient,
    List<PrescriptionItemModel>? effectiveItems,
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
  }) async {
    final pdf = pw.Document();

    final printFormat = format ??
        settings?.effectivePrescriptionPrintFormat ??
        PrintFormat.a4;

    pw.Font? ttfFont;
    if (fontData != null) {
      ttfFont = pw.Font.ttf(fontData);
    } else {
      try {
        final data = await rootBundle.load('assets/fonts/madani.ttf');
        ttfFont = pw.Font.ttf(data);
      } catch (_) {
        ttfFont = null;
      }
    }

    final theme = ttfFont != null
        ? pw.ThemeData.withFont(base: ttfFont, bold: ttfFont)
        : pw.ThemeData();

    final pageFormat = printFormat == PrintFormat.thermal80
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            240 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    final computedItems = effectiveItems ??
        EffectivePrescriptionCalculator.calculateEffectivePrescription(
          visit: visit,
        );

    final effectiveDiagnosis =
        EffectivePrescriptionCalculator.calculateEffectiveDiagnosis(
      visit: visit,
    );

    final isAmended =
        EffectivePrescriptionCalculator.isVisitAmended(visit: visit);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          if (printFormat == PrintFormat.thermal80) {
            return _buildThermalLayout(
              visit: visit,
              patient: patient,
              items: computedItems,
              effectiveDiagnosis: effectiveDiagnosis,
              settings: settings,
              isAmended: isAmended,
            );
          }
          return _buildA4Layout(
            visit: visit,
            patient: patient,
            items: computedItems,
            effectiveDiagnosis: effectiveDiagnosis,
            settings: settings,
            isAmended: isAmended,
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildA4Layout({
    required VisitModel visit,
    PatientModel? patient,
    required List<PrescriptionItemModel> items,
    String? effectiveDiagnosis,
    CompanySettingsModel? settings,
    required bool isAmended,
  }) {
    final template = settings?.effectivePrescriptionTemplate;

    final clinicName = (template != null && template.clinicDisplayName.trim().isNotEmpty)
        ? template.clinicDisplayName
        : ((settings?.companyName != null && settings!.companyName!.trim().isNotEmpty)
            ? settings.companyName!
            : 'المركز الطبي');

    final addresses = (template != null && template.addresses.isNotEmpty)
        ? template.addresses
        : (settings?.address != null && settings!.address!.trim().isNotEmpty
            ? [settings.address!]
            : <String>[]);

    final phoneNumbers = (template != null && template.phoneNumbers.isNotEmpty)
        ? template.phoneNumbers
        : (settings?.phone != null && settings!.phone!.trim().isNotEmpty
            ? [settings.phone!]
            : <String>[]);

    final patientName = visit.patientName ?? patient?.name ?? '-';
    final fileNumber = patient?.fileNumber ?? visit.patientId ?? '-';
    final doctorName = (template != null && template.doctorDisplayName.trim().isNotEmpty)
        ? template.doctorDisplayName
        : (visit.doctorName ?? 'طبيب الكشف');
    final doctorTitle = template?.doctorTitle ?? '';
    final medicalLicense = template?.medicalLicenseNumber ?? '';
    final ministryLicense = template?.ministryLicenseNumber ?? '';

    final rawDate =
        visit.startedAt ?? visit.finalizedAt ?? visit.triageAt ?? CairoTimeHelper.now();
    final visitDate = _formatDate(rawDate);

    final bool isPreprinted = template?.headerLayout == 'preprinted';
    final double preprintedGap = template?.preprintedHeaderHeight ?? 45.0;

    return pw.Container(
      padding: pw.EdgeInsets.only(
        top: isPreprinted ? preprintedGap : (template?.topMargin ?? 20.0),
        bottom: template?.bottomMargin ?? 20.0,
        right: template?.rightMargin ?? 15.0,
        left: template?.leftMargin ?? 15.0,
      ),
      child: pw.Stack(
        children: [
          // ─── Watermark Layer (if enabled) ─────────────────────────
          if (template?.watermarkEnabled == true)
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Opacity(
                  opacity: template!.watermarkOpacity,
                  child: pw.Transform.rotate(
                    angle: -0.45,
                    child: pw.Text(
                      template.watermarkCustomText.isNotEmpty
                          ? template.watermarkCustomText
                          : clinicName,
                      style: pw.TextStyle(
                        fontSize: 48,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ─── Main Content ─────────────────────────────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ─── Header: Clinic Info & Rx Title ──────────────────
              if (!isPreprinted) ...[
                if (template?.headerLayout == 'centered')
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        clinicName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (doctorName.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '$doctorName ${doctorTitle.isNotEmpty ? "($doctorTitle)" : ""}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                      if (ministryLicense.isNotEmpty || medicalLicense.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${ministryLicense.isNotEmpty ? "ترخيص وزارة الصحة: $ministryLicense" : ""}  ${medicalLicense.isNotEmpty ? "| ترخيص النقابة: $medicalLicense" : ""}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                      if (addresses.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          addresses.join('  •  '),
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                      if (phoneNumbers.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          phoneNumbers.join('  •  '),
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'روشتة علاجية سريرية - $visitDate',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  )
                else
                  // Dual layout (default)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            clinicName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          if (addresses.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            ...addresses.map(
                              (addr) => pw.Text(
                                addr,
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ],
                          if (phoneNumbers.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              phoneNumbers.join('  |  '),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            doctorName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          if (doctorTitle.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              doctorTitle,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ],
                          if (medicalLicense.isNotEmpty) ...[
                            pw.SizedBox(height: 1),
                            pw.Text(
                              'ترخيص النقابة: $medicalLicense',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            ),
                          ],
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'التاريخ: $visitDate',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 6),
              ],

              // ─── Amended Watermark / Notice ───────────────────────────
              if (isAmended) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.amber600, width: 1.2),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '[نسخة معدلة — يوجد ملحق سريري معتمد للروشتة]',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // ─── Patient & Doctor Info Box ────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'المريض: $patientName',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'رقم الملف: $fileNumber',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                            if (patient?.gender != null) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'النوع: ${patient!.gender!.name}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'الطبيب المعالج: $doctorName',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'رقم الكشف: ${visit.id ?? '-'}',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                            if (effectiveDiagnosis != null &&
                                effectiveDiagnosis.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'التشخيص: $effectiveDiagnosis',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    // ─── Chronic Diseases & Allergies Alert Box ───────────────
                    if ((template?.showChronicDiseasesAndAllergies ?? true) &&
                        ((patient?.hasAllergies == true) ||
                         (patient?.hasChronicDiseases == true))) ...[
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.red50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          border: pw.Border.all(color: PdfColors.red300, width: 0.8),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'تنبيهات سريرية: ',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red900,
                              ),
                            ),
                            if (patient?.hasAllergies == true) ...[
                              pw.Text(
                                'الحساسية: [${patient!.allergies!.join("، ")}]  ',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red800,
                                ),
                              ),
                            ],
                            if (patient?.hasChronicDiseases == true) ...[
                              pw.Text(
                                'الأمراض المزمنة: [${patient!.chronicDiseases!.join("، ")}]',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // ─── Rx Sign ──────────────────────────────────────────────
              pw.Row(
                children: [
                  pw.Text(
                    'Rx',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'الأدوية والعلاج الموصوف:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // ─── Prescription Items List ──────────────────────────────
              if (items.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'لا توجد أدوية مسجلة في هذه الروشتة',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.8,
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FlexColumnWidth(2.5),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue50,
                      ),
                      children: [
                        _buildTableHeaderCell('الدواء'),
                        _buildTableHeaderCell('الجرعة'),
                        _buildTableHeaderCell('التكرار'),
                        _buildTableHeaderCell('المدة'),
                        _buildTableHeaderCell('التعليمات'),
                      ],
                    ),
                    // Items Rows
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.tradeName ?? '',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                                if (item.scientificName != null &&
                                    item.scientificName!.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    item.scientificName!,
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildTableCell(item.dosage ?? '-'),
                          _buildTableCell(item.frequency ?? '-'),
                          _buildTableCell(item.duration ?? '-'),
                          _buildTableCell(item.instructions ?? '-'),
                        ],
                      );
                    }),
                  ],
                ),

              pw.Spacer(),

              // ─── Legal Disclaimer (if specified) ──────────────────────
              if (template != null && template.legalDisclaimer.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey200, width: 0.6),
                  ),
                  child: pw.Text(
                    template.legalDisclaimer,
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // ─── Follow-up Notes (if any) ─────────────────────────────
              if ((visit.followUpNotes != null &&
                      visit.followUpNotes!.isNotEmpty) ||
                  visit.followUpDays != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'ملاحظات الاستشارة / الإعادة: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${visit.followUpDays != null ? 'خلال ${visit.followUpDays} يوماً. ' : ''}${visit.followUpNotes ?? ''}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // ─── Footer: Signature & Official Stamp ───────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (template?.includeDoctorSignature ?? true)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'توقيع الطبيب المعالج:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 25),
                        pw.Container(
                          width: 130,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: PdfColors.grey400,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    pw.SizedBox(),

                  if (template?.includeOfficialStamp ?? true)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 80,
                          height: 50,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 1),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            (template != null && template.officialStampText.isNotEmpty)
                                ? template.officialStampText
                                : 'ختم المركز المعتمد',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  else
                    pw.SizedBox(),
                ],
              ),
              pw.SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout({
    required VisitModel visit,
    PatientModel? patient,
    required List<PrescriptionItemModel> items,
    String? effectiveDiagnosis,
    CompanySettingsModel? settings,
    required bool isAmended,
  }) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final phone = settings?.phone ?? '';

    final patientName = visit.patientName ?? patient?.name ?? '-';
    final fileNumber = patient?.fileNumber ?? visit.patientId ?? '-';
    final doctorName = visit.doctorName ?? 'طبيب الكشف';
    final rawDate =
        visit.startedAt ?? visit.finalizedAt ?? visit.triageAt ?? CairoTimeHelper.now();
    final visitDate = _formatDate(rawDate);

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
          pw.Center(
            child: pw.Text(
              clinicName,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (phone.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                phone,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'روشتة علاجية',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1, color: PdfColors.grey600),

          // Amended Notice
          if (isAmended) ...[
            pw.Center(
              child: pw.Text(
                '*** نسخة معدلة — يوجد ملحق سريري ***',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                ),
              ),
            ),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          ],

          // Patient & Doctor Info
          pw.Text(
            'المريض: $patientName',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('الملف: $fileNumber', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('الطبيب: $doctorName', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('التاريخ: $visitDate', style: const pw.TextStyle(fontSize: 8)),
          if (effectiveDiagnosis != null && effectiveDiagnosis.isNotEmpty)
            pw.Text(
              'التشخيص: $effectiveDiagnosis',
              style: const pw.TextStyle(fontSize: 8),
            ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1, color: PdfColors.grey600),

          // Items list
          pw.Text(
            'الأدوية والعلاج الموصوف:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),

          if (items.isEmpty)
            pw.Text(
              'لا توجد أدوية مسجلة',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            )
          else
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$idx. ${item.tradeName ?? ''} - ${item.dosage ?? ''}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (item.scientificName != null &&
                        item.scientificName!.isNotEmpty)
                      pw.Text(
                        '(${item.scientificName})',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    pw.Text(
                      'التكرار: ${item.frequency ?? '-'} | المدة: ${item.duration ?? '-'}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    if (item.instructions != null &&
                        item.instructions!.isNotEmpty)
                      pw.Text(
                        'التعليمات: ${item.instructions}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey800,
                        ),
                      ),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  ],
                ),
              );
            }),

          // Footer
          pw.SizedBox(height: 6),
          if (visit.followUpDays != null || visit.followUpNotes != null) ...[
            pw.Text(
              'الإعادة: ${visit.followUpDays != null ? 'خلال ${visit.followUpDays} يوماً' : ''} ${visit.followUpNotes ?? ''}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Center(
            child: pw.Text(
              'مع تمنياتنا بالشفاء العاجل',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
      ),
    );
  }
}
