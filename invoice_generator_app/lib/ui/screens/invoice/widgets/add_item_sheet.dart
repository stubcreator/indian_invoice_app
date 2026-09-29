import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/gst_slabs.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/invoice_item_model.dart';
import '../../../../data/models/item_model.dart';
import '../../../../providers/item_provider.dart';
import '../../../common/app_button.dart';

class AddItemSheet extends StatefulWidget {
  final bool isIntraState;
  final bool isGstMode;
  final String currencySymbol;
  final String currencyCode;
  final InvoiceItemModel? initialItem; // For editing
  final Function(InvoiceItemModel item) onItemAdded;

  const AddItemSheet({
    super.key,
    required this.isIntraState,
    required this.isGstMode,
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.initialItem,
    required this.onItemAdded,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _discountController = TextEditingController(text: '0');

  String _selectedUnit = 'PCS';
  double _selectedGstRate = 18.0;
  int? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.initialItem != null ? 1 : 2, vsync: this);

    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameController.text = item.itemName;
      _descController.text = item.description ?? '';
      _hsnController.text = item.hsnSacCode ?? '';
      _priceController.text = item.unitPrice.toString();
      _qtyController.text = item.quantity.toString();
      _discountController.text = item.discountAmount.toString();
      _selectedUnit = item.unit;
      _selectedGstRate = item.gstRate;
      _selectedItemId = item.itemId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _hsnController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _populateFromCatalog(ItemModel item) {
    setState(() {
      _selectedItemId = item.id;
      _nameController.text = item.name;
      _descController.text = item.description ?? '';
      _hsnController.text = item.hsnSacCode ?? '';
      _priceController.text = item.unitPrice.toString();
      _selectedUnit = item.unit;
      _selectedGstRate = item.gstRate;
      _tabController.animateTo(0);
    });
  }

  InvoiceItemModel _computeCurrentItem() {
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    return InvoiceItemModel.calculate(
      id: widget.initialItem?.id,
      invoiceId: widget.initialItem?.invoiceId,
      itemId: _selectedItemId,
      itemName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Item',
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      hsnSacCode: _hsnController.text.trim().isNotEmpty ? _hsnController.text.trim() : null,
      quantity: qty,
      unit: _selectedUnit,
      unitPrice: price,
      discountAmount: discount,
      gstRate: _selectedGstRate,
      isIntraState: widget.isIntraState,
      isGstMode: widget.isGstMode,
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final computed = _computeCurrentItem();
      widget.onItemAdded(computed);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final preview = _computeCurrentItem();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialItem != null ? 'Edit Invoice Item' : 'Add Invoice Item',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          if (widget.initialItem == null) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Item Details'),
                Tab(text: 'Pick from Catalog'),
              ],
            ),
          ],
          const SizedBox(height: 12),

          Expanded(
            child: widget.initialItem != null
                ? _buildFormView(preview)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFormView(preview),
                      _buildCatalogPicker(itemProvider),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPicker(ItemProvider itemProvider) {
    if (itemProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (itemProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('No products in catalog yet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Enter Custom Item'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: itemProvider.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = itemProvider.items[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${item.hsnSacCode != null ? "HSN: ${item.hsnSacCode} | " : ""}GST: ${item.gstRate.toStringAsFixed(1)}% | Unit: ${item.unit}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Text(
            CurrencyFormatter.format(item.unitPrice, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
          ),
          onTap: () => _populateFromCatalog(item),
        );
      },
    );
  }

  Widget _buildFormView(InvoiceItemModel preview) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // Item Name
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              hintText: 'e.g. Website Development or Cotton T-Shirt',
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter item name' : null,
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: _descController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Detailed specifications, batch no, etc.',
            ),
          ),
          const SizedBox(height: 12),

          // HSN/SAC Code & Unit
          Row(
            children: [
              if (widget.isGstMode) ...[
                Expanded(
                  child: TextFormField(
                    controller: _hsnController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'HSN / SAC Code',
                      hintText: 'e.g. 998311',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: GstSlabs.commonUnits.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Unit Price & Quantity
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Rate / Unit Price *',
                    prefixText: '${widget.currencySymbol} ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter price';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter quantity';
                    if ((double.tryParse(v) ?? 0) <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GST Slab & Item Discount
          Row(
            children: [
              if (widget.isGstMode) ...[
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: _selectedGstRate,
                    decoration: const InputDecoration(labelText: 'GST Slab Rate'),
                    items: GstSlabs.standardRates.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text('${r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 2)}%'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGstRate = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Discount',
                    prefixText: '${widget.currencySymbol} ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Calculation Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxable Value:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      CurrencyFormatter.format(preview.taxableAmount, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (widget.isGstMode && widget.isIntraState && preview.gstRate > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CGST (${(preview.gstRate / 2).toStringAsFixed(1)}%):',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(preview.cgstAmount, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SGST (${(preview.gstRate / 2).toStringAsFixed(1)}%):',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(preview.sgstAmount, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ] else if (preview.gstRate > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('IGST / Tax (${preview.gstRate.toStringAsFixed(1)}%):',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(preview.igstAmount, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Line Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(
                      CurrencyFormatter.format(preview.totalAmount, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AppButton(
            text: widget.initialItem != null ? 'Update Item' : 'Add Item to Invoice',
            onPressed: _submit,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}
