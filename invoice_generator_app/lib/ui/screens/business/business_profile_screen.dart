import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/indian_states.dart';
import '../../../core/theme/custom_text_styles.dart';
import '../../../data/models/business_model.dart';
import '../../../data/models/country_currency_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/item_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../../common/country_flag_widget.dart';
import '../invoice/widgets/signature_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  final BusinessModel? business;
  final bool isNew;

  const BusinessProfileScreen({super.key, this.business, this.isNew = false});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _tradeNameController;
  late TextEditingController _ownerController;
  late TextEditingController _gstinController; // Used for GSTIN in India or Tax ID/VAT in other countries
  late TextEditingController _panController; // India only
  late TextEditingController _stateController; // Non-India text field for Province/State
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addr1Controller;
  late TextEditingController _addr2Controller;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  // Bank & UPI
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController; // IFSC for India, SWIFT/Routing for others
  late TextEditingController _accountHolderController;
  late TextEditingController _upiIdController; // India only

  CountryCurrencyModel? _selectedCountry;
  IndianState? _selectedState;
  String? _logoPath;
  String? _signaturePath;
  bool _isLoading = false;

  bool get _isIndia {
    final name = _selectedCountry?.name.toLowerCase() ?? '';
    final code = _selectedCountry?.isoAlpha2.toUpperCase() ?? '';
    return name == 'india' || code == 'IN';
  }

  @override
  void initState() {
    super.initState();
    final biz = widget.isNew ? null : (widget.business ?? context.read<BusinessProvider>().activeBusiness);
    final settingsProv = context.read<SettingsProvider>();

    _nameController = TextEditingController(text: biz?.businessName ?? '');
    _tradeNameController = TextEditingController(text: biz?.tradeName ?? '');
    _ownerController = TextEditingController(text: biz?.ownerName ?? '');
    _gstinController = TextEditingController(text: biz?.gstin ?? '');
    _panController = TextEditingController(text: biz?.pan ?? '');
    _stateController = TextEditingController(text: biz?.state ?? '');
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

    // Resolve Country
    final countryName = biz?.country ?? settingsProv.selectedCountry?.name ?? 'India';
    final allCountries = settingsProv.countries;
    _selectedCountry = allCountries.isNotEmpty
        ? allCountries.firstWhere(
            (c) =>
                c.name.toLowerCase() == countryName.toLowerCase() ||
                c.isoAlpha2.toLowerCase() == countryName.toLowerCase(),
            orElse: () => settingsProv.selectedCountry ?? allCountries.first,
          )
        : CountryCurrencyModel.defaultIndia;

    // Resolve State for India
    if (_isIndia) {
      if (biz?.stateCode != null) {
        _selectedState = IndianStates.findByCode(biz!.stateCode);
      } else if (biz?.state != null) {
        _selectedState = IndianStates.findByName(biz!.state);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tradeNameController.dispose();
    _ownerController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _stateController.dispose();
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
    if (!_isIndia) return;

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

  void _showCountryPicker() {
    final allCountries = context.read<SettingsProvider>().countries;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCountries.where((c) {
              final q = query.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.currencyCode.toLowerCase().contains(q) ||
                  c.currencyName.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Business Country', style: size17(fw: FW.bold)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: TextField(
                      autofocus: false,
                      onChanged: (val) {
                        setModalState(() => query = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search country or currency...',
                        hintStyle: size13(fontColor: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final country = filtered[i];
                        final isSelected = _selectedCountry?.name == country.name;
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            title: Text(
                              country.name,
                              style: size14(
                                fw: isSelected ? FW.bold : FW.medium,
                                fontColor: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${country.currencyName} (${country.currencySymbol} - ${country.currencyCode})',
                              style: size12(fontColor: AppColors.textSecondary),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedCountry = country;
                                if (_isIndia) {
                                  if (_selectedState == null && _stateController.text.isNotEmpty) {
                                    _selectedState = IndianStates.findByName(_stateController.text);
                                  }
                                } else {
                                  if (_selectedState != null && _stateController.text.isEmpty) {
                                    _stateController.text = _selectedState!.name;
                                  }
                                  _selectedState = null;
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    final currentBiz = widget.isNew ? null : (widget.business ?? context.read<BusinessProvider>().activeBusiness);

    final updated = BusinessModel(
      id: currentBiz?.id,
      businessName: _nameController.text.trim(),
      tradeName: _tradeNameController.text.trim().isNotEmpty ? _tradeNameController.text.trim() : null,
      ownerName: _ownerController.text.trim().isNotEmpty ? _ownerController.text.trim() : null,
      // For India: GSTIN. For Non-India: Tax ID / VAT Number
      gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim().toUpperCase() : null,
      // PAN is strictly Indian statutory identification
      pan: _isIndia && _panController.text.trim().isNotEmpty ? _panController.text.trim().toUpperCase() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      addressLine1: _addr1Controller.text.trim().isNotEmpty ? _addr1Controller.text.trim() : null,
      addressLine2: _addr2Controller.text.trim().isNotEmpty ? _addr2Controller.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
      // State handling: IndianState for India, free-text for Non-India
      state: _isIndia
          ? _selectedState?.name
          : (_stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null),
      stateCode: _isIndia ? _selectedState?.code : null,
      country: _selectedCountry?.name ?? 'India',
      logoPath: _logoPath,
      signaturePath: _signaturePath,
      bankName: _bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null,
      accountNumber: _accountNoController.text.trim().isNotEmpty ? _accountNoController.text.trim() : null,
      ifscCode: _ifscController.text.trim().isNotEmpty ? _ifscController.text.trim().toUpperCase() : null,
      accountHolderName: _accountHolderController.text.trim().isNotEmpty ? _accountHolderController.text.trim() : null,
      // UPI is strictly Indian payment protocol
      upiId: _isIndia && _upiIdController.text.trim().isNotEmpty ? _upiIdController.text.trim() : null,
    );

    bool success = false;
    if (widget.isNew) {
      final newId = await context.read<BusinessProvider>().createBusiness(updated);
      success = newId != null;
      if (success && mounted) {
        context.read<InvoiceProvider>().setBusinessId(newId);
        context.read<ClientProvider>().setBusinessId(newId);
        context.read<ItemProvider>().setBusinessId(newId);
      }
    } else {
      success = await context.read<BusinessProvider>().updateBusiness(updated);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isNew ? 'Business profile created successfully!' : 'Business profile updated successfully!',
            style: size13(fontColor: AppColors.textWhite),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Business Profile?', style: size17(fw: FW.bold)),
        content: Text(
          'Are you sure you want to delete this business profile? All invoices linked will remain in records.',
          style: size13(fontColor: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<BusinessProvider>().deleteBusiness(id);
      if (mounted) {
        final active = context.read<BusinessProvider>().activeBusiness;
        context.read<InvoiceProvider>().setBusinessId(active?.id);
        context.read<ClientProvider>().setBusinessId(active?.id);
        context.read<ItemProvider>().setBusinessId(active?.id);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBiz = widget.isNew ? null : (widget.business ?? context.watch<BusinessProvider>().activeBusiness);
    final allBiz = context.watch<BusinessProvider>().businesses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isNew
              ? 'New Business Profile'
              : (widget.business != null ? 'Edit Business' : 'Business Profile & Settings'),
          style: size18(fw: FW.bold),
        ),
        actions: [
          if (!widget.isNew && currentBiz?.id != null && allBiz.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              tooltip: 'Delete Business',
              onPressed: () => _confirmDelete(currentBiz!.id!),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Country Selection Card (Dynamic Trigger)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Country', style: size15(fw: FW.semiBold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCountry?.name ?? 'India',
                                  style: size14(fw: FW.semiBold, fontColor: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isIndia
                        ? 'GST, PAN, and Indian states are enabled for this business.'
                        : 'Customized for ${_selectedCountry?.name}: Indian GST and PAN fields are hidden.',
                    style: size11(fontColor: _isIndia ? AppColors.primary : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 24, color: AppColors.primary),
                                const SizedBox(height: 4),
                                Text('Logo', style: size10(fontColor: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Business Logo', style: size15(fw: FW.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Will be printed on top of your invoices and PDF receipts.',
                          style: size12(fontColor: AppColors.textSecondary),
                        ),
                        if (_logoPath != null)
                          TextButton(
                            onPressed: () => setState(() => _logoPath = null),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text('Remove Logo', style: size12(fontColor: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 1. Core Company Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Details', style: size15(fw: FW.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Legal Business Name *',
                      hintText: 'e.g. Leo Infotech Solutions',
                      prefixIcon: const Icon(Icons.business_outlined),
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter business name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tradeNameController,
                    decoration: InputDecoration(
                      labelText: 'Trade / Brand Name (Optional)',
                      hintText: 'e.g. Leo Tech',
                      prefixIcon: const Icon(Icons.storefront_outlined),
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerController,
                    decoration: InputDecoration(
                      labelText: 'Owner / Signatory Name',
                      hintText: 'e.g. Rahul Bhuva',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Tax & Statutory Information (DYNAMIC: India vs Non-India)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isIndia ? Icons.verified_outlined : Icons.receipt_long_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isIndia ? 'GST & Statutory Information (India)' : 'Tax & Business Registration',
                        style: size15(fw: FW.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isIndia
                        ? 'GSTIN & PAN will be printed on Tax Invoices and used for CGST/SGST/IGST breakdown.'
                        : 'Your Tax ID or VAT number will be displayed on client invoices.',
                    style: size12(fontColor: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  if (_isIndia) ...[
                    // GSTIN input (15 chars)
                    TextFormField(
                      controller: _gstinController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onGstinChanged,
                      decoration: InputDecoration(
                        labelText: 'GSTIN (15 Characters)',
                        hintText: 'e.g. 24AAAAA0000A1Z5',
                        prefixIcon: const Icon(Icons.verified_outlined),
                        labelStyle: size13(fontColor: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // PAN & Indian State Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'PAN Number',
                              hintText: 'e.g. AAAAA0000A',
                              prefixIcon: const Icon(Icons.credit_card_outlined),
                              labelStyle: size13(fontColor: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<IndianState>(
                            initialValue: _selectedState,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'State *',
                              labelStyle: size13(fontColor: AppColors.textSecondary),
                            ),
                            items: IndianStates.all.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: size13(fw: FW.medium),
                                ),
                              );
                            }).toList(),
                            onChanged: (s) => setState(() => _selectedState = s),
                            validator: (v) => v == null ? 'Select state' : null,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Non-India: Tax ID / VAT Number & Province/State Text Field
                    Column(
                      children: [
                        TextFormField(
                          controller: _gstinController,
                          decoration: InputDecoration(
                            labelText: 'Tax ID / VAT No.',
                            hintText: 'e.g. EIN / VAT / Reg No.',
                            prefixIcon: const Icon(Icons.tag_rounded),
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State',
                            hintText: 'e.g. California, Ontario',
                            prefixIcon: const Icon(Icons.map_outlined),
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Contact & Location
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact & Location', style: size15(fw: FW.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addr1Controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 1',
                      hintText: 'Office / Shop no, Building, Street',
                      labelStyle: size13(fontColor: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          decoration: InputDecoration(
                            labelText: _isIndia ? 'Pincode' : 'ZIP / Postal Code',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Bank & Payment Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bank & Payment Details', style: size15(fw: FW.bold)),
                      if (_isIndia)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UPI QR Enabled',
                            style: size10(fw: FW.bold, fontColor: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isIndia
                        ? 'Your Bank info and UPI ID will generate a live Scan-to-Pay QR code on invoices.'
                        : 'Your Bank details will appear on PDF invoices so clients can pay you directly.',
                    style: size12(fontColor: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  if (_isIndia) ...[
                    // UPI ID for India
                    TextFormField(
                      controller: _upiIdController,
                      decoration: InputDecoration(
                        labelText: 'UPI ID (VPA) for Instant Payments',
                        hintText: 'e.g. rahul@okhdfcbank or 9876543210@paytm',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded),
                        labelStyle: size13(fontColor: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankNameController,
                          decoration: InputDecoration(
                            labelText: 'Bank Name',
                            hintText: _isIndia ? 'HDFC Bank' : 'Chase / Barclays',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: _isIndia ? 'IFSC Code' : 'SWIFT / BIC / Routing',
                            hintText: _isIndia ? 'HDFC0001234' : 'CHASUS33',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
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
                          decoration: InputDecoration(
                            labelText: _isIndia ? 'Account Number' : 'Account No. / IBAN',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _accountHolderController,
                          decoration: InputDecoration(
                            labelText: 'Account Holder Name',
                            labelStyle: size13(fontColor: AppColors.textSecondary),
                          ),
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
                      Text('Default Signature', style: size15(fw: FW.bold)),
                      TextButton.icon(
                        onPressed: _openSignatureSheet,
                        icon: const Icon(Icons.draw_rounded, size: 16),
                        label: Text(_signaturePath != null ? 'Change' : 'Sign Now', style: size13(fw: FW.semiBold)),
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
                    Text(
                      'No signature added yet. Will be printed on PDF invoices.',
                      style: size12(fontColor: AppColors.textSecondary),
                    ),
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
