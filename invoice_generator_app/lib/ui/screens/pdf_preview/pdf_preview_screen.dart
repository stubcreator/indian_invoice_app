import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/invoice_provider.dart';
import '../thank_you/thank_you_screen.dart';
import 'templates/gst_tax_invoice_template.dart';
import 'templates/modern_executive_template.dart';

class PdfPreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late int _selectedTemplate;
  late String _selectedColorHex;
  bool _isSaving = false;

  final List<String> _colorPalette = [
    '#1E3A8A', // Deep Royal Blue
    '#4F46E5', // Modern Indigo
    '#7C3AED', // Royal Purple
    '#059669', // Emerald Green
    '#B91C1C', // Crimson Red
    '#D97706', // Warm Amber
    '#0D9488', // Teal
    '#1F2937', // Charcoal Slate
  ];

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.invoice.templateId > 0 ? widget.invoice.templateId : 1;
    _selectedColorHex = widget.invoice.colorHex.isNotEmpty ? widget.invoice.colorHex : '#1E3A8A';
  }

  Future<Uint8List> _generatePdf() async {
    if (_selectedTemplate == 2) {
      return await ModernExecutiveTemplate.generate(widget.invoice, colorHex: _selectedColorHex);
    } else {
      return await GstTaxInvoiceTemplate.generate(widget.invoice, colorHex: _selectedColorHex);
    }
  }

  Future<void> _saveAndProceedToThankYou() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Update template and color in provider/DB if invoice is persisted
      if (widget.invoice.id != null) {
        await context.read<InvoiceProvider>().updateInvoiceTemplate(
          widget.invoice.id!,
          _selectedTemplate,
          colorHex: _selectedColorHex,
        );
      }

      // 2. Generate final PDF bytes with selected template & color
      final bytes = await _generatePdf();

      if (!mounted) return;

      // 3. Move to Thank You screen (where Download, Share, Email, Home actions live)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ThankYouScreen(
            invoice: widget.invoice.copyWith(templateId: _selectedTemplate, colorHex: _selectedColorHex),
            pdfBytes: bytes,
            colorHex: _selectedColorHex,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save invoice: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openCustomColorPicker() {
    Color currentColor = Color(int.parse(_selectedColorHex.replaceAll('#', '0xFF')));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Brand Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (newColor) {
              final hex = '#${newColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              setState(() {
                _selectedColorHex = hex;
              });
              Navigator.pop(ctx);
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Invoice #${widget.invoice.invoiceNumber}')),
      body: Column(
        children: [
          // Customization Controls: Color Picker + Template Selector
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Color Picker Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ..._colorPalette.map((hex) => _buildColorDot(hex)),
                          // const SizedBox(width: 5),
                          // Custom color picker button
                          Spacer(),
                          InkWell(
                            onTap: _openCustomColorPicker,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryDark, width: 1.5),
                                gradient: const SweepGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.cyan,
                                    Colors.blue,
                                    Colors.purple,
                                    Colors.red,
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.add, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Template Selector Row
                Row(
                  children: [
                    const Text(
                      'Template:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTemplateChip(1, '🇮🇳 GST Tax Invoice'),
                            const SizedBox(width: 8),
                            _buildTemplateChip(2, '🌐 Modern Executive'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Live PDF Preview (Preview only - no download/share inside preview screen)
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 700,
              dynamicLayout: false,
              allowSharing: false,
              allowPrinting: false,
              loadingWidget: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAndProceedToThankYou,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save & Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(String hex) {
    final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
    final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColorHex = hex;
        });
      },
      child: Container(
        width: 29,
        height: 29,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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
