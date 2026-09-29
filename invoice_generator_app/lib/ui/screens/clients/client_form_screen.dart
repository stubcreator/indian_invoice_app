import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/indian_states.dart';
import '../../../data/models/client_model.dart';
import '../../../providers/client_provider.dart';
import '../../common/app_button.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _gstinController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _billingController;
  late TextEditingController _shippingController;

  IndianState? _selectedState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameController = TextEditingController(text: c?.name ?? '');
    _companyController = TextEditingController(text: c?.companyName ?? '');
    _gstinController = TextEditingController(text: c?.gstin ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _billingController = TextEditingController(text: c?.billingAddress ?? '');
    _shippingController = TextEditingController(text: c?.shippingAddress ?? '');

    if (c?.stateCode != null) {
      _selectedState = IndianStates.findByCode(c!.stateCode);
    } else if (c?.state != null) {
      _selectedState = IndianStates.findByName(c!.state);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _gstinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _billingController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  void _onGstinChanged(String val) {
    // If user enters first 2 digits of GSTIN, auto-detect Indian State!
    final stateCode = IndianStates.getStateCodeFromGSTIN(val);
    if (stateCode != null) {
      final detected = IndianStates.findByCode(stateCode);
      if (detected != null && detected != _selectedState) {
        setState(() {
          _selectedState = detected;
        });
      }
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final clientModel = ClientModel(
      id: widget.client?.id,
      name: _nameController.text.trim(),
      companyName: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
      gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim().toUpperCase() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      billingAddress: _billingController.text.trim().isNotEmpty ? _billingController.text.trim() : null,
      shippingAddress: _shippingController.text.trim().isNotEmpty ? _shippingController.text.trim() : null,
      state: _selectedState?.name,
      stateCode: _selectedState?.code,
    );

    final provider = context.read<ClientProvider>();
    ClientModel? result;

    if (widget.client == null) {
      result = await provider.addClient(clientModel);
    } else {
      final updated = await provider.updateClient(clientModel);
      if (updated) result = clientModel;
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Person Name *',
                hintText: 'e.g. Ramesh Patel',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter customer name' : null,
            ),
            const SizedBox(height: 12),

            // Company Name
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Business / Company Name',
                hintText: 'e.g. Patel Trading Co.',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // GSTIN
            TextFormField(
              controller: _gstinController,
              textCapitalization: TextCapitalization.characters,
              onChanged: _onGstinChanged,
              decoration: const InputDecoration(
                labelText: 'GSTIN (Optional for B2B)',
                hintText: 'e.g. 24AAAAA0000A1Z5',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Place of Supply / State Dropdown
            DropdownButtonFormField<IndianState>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'Place of Supply (State) *',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: IndianStates.all.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('${s.code} - ${s.name}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (s) {
                setState(() => _selectedState = s);
              },
              validator: (v) => v == null ? 'Please select place of supply' : null,
            ),
            const SizedBox(height: 12),

            // Phone & Email
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Billing Address
            TextFormField(
              controller: _billingController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Billing Address',
                hintText: 'Street, Area, City, Pincode',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Shipping Address
            TextFormField(
              controller: _shippingController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Shipping Address (Consignee)',
                hintText: 'Leave empty if same as billing address',
                prefixIcon: const Icon(Icons.local_shipping_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Same as Billing Address',
                  onPressed: () {
                    _shippingController.text = _billingController.text;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              text: isEditing ? 'Save Changes' : 'Create Customer',
              isLoading: _isLoading,
              onPressed: _saveClient,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
