import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/enums/payment_method.dart';
import '../../../settings/data/models/company_settings_model.dart';
import '../../../settings/data/models/enums/print_format_enum.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../domain/helpers/money.dart';

class AdaptiveReceiptPdfGenerator {
  static Future<Uint8List> generate({
    required PaymentTransactionModel payment,
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
  }) async {
    final pdf = pw.Document();

    final effectiveFormat =
        format ?? settings?.effectiveReceiptPrintFormat ?? PrintFormat.a4;

    pw.Font? ttfFont;
    if (fontData != null) {
      ttfFont = pw.Font.ttf(fontData);
    } else {
      try {
        final data = await rootBundle.load('assets/fonts/madani.ttf');
        ttfFont = pw.Font.ttf(data);
      } catch (_) {
        if (!kIsWeb) {
          try {
            final file = File('assets/fonts/madani.ttf');
            if (file.existsSync()) {
              ttfFont =
                  pw.Font.ttf(ByteData.view(file.readAsBytesSync().buffer));
            } else {
              ttfFont = null;
            }
          } catch (_) {
            ttfFont = null;
          }
        } else {
          ttfFont = null;
        }
      }
    }

    final theme = ttfFont != null
        ? pw.ThemeData.withFont(base: ttfFont, bold: ttfFont)
        : pw.ThemeData();

    final pageFormat = effectiveFormat == PrintFormat.thermal80
        ? const PdfPageFormat(
            80 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
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
            return _buildThermalLayout(payment, settings);
          }
          return _buildA4Layout(payment, settings);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildA4Layout(
    PaymentTransactionModel payment,
    CompanySettingsModel? settings,
  ) {
    final money = Money.fromPiastres(payment.amountPiastres ?? 0);
    final clinicName =
        (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final phone = settings?.phone ?? '';
    final address = settings?.address ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
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
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (phone.isNotEmpty)
                    pw.Text(
                      phone,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'إيصال سداد نقدية',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'رقم الإيصال: ${payment.receiptNumber.isNotEmpty ? payment.receiptNumber : '-'}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1.5, color: PdfColors.blue900),
          pw.SizedBox(height: 16),

          // Metadata Grid
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('اسم المريض: ${payment.patientName ?? '-'}'),
                    pw.SizedBox(height: 6),
                    pw.Text('رقم الحجز: ${payment.bookingId ?? '-'}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('التاريخ: ${_formatDateTime(payment.createdAt)}'),
                    pw.SizedBox(height: 6),
                    pw.Text('الكاشير: ${payment.cashierName ?? '-'}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Payment Details Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'البيان',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'طريقة الدفع',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('سداد كشف طبي / استشارة'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_paymentMethodArabic(payment.paymentMethod)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(money.formatEgp()),
                  ),
                ],
              ),
            ],
          ),
          if (payment.notes != null && payment.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ملاحظات: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      payment.notes!.trim(),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 24),

          // Total Highlight
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'الإجمالي المسدد: ${money.formatEgp()}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ),
          ),
          pw.Spacer(),

          // Footer Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('توقيع الكاشير'),
                  pw.SizedBox(height: 30),
                  pw.Text('................................'),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('ختم العيادة'),
                  pw.SizedBox(height: 30),
                  pw.Text('................................'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalLayout(
    PaymentTransactionModel payment,
    CompanySettingsModel? settings,
  ) {
    final money = Money.fromPiastres(payment.amountPiastres ?? 0);
    final clinicName =
        (settings?.companyName != null &&
            settings!.companyName!.trim().isNotEmpty)
        ? settings.companyName!
        : 'المركز الطبي';
    final phone = settings?.phone ?? '';

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            clinicName,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          if (phone.isNotEmpty)
            pw.Text(
              phone,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            '-- إيصال سداد نقدية --',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'رقم: ${payment.receiptNumber.isNotEmpty ? payment.receiptNumber : '-'}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 6),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          _thermalRow('المريض:', payment.patientName ?? '-'),
          _thermalRow('الحجز:', payment.bookingId ?? '-'),
          _thermalRow('الكاشير:', payment.cashierName ?? '-'),
          _thermalRow('الوقت:', _formatDateTime(payment.createdAt)),
          _thermalRow(
            'طريقة الدفع:',
            _paymentMethodArabic(payment.paymentMethod),
          ),
          if (payment.notes != null && payment.notes!.trim().isNotEmpty)
            _thermalRow('ملاحظات:', payment.notes!.trim()),
          pw.SizedBox(height: 6),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المدفوع:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                money.formatEgp(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _dashedDivider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'شكراً لزيارتكم - مع تمنياتنا بالشفاء العاجل',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _thermalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dashedDivider() {
    return pw.Text(
      '------------------------------------------------',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      maxLines: 1,
    );
  }

  static String _paymentMethodArabic(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.card:
        return 'بطاقة / شبكة';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case null:
        return 'نقدي';
    }
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
}
