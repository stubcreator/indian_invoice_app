import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart';
import 'templates/gst_tax_invoice_template.dart';
import 'templates/modern_executive_template.dart';

class PdfPreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  int _selectedTemplate = 1; // 1: Indian GST Tax Invoice, 2: Modern Executive

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.invoice.templateId;
  }

  Future<Uint8List> _generatePdf() async {
    if (_selectedTemplate == 2) {
      return await ModernExecutiveTemplate.generate(widget.invoice);
    } else {
      return await GstTaxInvoiceTemplate.generate(widget.invoice);
    }
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await _generatePdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Invoice_${widget.invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Invoice #${widget.invoice.invoiceNumber} from ${widget.invoice.business?.businessName ?? "us"}. Total: ${widget.invoice.currencySymbol} ${widget.invoice.grandTotal.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Share Invoice PDF',
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Template Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Text(
                  'Template:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                _buildTemplateChip(1, '🇮🇳 GST Tax Invoice'),
                const SizedBox(width: 8),
                _buildTemplateChip(2, '🌐 Modern Executive'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Live PDF Viewer
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 700,
              dynamicLayout: false,
              allowSharing: true,
              allowPrinting: true,
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(int templateId, String label) {
    final isSelected = _selectedTemplate == templateId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTemplate = templateId;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
