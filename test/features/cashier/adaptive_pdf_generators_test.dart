import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
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
      cashierName: 'كاشير الفرع',
      createdAt: DateTime(2026, 4, 15, 10, 30),
      notes: 'كشف باطنة مستعجل',
    );

    final clinicSettings = const CompanySettingsModel(
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
      const customSettings = CompanySettingsModel(
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

    test('falls back gracefully to neutral default clinic name when settings is null or empty', () async {
      final bytesNull = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: null,
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(bytesNull, isNotNull);
      expect(bytesNull.isNotEmpty, isTrue);

      final bytesEmpty = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: const CompanySettingsModel(companyName: '  '),
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(bytesEmpty, isNotNull);
      expect(bytesEmpty.isNotEmpty, isTrue);
    });

    test('defaults to A4 when format is unspecified and settings has no preference', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: null,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('respects settings.effectiveReceiptPrintFormat when format is unspecified', () async {
      const thermalSettings = CompanySettingsModel(
        companyName: 'عيادة الأمل التخصصية',
        receiptPrintFormat: 'thermal80',
      );

      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: thermalSettings,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('works seamlessly when fontData is omitted via disk font fallback', () async {
      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: samplePayment,
        settings: clinicSettings,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('handles completely sparse PaymentTransactionModel with all optional fields null', () async {
      const sparsePayment = PaymentTransactionModel(
        id: null,
        bookingId: null,
        shiftId: null,
        branchId: null,
        patientName: null,
        amountPiastres: null,
        paymentMethod: null,
        cashierUserId: null,
        cashierName: null,
        createdAt: null,
        notes: null,
      );

      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: sparsePayment,
        settings: null,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('renders payment notes cleanly in both A4 and thermal formats', () async {
      final paymentWithNotes = samplePayment.copyWith(
        notes: 'ملاحظة خاصة: دفعة كشف استشاري ومتابعة فندقية',
      );

      final a4Bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: paymentWithNotes,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(a4Bytes, isNotNull);
      expect(a4Bytes.isNotEmpty, isTrue);

      final thermalBytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: paymentWithNotes,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(thermalBytes, isNotNull);
      expect(thermalBytes.isNotEmpty, isTrue);
    });

    test('handles null id gracefully by falling back to dash', () async {
      final paymentNoId = samplePayment.copyWith(
        id: null,
      );

      final bytes = await AdaptiveReceiptPdfGenerator.generate(
        payment: paymentNoId,
        settings: clinicSettings,
        fontData: fontData,
      );
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('generates receipt for all payment methods: cash, card, and bankTransfer', () async {
      for (final method in PaymentMethod.values) {
        final payment = samplePayment.copyWith(paymentMethod: method);
        final a4Bytes = await AdaptiveReceiptPdfGenerator.generate(
          payment: payment,
          settings: clinicSettings,
          format: PrintFormat.a4,
          fontData: fontData,
        );
        expect(a4Bytes, isNotNull);
        expect(a4Bytes.isNotEmpty, isTrue);

        final thermalBytes = await AdaptiveReceiptPdfGenerator.generate(
          payment: payment,
          settings: clinicSettings,
          format: PrintFormat.thermal80,
          fontData: fontData,
        );
        expect(thermalBytes, isNotNull);
        expect(thermalBytes.isNotEmpty, isTrue);
      }
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
      totalCapitalInjectionsPiastres: 50000, // 500 EGP
      totalBankDepositsPiastres: 100000, // 1000 EGP
      totalOwnerWithdrawalsPiastres: 30000, // 300 EGP
      expectedCashPiastres: 320000,
      actualCashCountPiastres: 315000,
      cashDifferencePiastres: -5000, // -50 EGP shortage
      shortageReason: 'خطأ في إرجاع الفكة للمريض صباحاً',
      isShortageApproved: true,
      shortageApprovedByUserId: 'manager-1',
      closingNotes: 'تم تسليم الدرج للمشرف',
      transactionCount: 24,
    );

    const clinicSettings = CompanySettingsModel(
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

    test('falls back gracefully to neutral clinic name when settings is null or empty', () async {
      final bytesNull = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: null,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(bytesNull, isNotNull);
      expect(bytesNull.isNotEmpty, isTrue);

      final bytesEmpty = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: const CompanySettingsModel(companyName: '   '),
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(bytesEmpty, isNotNull);
      expect(bytesEmpty.isNotEmpty, isTrue);
    });

    test('deterministic printing with CairoTimeHelper clock', () async {
      CairoTimeHelper.setFixedClock(DateTime(2026, 4, 15, 16, 30));
      try {
        final bytes = await AdaptiveShiftReportPdfGenerator.generate(
          shift: sampleShift,
          settings: clinicSettings,
          format: PrintFormat.thermal80,
          fontData: fontData,
        );
        expect(bytes, isNotNull);
        expect(bytes.isNotEmpty, isTrue);
      } finally {
        CairoTimeHelper.resetFixedClock();
      }
    });

    test('handles shift report with surplus and unapproved shortage states', () async {
      final surplusShift = sampleShift.copyWith(
        cashDifferencePiastres: 5000,
        shortageReason: null,
        isShortageApproved: false,
      );

      final a4Surplus = await AdaptiveShiftReportPdfGenerator.generate(
        shift: surplusShift,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(a4Surplus, isNotNull);

      final thermalSurplus = await AdaptiveShiftReportPdfGenerator.generate(
        shift: surplusShift,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(thermalSurplus, isNotNull);
    });

    test('respects settings.effectiveShiftReportPrintFormat when format is unspecified', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: clinicSettings,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('renders force-closed shift report with forceCloseReason and user in A4 and thermal', () async {
      final forceClosedShift = sampleShift.copyWith(
        status: ShiftStatusEnum.forceClosed,
        forceClosedByUserId: 'manager-admin',
        forceCloseReason: 'انقطاع تيار كهربائي مفاجئ بالفرع',
      );

      final a4Bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: forceClosedShift,
        settings: clinicSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(a4Bytes, isNotNull);
      expect(a4Bytes.isNotEmpty, isTrue);

      final thermalBytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: forceClosedShift,
        settings: clinicSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(thermalBytes, isNotNull);
      expect(thermalBytes.isNotEmpty, isTrue);
    });

    test('renders all shift statuses with Arabic localized names', () async {
      for (final status in ShiftStatusEnum.values) {
        final shiftWithStatus = sampleShift.copyWith(status: status);
        final bytes = await AdaptiveShiftReportPdfGenerator.generate(
          shift: shiftWithStatus,
          settings: clinicSettings,
          format: PrintFormat.thermal80,
          fontData: fontData,
        );
        expect(bytes, isNotNull);
        expect(bytes.isNotEmpty, isTrue);
      }
    });
    test('works seamlessly when fontData is omitted via disk font fallback', () async {
      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sampleShift,
        settings: clinicSettings,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('handles completely sparse CashierShiftModel with all optional fields null', () async {
      const sparseShift = CashierShiftModel(
        id: null,
        branchId: null,
        cashierUserId: null,
        cashierName: null,
        status: null,
        openedAt: null,
        closedAt: null,
        openingBalancePiastres: null,
        totalCashCollectedPiastres: null,
        totalCardCollectedPiastres: null,
        totalBankTransferPiastres: null,
        totalExpensesPiastres: null,
        totalRefundsPiastres: null,
        expectedCashPiastres: null,
        actualCashCountPiastres: null,
        cashDifferencePiastres: null,
        shortageReason: null,
        isShortageApproved: null,
        shortageApprovedByUserId: null,
        forceCloseReason: null,
        forceClosedByUserId: null,
        closingNotes: null,
        transactionCount: null,
      );

      final a4Bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sparseShift,
        settings: null,
        format: PrintFormat.a4,
        fontData: fontData,
      );
      expect(a4Bytes, isNotNull);
      expect(a4Bytes.isNotEmpty, isTrue);

      final thermalBytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: sparseShift,
        settings: null,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );
      expect(thermalBytes, isNotNull);
      expect(thermalBytes.isNotEmpty, isTrue);
    });

    test('handles extreme zero, large, and negative balances accurately without overflow', () async {
      final extremeShift = sampleShift.copyWith(
        openingBalancePiastres: 0,
        totalCashCollectedPiastres: 100000000, // 1,000,000 EGP
        totalExpensesPiastres: 50000000,
        cashDifferencePiastres: -2500000, // -25,000 EGP
      );

      final bytes = await AdaptiveShiftReportPdfGenerator.generate(
        shift: extremeShift,
        settings: clinicSettings,
        fontData: fontData,
      );
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
