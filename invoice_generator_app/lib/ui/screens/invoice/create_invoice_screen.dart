import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../pdf_preview/pdf_preview_screen.dart';
import 'widgets/add_item_sheet.dart';
import 'widgets/client_select_sheet.dart';
import 'widgets/signature_sheet.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final int? editInvoiceId;

  const CreateInvoiceScreen({super.key, this.editInvoiceId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numberController;
  late TextEditingController _poController;
  late TextEditingController _discountController;
  late TextEditingController _shippingController;
  late TextEditingController _termsController;
  late TextEditingController _notesController;

  bool _isInit = false;
  String _discountType = 'flat'; // 'flat' or 'percent'

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
    _poController = TextEditingController();
    _discountController = TextEditingController(text: '0');
    _shippingController = TextEditingController(text: '0');
    _termsController = TextEditingController();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final invoiceProv = context.read<InvoiceProvider>();
    final bizProv = context.read<BusinessProvider>();
    final setProv = context.read<SettingsProvider>();

    if (widget.editInvoiceId != null) {
      await invoiceProv.loadDraftForEdit(widget.editInvoiceId!);
    } else {
      await invoiceProv.initNewDraft(
        business: bizProv.business,
        settings: setProv.settings,
      );
    }

    final draft = invoiceProv.draftInvoice;
    if (draft != null) {
      _numberController.text = draft.invoiceNumber;
      _poController.text = draft.poNumber ?? '';
      _discountController.text = draft.discountRate > 0 ? draft.discountRate.toString() : '0';
      _shippingController.text = draft.shippingCharge > 0 ? draft.shippingCharge.toString() : '0';
      _discountType = draft.discountType;
      _termsController.text = draft.termsConditions ?? '';
      _notesController.text = draft.notes ?? '';
    }

    setState(() {
      _isInit = true;
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _poController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isDueDate) async {
    final invoiceProv = context.read<InvoiceProvider>();
    final draft = invoiceProv.draftInvoice;
    if (draft == null) return;

    final currentStr = isDueDate ? draft.dueDate : draft.invoiceDate;
    final initialDate = DateFormatter.parse(currentStr) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final isoStr = DateFormatter.formatIso(picked);
      if (isDueDate) {
        invoiceProv.updateDraftHeader(dueDate: isoStr);
      } else {
        invoiceProv.updateDraftHeader(invoiceDate: isoStr);
      }
    }
  }

  void _openClientSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientSelectSheet(
        onClientSelected: (client) {
          context.read<InvoiceProvider>().setDraftClient(client);
        },
      ),
    );
  }

  void _openAddItemSheet({int? editIndex}) {
    final invoiceProv = context.read<InvoiceProvider>();
    final draft = invoiceProv.draftInvoice;
    if (draft == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        isIntraState: invoiceProv.isDraftIntraState,
        isGstMode: draft.taxMode.toLowerCase() == 'gst',
        currencySymbol: draft.currencySymbol,
        currencyCode: draft.currencyCode,
        initialItem: editIndex != null ? draft.items[editIndex] : null,
        onItemAdded: (item) {
          if (editIndex != null) {
            invoiceProv.updateDraftItem(editIndex, item);
          } else {
            invoiceProv.addDraftItem(item);
          }
        },
      ),
    );
  }

  void _openSignatureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SignatureSheet(
        onSignatureSaved: (path) {
          context.read<InvoiceProvider>().updateDraftHeader(signaturePath: path);
        },
      ),
    );
  }

  Future<void> _saveAndPreview() async {
    final invoiceProv = context.read<InvoiceProvider>();
    final draft = invoiceProv.draftInvoice;

    if (draft == null) return;

    if (draft.clientName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a Customer / Client')),
      );
      return;
    }

    if (draft.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item to the invoice')),
      );
      return;
    }

    // Update financial fields before saving
    final disc = double.tryParse(_discountController.text) ?? 0.0;
    final ship = double.tryParse(_shippingController.text) ?? 0.0;
    invoiceProv.updateDraftFinancials(
      overallDiscountInput: disc,
      discountType: _discountType,
      shippingCharge: ship,
    );
    invoiceProv.updateDraftHeader(
      invoiceNumber: _numberController.text.trim(),
      poNumber: _poController.text.trim().isNotEmpty ? _poController.text.trim() : null,
      termsConditions: _termsController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final savedId = await invoiceProv.saveDraft();
    if (savedId != null && mounted) {
      final savedInvoice = await invoiceProv.getInvoice(savedId);
      if (savedInvoice != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: savedInvoice)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save invoice. Please check fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final invoiceProv = context.watch<InvoiceProvider>();
    final draft = invoiceProv.draftInvoice;
    if (draft == null) {
      return const Scaffold(body: Center(child: Text('Error loading draft')));
    }

    final isIntra = invoiceProv.isDraftIntraState;
    final isGst = draft.taxMode.toLowerCase() == 'gst';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editInvoiceId != null ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          TextButton.icon(
            onPressed: _saveAndPreview,
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
            label: const Text(
              'Preview',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. INVOICE META CARD
            _buildInvoiceMetaCard(draft),
            const SizedBox(height: 12),

            // 2. CLIENT / CUSTOMER CARD
            _buildCustomerCard(draft, isIntra, isGst),
            const SizedBox(height: 12),

            // 3. LINE ITEMS CARD
            _buildItemsCard(draft),
            const SizedBox(height: 12),

            // 4. DISCOUNT, SHIPPING & CHARGES CARD
            _buildAdjustmentsCard(draft),
            const SizedBox(height: 12),

            // 5. PAYMENT, TERMS & SIGNATURE CARD
            _buildPaymentAndSignatureCard(draft),
            const SizedBox(height: 80), // Padding for bottom sticky bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSummaryBar(draft),
    );
  }

  Widget _buildInvoiceMetaCard(InvoiceModel draft) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoice Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  draft.currencyCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _numberController,
            decoration: const InputDecoration(
              labelText: 'Invoice Number *',
              prefixIcon: Icon(Icons.tag_rounded, size: 20),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter invoice number' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      DateFormatter.formatDisplay(DateFormatter.parse(draft.invoiceDate)),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: Icon(Icons.event_available_rounded, size: 18),
                    ),
                    child: Text(
                      DateFormatter.formatDisplay(DateFormatter.parse(draft.dueDate)),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _poController,
            decoration: const InputDecoration(
              labelText: 'PO Reference / Order # (Optional)',
              prefixIcon: Icon(Icons.receipt_long_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(InvoiceModel draft, bool isIntra, bool isGst) {
    final hasClient = draft.clientName.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer / Bill To',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: _openClientSelector,
                icon: Icon(hasClient ? Icons.swap_horiz_rounded : Icons.person_add_rounded, size: 18),
                label: Text(hasClient ? 'Change' : 'Select'),
              ),
            ],
          ),
          if (hasClient) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        draft.clientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (isGst)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isIntra ? AppColors.infoLight : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isIntra ? 'Intra-State (CGST + SGST)' : 'Inter-State (IGST)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isIntra ? AppColors.info : AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (draft.clientCompanyName != null && draft.clientCompanyName!.isNotEmpty)
                    Text(draft.clientCompanyName!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  if (draft.clientGstin != null && draft.clientGstin!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'GSTIN: ${draft.clientGstin}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                  if (draft.placeOfSupply != null && draft.placeOfSupply!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Place of Supply: ${draft.placeOfSupply}${draft.placeOfSupplyCode != null ? " (${draft.placeOfSupplyCode})" : ""}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: _openClientSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryLight, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.04),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tap to Select Customer',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(InvoiceModel draft) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Line Items (${draft.items.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              AppButton(
                text: 'Add Item',
                icon: Icons.add_rounded,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: () => _openAddItemSheet(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (draft.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.format_list_bulleted_add, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'No items added yet. Tap "Add Item" above.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: draft.items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = draft.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit} × ${CurrencyFormatter.format(item.unitPrice, symbol: draft.currencySymbol, currencyCode: draft.currencyCode)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (item.hsnSacCode != null && item.hsnSacCode!.isNotEmpty)
                            Text(
                              'HSN: ${item.hsnSacCode} | Tax: ${item.gstRate}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(item.totalAmount, symbol: draft.currencySymbol, currencyCode: draft.currencyCode),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _openAddItemSheet(editIndex: index),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                context.read<InvoiceProvider>().removeDraftItem(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsCard(InvoiceModel draft) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discount & Charges',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Overall Discount',
                    prefixText: _discountType == 'flat' ? '${draft.currencySymbol} ' : null,
                    suffixText: _discountType == 'percent' ? '%' : null,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    context.read<InvoiceProvider>().updateDraftFinancials(
                          overallDiscountInput: d,
                          discountType: _discountType,
                        );
                  },
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [_discountType == 'flat', _discountType == 'percent'],
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: AppColors.primary,
                constraints: const BoxConstraints(minHeight: 46, minWidth: 46),
                onPressed: (index) {
                  setState(() {
                    _discountType = index == 0 ? 'flat' : 'percent';
                  });
                  final d = double.tryParse(_discountController.text) ?? 0.0;
                  context.read<InvoiceProvider>().updateDraftFinancials(
                        overallDiscountInput: d,
                        discountType: _discountType,
                      );
                },
                children: [
                  Text(draft.currencySymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shippingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Shipping / Delivery Charge',
              prefixText: '${draft.currencySymbol} ',
            ),
            onChanged: (val) {
              final s = double.tryParse(val) ?? 0.0;
              context.read<InvoiceProvider>().updateDraftFinancials(shippingCharge: s);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndSignatureCard(InvoiceModel draft) {
    final hasSig = draft.signaturePath != null && File(draft.signaturePath!).existsSync();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms, Notes & Signature',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _termsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              hintText: 'Goods once sold will not be returned...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Customer Notes',
              hintText: 'Thank you for your business!',
            ),
          ),
          const SizedBox(height: 16),

          // Signature Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Authorized Signature', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: _openSignatureSheet,
                icon: const Icon(Icons.draw_rounded, size: 16),
                label: Text(hasSig ? 'Change' : 'Sign Now'),
              ),
            ],
          ),
          if (hasSig)
            Container(
              height: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Image.file(File(draft.signaturePath!), fit: BoxFit.contain),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryBar(InvoiceModel draft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grand Total (${draft.items.length} items)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      draft.grandTotal,
                      symbol: draft.currencySymbol,
                      currencyCode: draft.currencyCode,
                    ),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppButton(
                text: 'Save & Preview',
                icon: Icons.check_circle_rounded,
                onPressed: _saveAndPreview,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
