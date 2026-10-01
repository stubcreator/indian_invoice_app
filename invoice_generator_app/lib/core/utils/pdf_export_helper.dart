import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/invoice_model.dart';
import '../../ui/screens/pdf_preview/templates/gst_tax_invoice_template.dart';
import '../../ui/screens/pdf_preview/templates/modern_executive_template.dart';

class PdfExportHelper {
  /// Generates the raw PDF bytes using the invoice's saved template & color
  static Future<Uint8List> generatePdf(InvoiceModel invoice) async {
    if (invoice.templateId == 2) {
      return await ModernExecutiveTemplate.generate(invoice, colorHex: invoice.colorHex);
    } else {
      return await GstTaxInvoiceTemplate.generate(invoice, colorHex: invoice.colorHex);
    }
  }

  /// Writes PDF to device storage and immediately opens it via default viewer
  static Future<void> downloadAndOpenPdf(BuildContext context, InvoiceModel invoice) async {
    try {
      final bytes = await generatePdf(invoice);
      final dir = await getTemporaryDirectory();
      final cleanNum = invoice.invoiceNumber.replaceAll('/', '_').replaceAll('\\', '_');
      final file = File('${dir.path}/Invoice_$cleanNum.pdf');
      await file.writeAsBytes(bytes);
      debugPrint("PDF FILE PATH -->>  ${file.path}");
      final result = await OpenFile.open(file.path);
      if (context.mounted) {
        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice #${invoice.invoiceNumber} opened successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice saved at ${file.path}'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shares the PDF across apps (WhatsApp, Drive, etc.) using native share sheet
  static Future<void> sharePdf(BuildContext context, InvoiceModel invoice) async {
    try {
      final bytes = await generatePdf(invoice);
      final dir = await getTemporaryDirectory();
      final cleanNum = invoice.invoiceNumber.replaceAll('/', '_').replaceAll('\\', '_');
      final file = File('${dir.path}/Invoice_$cleanNum.pdf');
      await file.writeAsBytes(bytes);

      final bizName = invoice.business?.businessName ?? 'our company';
      final total = '${invoice.currencySymbol} ${invoice.grandTotal.toStringAsFixed(2)}';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice #${invoice.invoiceNumber} from $bizName',
        text: 'Invoice #${invoice.invoiceNumber} from $bizName. Total: $total',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
