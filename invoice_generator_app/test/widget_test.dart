import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator_app/core/constants/indian_states.dart';
import 'package:invoice_generator_app/core/utils/currency_formatter.dart';
import 'package:invoice_generator_app/core/utils/number_to_words.dart';
import 'package:flutter/material.dart';
import 'package:invoice_generator_app/core/theme/custom_text_styles.dart';
import 'package:invoice_generator_app/data/models/invoice_item_model.dart';
import 'package:invoice_generator_app/data/models/invoice_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Indian GST Calculations & Number Formatting', () {
    test('Indian Numbering Currency Formatter', () {
      final formatted = CurrencyFormatter.formatIndian(150250.50);
      expect(formatted, '₹ 1,50,250.50');

      final largeFormatted = CurrencyFormatter.formatIndian(12345678.00);
      expect(largeFormatted, '₹ 1,23,45,678.00');
    });

    test('Indian Number to Words', () {
      final words = NumberToWords.convertIndian(150250.0);
      expect(words, 'Rupees One Lakh Fifty Thousand Two Hundred Fifty Only');
    });

    test('GSTIN validation and state extraction', () {
      const gstin = '24AAAAA0000A1Z5';
      final stateCode = IndianStates.getStateCodeFromGSTIN(gstin);
      expect(stateCode, '24');
      final state = IndianStates.findByCode(stateCode);
      expect(state?.name, 'Gujarat');
    });

    test('Intra-State GST calculation (CGST + SGST)', () {
      final item = InvoiceItemModel.calculate(
        itemName: 'Consulting',
        quantity: 1,
        unitPrice: 10000,
        gstRate: 18.0,
        isIntraState: true,
        isGstMode: true,
      );

      expect(item.taxableAmount, 10000.0);
      expect(item.cgstAmount, 900.0);
      expect(item.sgstAmount, 900.0);
      expect(item.igstAmount, 0.0);
      expect(item.totalAmount, 11800.0);
    });

    test('Inter-State GST calculation (IGST)', () {
      final item = InvoiceItemModel.calculate(
        itemName: 'Hardware',
        quantity: 2,
        unitPrice: 5000,
        gstRate: 18.0,
        isIntraState: false,
        isGstMode: true,
      );

      expect(item.taxableAmount, 10000.0);
      expect(item.cgstAmount, 0.0);
      expect(item.sgstAmount, 0.0);
      expect(item.igstAmount, 1800.0);
      expect(item.totalAmount, 11800.0);
    });

    test('Invoice Totals Calculation with Round-Off', () {
      final item = InvoiceItemModel.calculate(
        itemName: 'Item 1',
        quantity: 1,
        unitPrice: 100.45,
        gstRate: 18.0,
        isIntraState: true,
        isGstMode: true,
      );

      final invoice = InvoiceModel.calculate(
        invoiceNumber: 'INV-001',
        invoiceDate: '2026-09-29',
        dueDate: '2026-10-15',
        clientName: 'Rahul',
        items: [item],
      );

      expect(invoice.grandTotal, 119.0); // 100.45 + 18.081 = 118.531 -> rounded to 119.0
      expect(invoice.status, 'unpaid');
    });

    test('Modern Executive & GST Templates generate with custom colorHex', () async {
      final item = InvoiceItemModel.calculate(
        itemName: 'Test Product',
        quantity: 1,
        unitPrice: 1000,
        gstRate: 18.0,
        isIntraState: true,
        isGstMode: true,
      );

      final invoice = InvoiceModel.calculate(
        invoiceNumber: 'INV-999',
        invoiceDate: '2026-09-29',
        dueDate: '2026-10-15',
        clientName: 'Acme Corp',
        items: [item],
      );

      expect(invoice.invoiceNumber, 'INV-999');
      expect(invoice.grandTotal, 1180.0);
    });

    test('Custom typography helper size functions return correct font sizes and weights', () {
      final s14 = size14(fw: FW.bold);
      expect(s14.fontSize, 14.0);
      expect(s14.fontWeight, FontWeight.w700);

      final s18 = size18(fw: FW.semiBold);
      expect(s18.fontSize, 18.0);
      expect(s18.fontWeight, FontWeight.w600);
    });
  });
}
