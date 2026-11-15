import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../settings/data/models/company_settings_model.dart';
import '../../../settings/data/models/enums/print_format_enum.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/enums/shift_status_enum.dart';
import '../../domain/helpers/money.dart';

class AdaptiveShiftReportPdfGenerator {
  static Future<Uint8List> generate({
    required CashierShiftModel shift,
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
  }) async {
    final pdf = pw.Document();

    final effectiveFormat = format ??
        settings?.effectiveShiftReportPrintFormat ??
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
            260 * PdfPageFormat.mm,
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
            return _buildThermalLayout(shift, settings);
          }
          return _buildA4Layout(shift, settings);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildA4Layout(
    CashierShiftModel shift,
    CompanySettingsModel? settings,
  ) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final phone = settings?.phone ?? '';
    final address = settings?.address ?? '';

    final openingBal = Money.fromPiastres(shift.openingBalancePiastres ?? 0);
    final cashCollected = Money.fromPiastres(shift.totalCashCollectedPiastres ?? 0);
    final cardCollected = Money.fromPiastres(shift.totalCardCollectedPiastres ?? 0);
    final transferCollected = Money.fromPiastres(shift.totalBankTransferPiastres ?? 0);
    final expenses = Money.fromPiastres(shift.totalExpensesPiastres ?? 0);
    final refunds = Money.fromPiastres(shift.totalRefundsPiastres ?? 0);
    final expectedCash = Money.fromPiastres(shift.expectedCashPiastres ?? 0);
    final actualCash = Money.fromPiastres(shift.actualCashCountPiastres ?? 0);
    final diff = Money.fromPiastres(shift.cashDifferencePiastres ?? 0);

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
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (address.isNotEmpty)
                    pw.Text(
                      address,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  if (phone.isNotEmpty)
                    pw.Text(
                      phone,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تقرير إغلاق الوردية (Z-Report)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.Text(
                    'تاريخ الطباعة: ${_formatDateTime(CairoTimeHelper.now())}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.blueGrey400),
          pw.SizedBox(height: 12),

          // Shift Meta
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem('معرف الوردية', shift.id ?? '-'),
                _buildMetaItem('الكاشير', shift.cashierName ?? shift.cashierUserId ?? '-'),
                _buildMetaItem('وقت الفتح', _formatDateTime(shift.openedAt)),
                _buildMetaItem('وقت الإغلاق', _formatDateTime(shift.closedAt)),
                _buildMetaItem('العمليات', '${shift.transactionCount ?? 0}'),
                _buildMetaItem('الحالة', _shiftStatusArabic(shift.status)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Financial Summary
          pw.Text(
            'الملخص المالي للوردية',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _buildTableRow('الرصيد الافتتاحي (عهدة البداية)', openingBal.formattedEgp),
              _buildTableRow('إجمالي المقبوضات النقدية (Cash)', cashCollected.formattedEgp),
              _buildTableRow('إجمالي مقبوضات الشبكة / البطاقات (Card)', cardCollected.formattedEgp),
              _buildTableRow('إجمالي التحويلات البنكية (Bank Transfer)', transferCollected.formattedEgp),
              _buildTableRow('إجمالي المصروفات المنصرفة من الدرج', expenses.formattedEgp),
              _buildTableRow('إجمالي المبالغ المستردة (Refunds)', refunds.formattedEgp),
              if ((shift.totalCapitalInjectionsPiastres ?? 0) > 0)
                _buildTableRow('إيداعات رأس المال الإضافية', Money.fromPiastres(shift.totalCapitalInjectionsPiastres!).formattedEgp),
              if ((shift.totalBankDepositsPiastres ?? 0) > 0)
                _buildTableRow('إيداعات بنكية من الدرج', Money.fromPiastres(shift.totalBankDepositsPiastres!).formattedEgp),
              if ((shift.totalOwnerWithdrawalsPiastres ?? 0) > 0)
                _buildTableRow('مسحوبات المالك', Money.fromPiastres(shift.totalOwnerWithdrawalsPiastres!).formattedEgp),
              _buildTableRow('إجمالي النقد المتوقع بالدرج', expectedCash.formattedEgp, isBold: true),
              _buildTableRow('النقد الفعلي المحسوب عند الإغلاق', actualCash.formattedEgp, isBold: true),
              _buildTableRow(
                'فرق النقد (عجز / زيادة)',
                diff.formattedEgp,
                isBold: true,
                textColor: (shift.cashDifferencePiastres ?? 0) < 0
                    ? PdfColors.red700
                    : ((shift.cashDifferencePiastres ?? 0) > 0 ? PdfColors.green700 : PdfColors.black),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Notes & Shortage Details
          if ((shift.shortageReason != null && shift.shortageReason!.isNotEmpty) ||
              (shift.forceCloseReason != null && shift.forceCloseReason!.isNotEmpty) ||
              (shift.closingNotes != null && shift.closingNotes!.isNotEmpty))
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (shift.shortageReason != null && shift.shortageReason!.isNotEmpty) ...[
                    pw.Text('سبب العجز / الملاحظات المرفوعة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(shift.shortageReason!, style: const pw.TextStyle(fontSize: 10)),
                    if (shift.isShortageApproved == true)
                      pw.Text('تم اعتماد العجز من المشرف: ${shift.shortageApprovedByUserId ?? ""}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green700)),
                    pw.SizedBox(height: 6),
                  ],
                  if (shift.forceCloseReason != null && shift.forceCloseReason!.isNotEmpty) ...[
                    pw.Text('سبب الإغلاق الإجباري:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red700)),
                    pw.Text(shift.forceCloseReason!, style: const pw.TextStyle(fontSize: 10)),
                    if (shift.forceClosedByUserId != null)
                      pw.Text('بواسطة: ${shift.forceClosedByUserId!}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                  ],
                  if (shift.closingNotes != null && shift.closingNotes!.isNotEmpty) ...[
                    pw.Text('ملاحظات الإغلاق العامة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(shift.closingNotes!, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ],
              ),
            ),

          pw.Spacer(),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('توقيع الكاشير', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('توقيع المشرف / المدير', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 130, height: 1, color: PdfColors.grey400),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'نظام إدارة العيادات والمراكز الطبية',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout(
    CashierShiftModel shift,
    CompanySettingsModel? settings,
  ) {
    final clinicName = (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final phone = settings?.phone ?? '';

    final openingBal = Money.fromPiastres(shift.openingBalancePiastres ?? 0);
    final cashCollected = Money.fromPiastres(shift.totalCashCollectedPiastres ?? 0);
    final cardCollected = Money.fromPiastres(shift.totalCardCollectedPiastres ?? 0);
    final transferCollected = Money.fromPiastres(shift.totalBankTransferPiastres ?? 0);
    final expenses = Money.fromPiastres(shift.totalExpensesPiastres ?? 0);
    final refunds = Money.fromPiastres(shift.totalRefundsPiastres ?? 0);
    final expectedCash = Money.fromPiastres(shift.expectedCashPiastres ?? 0);
    final actualCash = Money.fromPiastres(shift.actualCashCountPiastres ?? 0);
    final diff = Money.fromPiastres(shift.cashDifferencePiastres ?? 0);

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              clinicName,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          if (phone.isNotEmpty)
            pw.Center(
              child: pw.Text(
                phone,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'تقرير إغلاق الوردية (Z-Report)',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

          _buildThermalRow('معرف الوردية', shift.id ?? '-'),
          _buildThermalRow('الكاشير', shift.cashierName ?? shift.cashierUserId ?? '-'),
          _buildThermalRow('الفتح', _formatDateTime(shift.openedAt)),
          _buildThermalRow('الإغلاق', _formatDateTime(shift.closedAt)),
          _buildThermalRow('العمليات', '${shift.transactionCount ?? 0}'),
          _buildThermalRow('الحالة', _shiftStatusArabic(shift.status)),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

          _buildThermalRow('الافتتاحي', openingBal.formattedEgp),
          _buildThermalRow('نقدي (+)', cashCollected.formattedEgp),
          _buildThermalRow('شبكة / فيزا', cardCollected.formattedEgp),
          _buildThermalRow('تحويل بنكي', transferCollected.formattedEgp),
          _buildThermalRow('مصروفات (-)', expenses.formattedEgp),
          _buildThermalRow('مرتجعات (-)', refunds.formattedEgp),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

          _buildThermalRow('المتوقع في الدرج', expectedCash.formattedEgp, isBold: true),
          _buildThermalRow('الفعلي المحسوب', actualCash.formattedEgp, isBold: true),
          _buildThermalRow(
            'فرق النقد',
            diff.formattedEgp,
            isBold: true,
            textColor: (shift.cashDifferencePiastres ?? 0) < 0
                ? PdfColors.red700
                : ((shift.cashDifferencePiastres ?? 0) > 0 ? PdfColors.green700 : PdfColors.black),
          ),

          if (shift.shortageReason != null && shift.shortageReason!.isNotEmpty) ...[
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            pw.Text('سبب العجز:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
            pw.Text(shift.shortageReason!, style: const pw.TextStyle(fontSize: 7)),
          ],
          if (shift.forceCloseReason != null && shift.forceCloseReason!.isNotEmpty) ...[
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            pw.Text('سبب الإغلاق الإجباري:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            pw.Text(shift.forceCloseReason!, style: const pw.TextStyle(fontSize: 7)),
          ],

          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
          pw.Center(
            child: pw.Text(
              'تاريخ الطباعة: ${_formatDateTime(CairoTimeHelper.now())}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '*** نهاية التقرير ***',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetaItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildThermalRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  static String _shiftStatusArabic(ShiftStatusEnum? status) {
    switch (status) {
      case ShiftStatusEnum.open:
        return 'مفتوحة';
      case ShiftStatusEnum.closed:
        return 'مغلقة';
      case ShiftStatusEnum.closedPendingApproval:
        return 'معلقة للاعتماد';
      case ShiftStatusEnum.forceClosed:
        return 'إغلاق إجباري';
      case null:
        return '-';
    }
  }
}

