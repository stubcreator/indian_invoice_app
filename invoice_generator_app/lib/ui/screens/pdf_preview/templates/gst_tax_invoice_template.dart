import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/number_to_words.dart';
import '../../../../core/utils/upi_helper.dart';
import '../../../../data/models/invoice_model.dart';
import '../pdf_font_helper.dart';

class GstTaxInvoiceTemplate {
  static Future<Uint8List> generate(InvoiceModel invoice, {String? colorHex}) async {
    final pdf = pw.Document(theme: await PdfFontHelper.getPdfTheme());

    final business = invoice.business;
    final isIntraState = invoice.totalIgst == 0 && (invoice.totalCgst > 0 || invoice.totalSgst > 0);
    final isGst = invoice.taxMode.toLowerCase() == 'gst';

    // Load logo if exists
    pw.MemoryImage? logoImage;
    if (business?.logoPath != null && File(business!.logoPath!).existsSync()) {
      try {
        final bytes = await File(business.logoPath!).readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    // Load signature if exists
    pw.MemoryImage? signatureImage;
    if (invoice.signaturePath != null && File(invoice.signaturePath!).existsSync()) {
      try {
        final bytes = await File(invoice.signaturePath!).readAsBytes();
        signatureImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    // UPI QR Code URI
    String? upiUri;
    if (business?.upiId != null && business!.upiId!.trim().isNotEmpty) {
      upiUri = UpiHelper.generateUpiUri(
        upiId: business.upiId!,
        payeeName: business.businessName,
        amount: invoice.balanceDue > 0 ? invoice.balanceDue : invoice.grandTotal,
        transactionNote: 'Invoice ${invoice.invoiceNumber}',
      );
    }

    final primaryColor = colorHex != null
        ? PdfColor.fromHex(colorHex.replaceAll('#', ''))
        : PdfColor.fromHex('1E3A8A');
    final mutedTextColor = PdfColor.fromHex('64748B');
    final borderColor = PdfColor.fromHex('CBD5E1');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // 1. Header Box
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Seller Info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          height: 48,
                          child: pw.Image(logoImage),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      pw.Text(
                        business?.businessName ?? 'YOUR BUSINESS NAME',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      if (business?.tradeName != null && business!.tradeName!.isNotEmpty)
                        pw.Text(business.tradeName!, style: pw.TextStyle(fontSize: 10, color: mutedTextColor)),
                      pw.SizedBox(height: 4),
                      if (business?.gstin != null && business!.gstin!.isNotEmpty)
                        pw.Text('GSTIN: ${business.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (business?.pan != null && business!.pan!.isNotEmpty)
                        pw.Text('PAN: ${business.pan}', style: const pw.TextStyle(fontSize: 9)),
                      if (business?.fullAddress.isNotEmpty == true)
                        pw.Text(business!.fullAddress, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      if (business?.phone != null && business!.phone!.isNotEmpty)
                        pw.Text('Phone: ${business.phone}', style: const pw.TextStyle(fontSize: 9)),
                      if (business?.email != null && business!.email!.isNotEmpty)
                        pw.Text('Email: ${business.email}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),

                // Invoice Title & Meta Box
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          isGst ? 'TAX INVOICE' : 'INVOICE',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Invoice No:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                          pw.Text(invoice.invoiceNumber, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Invoice Date:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                          pw.Text(invoice.invoiceDate, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Due Date:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                          pw.Text(invoice.dueDate, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      if (invoice.placeOfSupply != null && invoice.placeOfSupply!.isNotEmpty)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Place of Supply:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                            pw.Text(
                              '${invoice.placeOfSupply}${invoice.placeOfSupplyCode != null ? " (${invoice.placeOfSupplyCode})" : ""}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Reverse Charge:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                          pw.Text(invoice.isReverseCharge ? 'Yes' : 'No', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      if (invoice.poNumber != null && invoice.poNumber!.isNotEmpty)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('PO Ref:', style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                            pw.Text(invoice.poNumber!, style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // 2. Bill To & Ship To
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderColor, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO:',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        invoice.clientName,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      if (invoice.clientCompanyName != null && invoice.clientCompanyName!.isNotEmpty)
                        pw.Text(invoice.clientCompanyName!, style: const pw.TextStyle(fontSize: 9)),
                      if (invoice.clientGstin != null && invoice.clientGstin!.isNotEmpty)
                        pw.Text('GSTIN: ${invoice.clientGstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (invoice.client?.billingAddress != null && invoice.client!.billingAddress!.isNotEmpty)
                        pw.Text(invoice.client!.billingAddress!, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      if (invoice.client?.phone != null && invoice.client!.phone!.isNotEmpty)
                        pw.Text('Phone: ${invoice.client!.phone}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                if (invoice.client?.shippingAddress != null && invoice.client!.shippingAddress!.isNotEmpty) ...[
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHIPPED TO:',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.client!.shippingAddress!, style: pw.TextStyle(fontSize: 9, color: mutedTextColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // 3. Line Items Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            headers: [
              '#',
              'Item Description',
              'HSN/SAC',
              'Qty',
              'Rate',
              'Taxable',
              if (isGst && isIntraState) ...['CGST', 'SGST'] else if (isGst) ...['IGST'] else ...['Tax'],
              'Total',
            ],
            data: List.generate(invoice.items.length, (index) {
              final item = invoice.items[index];
              return [
                '${index + 1}',
                item.itemName + (item.description != null && item.description!.isNotEmpty ? '\n${item.description}' : ''),
                item.hsnSacCode ?? '-',
                '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                CurrencyFormatter.format(item.unitPrice, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
                CurrencyFormatter.format(item.taxableAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
                if (isGst && isIntraState) ...[
                  '${(item.gstRate / 2).toStringAsFixed(1)}%\n${CurrencyFormatter.format(item.cgstAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode)}',
                  '${(item.gstRate / 2).toStringAsFixed(1)}%\n${CurrencyFormatter.format(item.sgstAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode)}',
                ] else if (isGst) ...[
                  '${item.gstRate.toStringAsFixed(1)}%\n${CurrencyFormatter.format(item.igstAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode)}',
                ] else ...[
                  '${item.gstRate.toStringAsFixed(1)}%\n${CurrencyFormatter.format(item.igstAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode)}',
                ],
                CurrencyFormatter.format(item.totalAmount, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
              ];
            }),
          ),

          pw.SizedBox(height: 12),

          // 4. Totals and Banking / UPI Block
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Bank details & UPI QR
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F8FAFC'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderColor, width: 0.5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Bank Details Text
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BANK & PAYMENT DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.SizedBox(height: 4),
                            if (business?.bankName != null && business!.bankName!.isNotEmpty)
                              pw.Text('Bank: ${business.bankName}', style: const pw.TextStyle(fontSize: 8)),
                            if (business?.accountNumber != null && business!.accountNumber!.isNotEmpty)
                              pw.Text('A/C No: ${business.accountNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            if (business?.ifscCode != null && business!.ifscCode!.isNotEmpty)
                              pw.Text('IFSC: ${business.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                            if (business?.accountHolderName != null && business!.accountHolderName!.isNotEmpty)
                              pw.Text('A/C Name: ${business.accountHolderName}', style: const pw.TextStyle(fontSize: 8)),
                            if (business?.upiId != null && business!.upiId!.isNotEmpty)
                              pw.Text('UPI ID: ${business.upiId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      // UPI QR Code if available
                      if (upiUri != null) ...[
                        pw.SizedBox(width: 8),
                        pw.Column(
                          children: [
                            pw.Container(
                              height: 60,
                              width: 60,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: upiUri,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text('Scan to Pay (UPI)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              pw.SizedBox(width: 14),

              // Right: Calculations Summary
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Taxable Subtotal:', invoice.subtotal, invoice),
                    if (invoice.discountAmount > 0)
                      _buildSummaryRow('Discount:', -invoice.discountAmount, invoice, isNegative: true),
                    if (isGst && isIntraState) ...[
                      _buildSummaryRow('Total CGST:', invoice.totalCgst, invoice),
                      _buildSummaryRow('Total SGST:', invoice.totalSgst, invoice),
                    ] else if (isGst) ...[
                      _buildSummaryRow('Total IGST:', invoice.totalIgst, invoice),
                    ] else if (invoice.totalIgst > 0) ...[
                      _buildSummaryRow('Total Tax:', invoice.totalIgst, invoice),
                    ],
                    if (invoice.shippingCharge > 0)
                      _buildSummaryRow('Shipping / Delivery:', invoice.shippingCharge, invoice),
                    if (invoice.roundOff != 0)
                      _buildSummaryRow('Round Off:', invoice.roundOff, invoice),
                    pw.Divider(color: primaryColor, thickness: 1),
                    _buildSummaryRow('Grand Total:', invoice.grandTotal, invoice, isBold: true, fontSize: 11),
                    if (invoice.paidAmount > 0) ...[
                      pw.SizedBox(height: 4),
                      _buildSummaryRow('Amount Paid:', invoice.paidAmount, invoice, textColor: PdfColors.green800),
                      _buildSummaryRow('Balance Due:', invoice.balanceDue, invoice, isBold: true, textColor: PdfColors.red800),
                    ],
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // 5. Amount in Words Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F1F5F9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Text('Amount in Words: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(
                  child: pw.Text(
                    NumberToWords.toWords(invoice.grandTotal, currencyCode: invoice.currencyCode),
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // 6. Terms, Notes & Signature
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Terms & Notes
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (invoice.termsConditions != null && invoice.termsConditions!.isNotEmpty) ...[
                      pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(invoice.termsConditions!, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                    ],
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.Text('Notes:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(width: 20),

              // Signature
              pw.Container(
                width: 140,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 40,
                        child: pw.Image(signatureImage),
                      )
                    else
                      pw.SizedBox(height: 40),
                    pw.Container(height: 0.5, color: borderColor),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                    pw.Text(business?.businessName ?? '', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double value,
    InvoiceModel invoice, {
    bool isBold = false,
    bool isNegative = false,
    double fontSize = 8,
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
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            CurrencyFormatter.format(value, symbol: invoice.currencySymbol, currencyCode: invoice.currencyCode),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? (isNegative ? PdfColors.red800 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
