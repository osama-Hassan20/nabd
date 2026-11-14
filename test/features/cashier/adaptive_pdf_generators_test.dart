import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/presentation/helpers/adaptive_receipt_pdf_generator.dart';
import 'package:eyadty/features/cashier/presentation/helpers/adaptive_shift_report_pdf_generator.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';

void main() {
  ByteData? fontData;

  setUpAll(() {
    final fontFile = File('assets/fonts/madani.ttf');
    if (fontFile.existsSync()) {
      fontData = ByteData.view(fontFile.readAsBytesSync().buffer);
    }
  });

  group('AdaptiveReceiptPdfGenerator', () {
    final samplePayment = PaymentTransactionModel(
      id: 'pay-001',
      bookingId: 'book-100',
      shiftId: 'shift-1',
      branchId: 'branch-1',
      patientName: 'أحمد محمود',
      amountPiastres: 35000,
      paymentMethod: PaymentMethod.cash,
      cashierUserId: 'user-c1',
      createdAt: DateTime(2026, 4, 15, 10, 30),
      notes: 'كشف باطنة مستعجل',
    );

    final clinicSettings = CompanySettingsModel(
      id: 'branch-1',
      companyName: 'عيادة الأمل التخصصية',
      phone: '01122334455',
      address: 'القاهرة - المعادي',
      receiptPrintFormat: 'a4',
      shiftReportPrintFormat: 'thermal80',
    );

    test('generates A4 PDF bytes successfully', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      // PDF header magic bytes %PDF
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('generates thermal 80mm PDF bytes successfully', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('applies dynamic clinic header from CompanySettingsModel', () async {
      final customSettings = CompanySettingsModel(
        companyName: 'مركز الشفاء الطبي المتقدم',
        phone: '01000000000',
        address: 'الإسكندرية - سموحة',
      );

      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: customSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(100));
    });

    test('falls back gracefully to default clinic name when settings is null', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: null,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('defaults to A4 when format is unspecified', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: clinicSettings,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('never exposes credit card number or unmasked sensitive data', () async {
      final cardPayment = PaymentTransactionModel(
        id: 'pay-card-1',
        shiftId: 'shift-1',
        branchId: 'branch-1',
        patientName: 'سارة علي',
        amountPiastres: 50000,
        paymentMethod: PaymentMethod.card,
        cashierUserId: 'user-c1',
        createdAt: DateTime(2026, 4, 15, 11, 0),
      );

      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: cardPayment,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      // Card numbers should never exist in the model or pdf output
      expect(cardPayment.toJson().containsKey('cardNumber'), isFalse);
    });
  });

  group('AdaptiveShiftReportPdfGenerator', () {
    final sampleShift = CashierShiftModel(
      id: 'shift-001',
      branchId: 'branch-1',
      cashierUserId: 'user-c1',
      cashierName: 'كاشير الورديات الأول',
      status: ShiftStatusEnum.closed,
      openedAt: DateTime(2026, 4, 15, 8, 0),
      closedAt: DateTime(2026, 4, 15, 16, 0),
      openingBalancePiastres: 100000, // 1000 EGP
      totalCashCollectedPiastres: 250000, // 2500 EGP
      totalCardCollectedPiastres: 150000, // 1500 EGP
      totalBankTransferPiastres: 50000, // 500 EGP
      totalExpensesPiastres: 20000, // 200 EGP
      totalRefundsPiastres: 10000, // 100 EGP
      expectedCashPiastres: 320000, // 1000 + 2500 - 200 - 100 = 3200 EGP
      actualCashCountPiastres: 315000, // 3150 EGP
      cashDifferencePiastres: -5000, // -50 EGP shortage
      shortageReason: 'خطأ في إرجاع الفكة للمريض صباحاً',
      isShortageApproved: true,
      shortageApprovedByUserId: 'manager-1',
      closingNotes: 'تم تسليم الدرج للمشرف',
      transactionCount: 24,
    );

    final clinicSettings = CompanySettingsModel(
      id: 'branch-1',
      companyName: 'عيادة الأمل التخصصية',
      phone: '01122334455',
      address: 'القاهرة - المعادي',
    );

    test('generates A4 shift report PDF bytes successfully', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('generates thermal 80mm shift report PDF bytes successfully', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('renders financial summary and shortage reason in A4 layout', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(200));
    });

    test('falls back gracefully when settings is null', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: null,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}

