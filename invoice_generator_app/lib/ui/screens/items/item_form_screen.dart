import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/gst_slabs.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/item_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_button.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemModel? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _hsnController;
  late TextEditingController _priceController;

  String _selectedUnit = 'PCS';
  double _selectedGstRate = 18.0;
  bool _isService = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final itm = widget.item;
    _nameController = TextEditingController(text: itm?.name ?? '');
    _descController = TextEditingController(text: itm?.description ?? '');
    _hsnController = TextEditingController(text: itm?.hsnSacCode ?? '');
    _priceController = TextEditingController(text: itm != null ? itm.unitPrice.toString() : '');
    _selectedUnit = itm?.unit ?? 'PCS';
    _selectedGstRate = itm?.gstRate ?? 18.0;
    _isService = itm?.isService ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _hsnController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final price = double.tryParse(_priceController.text) ?? 0.0;

    final itemModel = ItemModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      hsnSacCode: _hsnController.text.trim().isNotEmpty ? _hsnController.text.trim() : null,
      unitPrice: price,
      unit: _selectedUnit,
      gstRate: _selectedGstRate,
      isService: _isService,
    );

    final provider = context.read<ItemProvider>();
    ItemModel? result;

    if (widget.item == null) {
      result = await provider.addItem(itemModel);
    } else {
      final updated = await provider.updateItem(itemModel);
      if (updated) result = itemModel;
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item to Catalog'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Item Type Toggle (Goods vs Service)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Goods (HSN)'), icon: Icon(Icons.inventory_2_outlined)),
                ButtonSegment(value: true, label: Text('Service (SAC)'), icon: Icon(Icons.miscellaneous_services_outlined)),
              ],
              selected: {_isService},
              onSelectionChanged: (val) {
                setState(() => _isService = val.first);
              },
            ),
            const SizedBox(height: 16),

            // Item Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _isService ? 'Service Name *' : 'Product / Item Name *',
                hintText: _isService ? 'e.g. Website Consulting' : 'e.g. Steel Pipe 2 inch',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Detailed specifications, grade, model...',
              ),
            ),
            const SizedBox(height: 12),

            // HSN / SAC Code
            if (settings.isGstMode) ...[
              TextFormField(
                controller: _hsnController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isService ? 'SAC Code (Optional)' : 'HSN Code (Optional)',
                  hintText: _isService ? 'e.g. 998311' : 'e.g. 847130',
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Unit Price and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Selling Price *',
                      prefixText: '${settings.currencySymbol} ',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter price';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
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

            // GST Slab Rate Dropdown
            if (settings.isGstMode) ...[
              DropdownButtonFormField<double>(
                value: _selectedGstRate,
                decoration: const InputDecoration(labelText: 'Default GST Rate (%)'),
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
              const SizedBox(height: 24),
            ],

            AppButton(
              text: isEditing ? 'Save Changes' : 'Add to Catalog',
              isLoading: _isLoading,
              onPressed: _saveItem,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
