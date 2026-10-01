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
  final TextEditingController _searchCatalogController = TextEditingController();

  String _selectedUnit = 'PCS';
  double _selectedGstRate = 18.0;
  int? _selectedItemId;
  String _catalogSearchQuery = '';

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
    _searchCatalogController.dispose();
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
      _tabController.animateTo(1);
    });
  }

  void _addDirectlyFromCatalog(ItemModel item) {
    final computed = InvoiceItemModel.calculate(
      itemId: item.id,
      itemName: item.name,
      description: item.description,
      hsnSacCode: item.hsnSacCode,
      quantity: 1.0,
      unit: item.unit,
      unitPrice: item.unitPrice,
      discountAmount: 0.0,
      gstRate: item.gstRate,
      isIntraState: widget.isIntraState,
      isGstMode: widget.isGstMode,
    );
    widget.onItemAdded(computed);
    Navigator.pop(context);
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
                widget.initialItem != null ? 'Edit Invoice Item' : 'Add Item to Invoice',
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
                Tab(text: 'Saved Catalog'),
                Tab(text: 'Custom Item'),
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
                      _buildCatalogPicker(itemProvider),
                      _buildFormView(preview),
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
            const Text(
              'No items in your catalog yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create items in the Catalog tab or enter details directly',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Enter Custom Item'),
            ),
          ],
        ),
      );
    }

    final filtered = itemProvider.items.where((i) {
      if (_catalogSearchQuery.isEmpty) return true;
      final q = _catalogSearchQuery.toLowerCase();
      return i.name.toLowerCase().contains(q) ||
          (i.hsnSacCode != null && i.hsnSacCode!.toLowerCase().contains(q)) ||
          (i.description != null && i.description!.toLowerCase().contains(q));
    }).toList();

    return Column(
      children: [
        // Search in catalog
        TextField(
          controller: _searchCatalogController,
          onChanged: (v) => setState(() => _catalogSearchQuery = v.trim()),
          decoration: InputDecoration(
            hintText: 'Search catalog items...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            isDense: true,
            suffixIcon: _searchCatalogController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCatalogController.clear();
                      setState(() => _catalogSearchQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No catalog items match your search', style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: (item.isService ? AppColors.accent : AppColors.primary).withValues(alpha: 0.1),
                        child: Icon(
                          item.isService ? Icons.miscellaneous_services_rounded : Icons.inventory_2_rounded,
                          color: item.isService ? AppColors.accent : AppColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        '${item.hsnSacCode != null && item.hsnSacCode!.isNotEmpty ? "HSN: ${item.hsnSacCode} • " : ""}GST: ${item.gstRate.toStringAsFixed(0)}% • ${item.unit}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(item.unitPrice, symbol: widget.currencySymbol, currencyCode: widget.currencyCode),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _addDirectlyFromCatalog(item),
                            child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      onTap: () => _populateFromCatalog(item),
                    );
                  },
                ),
        ),
      ],
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
                    decoration: const InputDecoration(
                      labelText: 'HSN / SAC Code',
                      hintText: 'e.g. 998314',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(value: 'PCS', child: Text('PCS (Pieces)')),
                    DropdownMenuItem(value: 'NOS', child: Text('NOS (Numbers)')),
                    DropdownMenuItem(value: 'KGS', child: Text('KGS (Kilograms)')),
                    DropdownMenuItem(value: 'MTR', child: Text('MTR (Meters)')),
                    DropdownMenuItem(value: 'BOX', child: Text('BOX (Boxes)')),
                    DropdownMenuItem(value: 'HRS', child: Text('HRS (Hours)')),
                    DropdownMenuItem(value: 'DAYS', child: Text('DAYS (Days)')),
                    DropdownMenuItem(value: 'SET', child: Text('SET (Sets)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedUnit = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quantity & Unit Price
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Invalid qty';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Unit Price *',
                    prefixText: '${widget.currencySymbol} ',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Invalid price';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GST Rate & Discount
          Row(
            children: [
              if (widget.isGstMode) ...[
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: _selectedGstRate,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'GST Rate'),
                    items: GstSlabs.standardRates.map((rate) {
                      return DropdownMenuItem(
                        value: rate,
                        child: Text('${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 2)}%'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedGstRate = v);
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
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
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
