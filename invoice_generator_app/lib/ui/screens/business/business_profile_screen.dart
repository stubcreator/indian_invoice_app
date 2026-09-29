import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/indian_states.dart';
import '../../../core/utils/upi_helper.dart';
import '../../../data/models/business_model.dart';
import '../../../providers/business_provider.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../invoice/widgets/signature_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _tradeNameController;
  late TextEditingController _ownerController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addr1Controller;
  late TextEditingController _addr2Controller;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  // Bank & UPI
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;
  late TextEditingController _accountHolderController;
  late TextEditingController _upiIdController;

  IndianState? _selectedState;
  String? _logoPath;
  String? _signaturePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final biz = context.read<BusinessProvider>().business;

    _nameController = TextEditingController(text: biz?.businessName ?? '');
    _tradeNameController = TextEditingController(text: biz?.tradeName ?? '');
    _ownerController = TextEditingController(text: biz?.ownerName ?? '');
    _gstinController = TextEditingController(text: biz?.gstin ?? '');
    _panController = TextEditingController(text: biz?.pan ?? '');
    _phoneController = TextEditingController(text: biz?.phone ?? '');
    _emailController = TextEditingController(text: biz?.email ?? '');
    _addr1Controller = TextEditingController(text: biz?.addressLine1 ?? '');
    _addr2Controller = TextEditingController(text: biz?.addressLine2 ?? '');
    _cityController = TextEditingController(text: biz?.city ?? '');
    _pincodeController = TextEditingController(text: biz?.pincode ?? '');

    _bankNameController = TextEditingController(text: biz?.bankName ?? '');
    _accountNoController = TextEditingController(text: biz?.accountNumber ?? '');
    _ifscController = TextEditingController(text: biz?.ifscCode ?? '');
    _accountHolderController = TextEditingController(text: biz?.accountHolderName ?? '');
    _upiIdController = TextEditingController(text: biz?.upiId ?? '');

    _logoPath = biz?.logoPath;
    _signaturePath = biz?.signaturePath;

    if (biz?.stateCode != null) {
      _selectedState = IndianStates.findByCode(biz!.stateCode);
    } else if (biz?.state != null) {
      _selectedState = IndianStates.findByName(biz!.state);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tradeNameController.dispose();
    _ownerController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addr1Controller.dispose();
    _addr2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _onGstinChanged(String val) {
    final stateCode = IndianStates.getStateCodeFromGSTIN(val);
    if (stateCode != null) {
      final s = IndianStates.findByCode(stateCode);
      if (s != null && s != _selectedState) {
        setState(() => _selectedState = s);
      }
    }

    final pan = IndianStates.getPANFromGSTIN(val);
    if (pan != null && _panController.text.isEmpty) {
      _panController.text = pan;
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  void _openSignatureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SignatureSheet(
        onSignatureSaved: (path) {
          setState(() => _signaturePath = path);
        },
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentBiz = context.read<BusinessProvider>().business;

    final updated = BusinessModel(
      id: currentBiz?.id,
      businessName: _nameController.text.trim(),
      tradeName: _tradeNameController.text.trim().isNotEmpty ? _tradeNameController.text.trim() : null,
      ownerName: _ownerController.text.trim().isNotEmpty ? _ownerController.text.trim() : null,
      gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim().toUpperCase() : null,
      pan: _panController.text.trim().isNotEmpty ? _panController.text.trim().toUpperCase() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      addressLine1: _addr1Controller.text.trim().isNotEmpty ? _addr1Controller.text.trim() : null,
      addressLine2: _addr2Controller.text.trim().isNotEmpty ? _addr2Controller.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
      state: _selectedState?.name,
      stateCode: _selectedState?.code,
      logoPath: _logoPath,
      signaturePath: _signaturePath,
      bankName: _bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null,
      accountNumber: _accountNoController.text.trim().isNotEmpty ? _accountNoController.text.trim() : null,
      ifscCode: _ifscController.text.trim().isNotEmpty ? _ifscController.text.trim().toUpperCase() : null,
      accountHolderName: _accountHolderController.text.trim().isNotEmpty ? _accountHolderController.text.trim() : null,
      upiId: _upiIdController.text.trim().isNotEmpty ? _upiIdController.text.trim() : null,
    );

    final success = await context.read<BusinessProvider>().saveBusiness(updated);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Profile & GST'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo & Header Box
            AppCard(
              child: Row(
                children: [
                  InkWell(
                    onTap: _pickLogo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(File(_logoPath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 24, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text('Logo', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Logo',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Will be printed on top of your invoices and PDF receipts.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (_logoPath != null)
                          TextButton(
                            onPressed: () => setState(() => _logoPath = null),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: const Text('Remove Logo', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 1. Core Business Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Legal Business Name *',
                      hintText: 'e.g. Apex Infotech Solutions',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter business name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tradeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Trade / Brand Name (Optional)',
                      hintText: 'e.g. Apex Tech',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: 'Owner / Signatory Name',
                      hintText: 'e.g. Rahul Bhuva',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. GST & Tax Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GST & Statutory Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _onGstinChanged,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (15 Characters)',
                      hintText: 'e.g. 24AAAAA0000A1Z5',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _panController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'e.g. AAAAA0000A',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<IndianState>(
                          value: _selectedState,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Home State *'),
                          items: IndianStates.all.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('${s.code} - ${s.name}', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (s) => setState(() => _selectedState = s),
                          validator: (v) => v == null ? 'Select state' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Contact & Address
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact & Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addr1Controller,
                    decoration: const InputDecoration(labelText: 'Address Line 1', hintText: 'Shop / Office no, Building'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Pincode'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Bank & UPI Details (for invoice QR Code)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bank & UPI Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('QR Enabled', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Bank info and UPI ID will generate a live Scan-to-Pay QR code on invoices.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _upiIdController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (VPA) for Instant Payments',
                      hintText: 'e.g. rahul@okhdfcbank or 9876543210@paytm',
                      prefixIcon: Icon(Icons.qr_code_2_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(labelText: 'Bank Name', hintText: 'HDFC Bank'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'IFSC Code', hintText: 'HDFC0001234'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _accountNoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Account Number'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _accountHolderController,
                          decoration: const InputDecoration(labelText: 'Account Holder Name'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Authorized Signature
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Signature', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: _openSignatureSheet,
                        icon: const Icon(Icons.draw_rounded, size: 16),
                        label: Text(_signaturePath != null ? 'Change' : 'Sign Now'),
                      ),
                    ],
                  ),
                  if (_signaturePath != null && File(_signaturePath!).existsSync())
                    Container(
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.file(File(_signaturePath!), fit: BoxFit.contain),
                    )
                  else
                    const Text('No signature added yet. Will be printed on PDF invoices.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'Save Business Profile',
              isLoading: _isLoading,
              onPressed: _saveProfile,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
