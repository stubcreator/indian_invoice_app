import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/invoice_provider.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../../common/status_badge.dart';
import '../pdf_preview/pdf_preview_screen.dart';
import '../pdf_preview/templates/gst_tax_invoice_template.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    final inv = await context.read<InvoiceProvider>().getInvoice(widget.invoiceId);
    if (mounted) {
      setState(() {
        _invoice = inv;
        _isLoading = false;
      });
    }
  }

  void _showRecordPaymentDialog() {
    if (_invoice == null) return;

    final amountController = TextEditingController(
      text: _invoice!.balanceDue > 0 ? _invoice!.balanceDue.toStringAsFixed(2) : '',
    );
    String selectedMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Payment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Balance Due: ${CurrencyFormatter.format(_invoice!.balanceDue, symbol: _invoice!.currencySymbol, currencyCode: _invoice!.currencyCode)}',
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Payment Amount *',
                      prefixText: '${_invoice!.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode'),
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay, PhonePe, Paytm)')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/RTGS/IMPS)')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'Card', child: Text('Debit / Credit Card')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedMode = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Confirm Payment',
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0) return;

                      final success = await context.read<InvoiceProvider>().recordPayment(
                            invoiceId: _invoice!.id!,
                            amount: amount,
                            paymentMode: selectedMode,
                          );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _loadInvoice();
                      }
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareInvoice() async {
    if (_invoice == null) return;
    try {
      final pdfBytes = await GstTaxInvoiceTemplate.generate(_invoice!);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Invoice_${_invoice!.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Tax Invoice #${_invoice!.invoiceNumber} from ${_invoice!.business?.businessName ?? ""}. Total: ${_invoice!.currencySymbol} ${_invoice!.grandTotal.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_invoice == null) {
      return const Scaffold(
        body: Center(child: Text('Invoice not found')),
      );
    }

    final inv = _invoice!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #${inv.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Share Invoice',
            onPressed: _shareInvoice,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateInvoiceScreen(editInvoiceId: inv.id)),
                );
                _loadInvoice();
              } else if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Invoice?'),
                    content: const Text('Are you sure you want to delete this invoice permanently?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await context.read<InvoiceProvider>().deleteInvoice(inv.id!);
                  if (mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.danger))])),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Top Status & Amount Header Card
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '# ${inv.invoiceNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    StatusBadge(status: inv.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyFormatter.format(inv.grandTotal, symbol: inv.currencySymbol, currencyCode: inv.currencyCode),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Paid: ${CurrencyFormatter.format(inv.paidAmount, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Balance: ${CurrencyFormatter.format(inv.balanceDue, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Preview PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: inv)),
                          );
                        },
                      ),
                    ),
                    if (inv.balanceDue > 0) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Record Payment',
                          isOutlined: true,
                          icon: Icons.payment_rounded,
                          onPressed: _showRecordPaymentDialog,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Customer & Place of Supply
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(inv.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (inv.clientCompanyName != null) Text(inv.clientCompanyName!, style: const TextStyle(color: AppColors.textSecondary)),
                if (inv.clientGstin != null && inv.clientGstin!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('GSTIN: ${inv.clientGstin}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
                if (inv.placeOfSupply != null && inv.placeOfSupply!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Place of Supply: ${inv.placeOfSupply} (${inv.placeOfSupplyCode ?? ""})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Items Summary
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items (${inv.items.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...inv.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${item.quantity} ${item.unit} × ${CurrencyFormatter.format(item.unitPrice, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)} (GST ${item.gstRate}%)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalAmount, symbol: inv.currencySymbol, currencyCode: inv.currencyCode),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                _buildSummaryLine('Subtotal', inv.subtotal, inv),
                if (inv.discountAmount > 0) _buildSummaryLine('Discount', -inv.discountAmount, inv, isNegative: true),
                if (inv.totalCgst > 0) _buildSummaryLine('CGST', inv.totalCgst, inv),
                if (inv.totalSgst > 0) _buildSummaryLine('SGST', inv.totalSgst, inv),
                if (inv.totalIgst > 0) _buildSummaryLine('IGST', inv.totalIgst, inv),
                if (inv.shippingCharge > 0) _buildSummaryLine('Shipping', inv.shippingCharge, inv),
                if (inv.roundOff != 0) _buildSummaryLine('Round Off', inv.roundOff, inv),
                const Divider(height: 12),
                _buildSummaryLine('Grand Total', inv.grandTotal, inv, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Payment History (if any)
          if (inv.payments.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...inv.payments.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.successLight,
                        child: Icon(Icons.check, size: 16, color: AppColors.success),
                      ),
                      title: Text(
                        CurrencyFormatter.format(p.amount, symbol: inv.currencySymbol, currencyCode: inv.currencyCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${p.paymentMode} • ${p.paymentDate}'),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, double amount, InvoiceModel inv, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 13)),
          Text(
            CurrencyFormatter.format(amount, symbol: inv.currencySymbol, currencyCode: inv.currencyCode),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
              color: isNegative ? AppColors.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}
