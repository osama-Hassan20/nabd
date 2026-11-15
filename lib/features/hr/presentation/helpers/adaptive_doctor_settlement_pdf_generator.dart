import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';

class AdaptiveDoctorSettlementPdfGenerator {
  static Future<Uint8List> generate({
    required DoctorSettlementModel settlement,
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
  }) async {
    final pdf = pw.Document();

    final effectiveFormat = format ??
        settings?.effectiveDoctorSettlementPrintFormat ??
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

    final pageFormat = effectiveFormat == PrintFormat.thermal80
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            240 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          if (effectiveFormat == PrintFormat.thermal80) {
            return _buildThermalLayout(settlement, settings);
          }
          return _buildA4Layout(settlement, settings);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildA4Layout(
    DoctorSettlementModel settlement,
    CompanySettingsModel? settings,
  ) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final address = settings?.address ?? '';
    final phone = settings?.phone ?? '';

    final totalVisits = settlement.totalVisitsCount ?? 0;
    final totalRevenue = Money.fromPiastres(settlement.totalNetRevenuePiastres ?? 0);
    final netPayable = Money.fromPiastres(settlement.netPayablePiastres ?? 0);
    final items = settlement.items ?? [];

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Clinic Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    clinicName,
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  if (address.isNotEmpty)
                    pw.Text(address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if (phone.isNotEmpty)
                    pw.Text(phone, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تسوية أتعاب طبيب',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                  ),
                  pw.Text(
                    settlement.settlementNumber ?? settlement.id ?? '-',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // Settlement Details Bar
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('الطبيب: ${settlement.doctorName ?? settlement.doctorId ?? '-'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('الفرع: ${settlement.branchId ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('الحالة: ${settlement.status?.name ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Summary Financial Cards
          pw.Row(
            children: [
              _buildMetricBox('عدد الكشوفات', '$totalVisits'),
              pw.SizedBox(width: 8),
              _buildMetricBox('إجمالي الإيراد', totalRevenue.formatEgp()),
              pw.SizedBox(width: 8),
              _buildMetricBox('صافي المستحق', netPayable.formatEgp(), highlight: true),
            ],
          ),
          pw.SizedBox(height: 16),

          // Items Table
          pw.Text('تفاصيل الكشوفات:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),

          pw.TableHelper.fromTextArray(
            headers: const ['الكشف', 'المريض', 'الخدمة', 'الإجمالي', 'الخصم', 'الصافي', 'مستحق الطبيب'],
            data: items.map((item) {
              return [
                item.visitId ?? '-',
                item.patientName ?? item.patientId ?? '-',
                item.serviceName ?? '-',
                Money.fromPiastres(item.grossFeePiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.discountAmountPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.netAmountPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.doctorEarnedPiastres ?? 0).formatEgp(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),

          pw.Spacer(),

          // Signatures Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('توقيع الطبيب:', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 25),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('اعتماد الحسابات / الإدارة:', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 25),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout(
    DoctorSettlementModel settlement,
    CompanySettingsModel? settings,
  ) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';

    final totalVisits = settlement.totalVisitsCount ?? 0;
    final totalRevenue = Money.fromPiastres(settlement.totalNetRevenuePiastres ?? 0);
    final netPayable = Money.fromPiastres(settlement.netPayablePiastres ?? 0);
    final items = settlement.items ?? [];

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(clinicName,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text('تسوية أتعاب طبيب (حراري)',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Divider(thickness: 0.5),

          pw.Text('رقم التسوية: ${settlement.settlementNumber ?? settlement.id ?? '-'}',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text('الطبيب: ${settlement.doctorName ?? settlement.doctorId ?? '-'}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text('الحالة: ${settlement.status?.name ?? '-'}',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Divider(thickness: 0.5),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الكشوفات:', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('$totalVisits', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('إجمالي الإيراد:', style: const pw.TextStyle(fontSize: 8)),
              pw.Text(totalRevenue.formatEgp(), style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Divider(thickness: 0.5),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('صافي المستحق:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(netPayable.formatEgp(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(thickness: 0.5),

          pw.Text('الكشوفات المنجزة:', style: const pw.TextStyle(fontSize: 8)),
          ...items.take(8).map((item) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item.visitId ?? '-', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text(Money.fromPiastres(item.doctorEarnedPiastres ?? 0).formatEgp(),
                      style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            );
          }),

          if (items.length > 8)
            pw.Center(
              child: pw.Text('... و ${items.length - 8} كشوفات أخرى',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ),

          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              '${CairoTimeHelper.now().year}/${CairoTimeHelper.now().month.toString().padLeft(2, '0')}/${CairoTimeHelper.now().day.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox(String label, String value, {bool highlight = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: highlight ? PdfColors.blue50 : PdfColors.grey50,
          border: pw.Border.all(color: highlight ? PdfColors.blue300 : PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: highlight ? PdfColors.blue800 : PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
