import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../settings/data/models/company_settings_model.dart';
import '../../../settings/data/models/enums/print_format_enum.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../domain/helpers/money.dart';

class AdaptiveReceiptPdfGenerator {
  static Future<Uint8List> generate({
    required PaymentTransactionModel payment,
    CompanySettingsModel? settings,
    PrintFormat format = PrintFormat.a4,
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

    final theme = pw.ThemeData.withFont(
      base: ttfFont,
      bold: ttfFont,
    );

    final pageFormat = format == PrintFormat.thermal80
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
          if (format == PrintFormat.thermal80) {
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
    final clinicName = settings?.companyName ?? 'عيادتي التخصصية';
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
                    'إيصال سداد نقدية',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'رقم الإيصال: ${payment.receiptNumber}',
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
                    pw.Text('التاريخ: ${payment.createdAt?.toIso8601String().split('T').first ?? '-'}'),
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
                    child: pw.Text('البيان', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('طريقة الدفع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('المبلغ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                    child: pw.Text(payment.paymentMethod?.name ?? 'نقدي'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(money.formatEgp()),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Total Highlight
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    final clinicName = settings?.companyName ?? 'عيادتي التخصصية';
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
          pw.Text('رقم: ${payment.receiptNumber}', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 6),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          _thermalRow('المريض:', payment.patientName ?? '-'),
          _thermalRow('الحجز:', payment.bookingId ?? '-'),
          _thermalRow('الكاشير:', payment.cashierName ?? '-'),
          _thermalRow(
            'الوقت:',
            payment.createdAt?.toIso8601String().split('T').first ?? '-',
          ),
          _thermalRow('طريقة الدفع:', payment.paymentMethod?.name ?? 'نقدي'),
          pw.SizedBox(height: 6),
          _dashedDivider(),
          pw.SizedBox(height: 6),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المدفوع:',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                money.formatEgp(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
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
}

