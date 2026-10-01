import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/invoice_model.dart';
import '../pdf_font_helper.dart';

class ModernExecutiveTemplate {
  static Future<Uint8List> generate(InvoiceModel invoice, {String? colorHex}) async {
    final pdf = pw.Document(theme: await PdfFontHelper.getPdfTheme());
    final business = invoice.business;

    pw.MemoryImage? logoImage;
    if (business?.logoPath != null && File(business!.logoPath!).existsSync()) {
      try {
        final bytes = await File(business.logoPath!).readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    if (invoice.signaturePath != null && File(invoice.signaturePath!).existsSync()) {
      try {
        final bytes = await File(invoice.signaturePath!).readAsBytes();
        signatureImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    final accentColor = colorHex != null
        ? PdfColor.fromHex(colorHex.replaceAll('#', ''))
        : PdfColor.fromHex('4F46E5'); // Modern Indigo
    final lightBg = colorHex != null
        ? PdfColor(accentColor.red, accentColor.green, accentColor.blue, 0.08)
        : PdfColor.fromHex('F5F3FF'); // Indigo 50
    final darkText = PdfColor.fromHex('1E1B4B');
    final mutedText = PdfColor.fromHex('6B7280');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Bar
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) ...[
                    pw.Container(height: 50, child: pw.Image(logoImage)),
                    pw.SizedBox(height: 6),
                  ],
                  pw.Text(
                    business?.businessName ?? 'COMPANY NAME',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: darkText),
                  ),
                  if (business?.fullAddress.isNotEmpty == true)
                    pw.Text(business!.fullAddress, style: pw.TextStyle(fontSize: 9, color: mutedText)),
                  if (business?.phone != null && business!.phone!.isNotEmpty)
                    pw.Text('Tel: ${business.phone}', style: pw.TextStyle(fontSize: 9, color: mutedText)),
                  if (business?.email != null && business!.email!.isNotEmpty)
                    pw.Text('Email: ${business.email}', style: pw.TextStyle(fontSize: 9, color: mutedText)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: accentColor)),
                  pw.SizedBox(height: 4),
                  pw.Text('# ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: ${invoice.invoiceDate}', style: pw.TextStyle(fontSize: 9, color: mutedText)),
                  pw.Text('Due: ${invoice.dueDate}', style: pw.TextStyle(fontSize: 9, color: mutedText)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Bill To Card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor)),
                      pw.SizedBox(height: 2),
                      pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      if (invoice.clientCompanyName != null)
                        pw.Text(invoice.clientCompanyName!, style: const pw.TextStyle(fontSize: 9)),
                      if (invoice.client?.billingAddress != null)
                        pw.Text(invoice.client!.billingAddress!, style: pw.TextStyle(fontSize: 9, color: mutedText)),
                    ],
                  ),
                ),
                if (invoice.placeOfSupply != null && invoice.placeOfSupply!.isNotEmpty) ...[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PLACE OF SUPPLY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor)),
                      pw.Text(invoice.placeOfSupply!, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // Items Table
          pw.TableHelper.fromTextArray(
            border: null,
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkText),
            headerDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: accentColor, width: 1.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            headers: ['Item', 'Qty', 'Price', 'Tax %', 'Total'],
            data: invoice.items.map((item) {
              return [
                item.itemName,
                '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                CurrencyFormatter.format(item.unitPrice, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
                '${item.gstRate.toStringAsFixed(1)}%',
                CurrencyFormatter.format(item.totalAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
              ];
            }).toList(),
          ),

          pw.Divider(color: PdfColors.grey300),

          pw.SizedBox(height: 12),

          // Financial Summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Notes
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.Text('Notes:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 8, color: mutedText)),
                      pw.SizedBox(height: 8),
                    ],
                    if (invoice.termsConditions != null && invoice.termsConditions!.isNotEmpty) ...[
                      pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.termsConditions!, style: pw.TextStyle(fontSize: 8, color: mutedText)),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(width: 24),

              // Totals
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildRow('Subtotal', invoice.subtotal, invoice),
                    if (invoice.discountAmount > 0)
                      _buildRow('Discount', -invoice.discountAmount, invoice, isNegative: true),
                    if ((invoice.totalCgst + invoice.totalSgst + invoice.totalIgst) > 0)
                      _buildRow('Total Tax', invoice.totalCgst + invoice.totalSgst + invoice.totalIgst, invoice),
                    if (invoice.shippingCharge > 0)
                      _buildRow('Shipping', invoice.shippingCharge, invoice),
                    pw.Divider(color: accentColor, thickness: 1),
                    _buildRow('Grand Total', invoice.grandTotal, invoice, isBold: true, fontSize: 12, color: accentColor),
                    if (invoice.paidAmount > 0) ...[
                      _buildRow('Paid', invoice.paidAmount, invoice, color: PdfColors.green700),
                      _buildRow('Balance Due', invoice.balanceDue, invoice, isBold: true, color: PdfColors.red700),
                    ],
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Signature
          if (signatureImage != null)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(height: 40, child: pw.Image(signatureImage)),
                  pw.Container(width: 120, height: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 2),
                  pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, double amount, InvoiceModel invoice,
      {bool isBold = false, bool isNegative = false, double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            CurrencyFormatter.format(amount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (isNegative ? PdfColors.red700 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
