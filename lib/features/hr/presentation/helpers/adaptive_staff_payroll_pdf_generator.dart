import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';

class AdaptiveStaffPayrollPdfGenerator {
  static Future<Uint8List> generate({
    required StaffPayrollPeriodModel period,
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
  }) async {
    final pdf = pw.Document();

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

    // Staff payroll requires wide landscape layout for all columns.
    // When thermal80 is requested, fallback gracefully to A4 landscape per design specification.
    final pageFormat = PdfPageFormat.a4.landscape;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return _buildA4LandscapeLayout(period, settings);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildA4LandscapeLayout(
    StaffPayrollPeriodModel period,
    CompanySettingsModel? settings,
  ) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final address = settings?.address ?? '';
    final phone = settings?.phone ?? '';

    final totalEmployees = period.totalEmployeesCount ?? (period.items?.length ?? 0);
    final totalBaseSalary = Money.fromPiastres(period.totalBaseSalaryPiastres ?? 0);
    final totalAllowances = Money.fromPiastres(period.totalAllowancesPiastres ?? 0);
    final totalDeductions = Money.fromPiastres(period.totalDeductionsPiastres ?? 0);
    final totalNetPayable = Money.fromPiastres(period.totalNetPayablePiastres ?? 0);
    final items = period.items ?? [];

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header Bar
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
                  if (address.isNotEmpty || phone.isNotEmpty)
                    pw.Text('$address  $phone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'مسير رواتب موظفي المركز',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                  ),
                  pw.Text(
                    'الفترة: ${period.year ?? '-'}/${period.month ?? '-'} | رقم المسير: ${period.payrollNumber ?? period.id ?? '-'}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 6),

          // Summary Metrics Cards
          pw.Row(
            children: [
              _buildMetricCard('إجمالي الموظفين', '$totalEmployees'),
              pw.SizedBox(width: 8),
              _buildMetricCard('إجمالي الأساسي', totalBaseSalary.formatEgp()),
              pw.SizedBox(width: 8),
              _buildMetricCard('إجمالي البدلات', totalAllowances.formatEgp()),
              pw.SizedBox(width: 8),
              _buildMetricCard('إجمالي الخصومات', totalDeductions.formatEgp()),
              pw.SizedBox(width: 8),
              _buildMetricCard('صافي الرواتب المستحقة', totalNetPayable.formatEgp(), highlight: true),
            ],
          ),
          pw.SizedBox(height: 12),

          // Items Table
          pw.Text('كشف تفاصيل رواتب العاملين:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),

          pw.TableHelper.fromTextArray(
            headers: const [
              'الموظف',
              'المسمى الوظيفي',
              'الراتب الأساسي',
              'البدلات',
              'الاستقطاعات',
              'خصم السلف',
              'صافي الراتب',
            ],
            data: items.map((item) {
              return [
                item.employeeName ?? item.staffUserId ?? '-',
                item.jobTitle ?? '-',
                Money.fromPiastres(item.baseSalaryPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.totalAllowancesPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.totalDeductionsPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.advancesDeductedPiastres ?? 0).formatEgp(),
                Money.fromPiastres(item.netSalaryPiastres ?? 0).formatEgp(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
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
                  pw.Text('إعداد الموارد البشرية:', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 20),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('مراجعة الحسابات:', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 20),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('اعتماد المدير العام:', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 20),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'تاريخ الطباعة: ${CairoTimeHelper.now().year}/${CairoTimeHelper.now().month.toString().padLeft(2, '0')}/${CairoTimeHelper.now().day.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, {bool highlight = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: highlight ? PdfColors.teal50 : PdfColors.grey50,
          border: pw.Border.all(color: highlight ? PdfColors.teal300 : PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: highlight ? PdfColors.teal900 : PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
