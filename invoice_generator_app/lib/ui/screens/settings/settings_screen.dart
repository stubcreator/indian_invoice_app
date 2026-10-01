import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../business/business_profile_screen.dart';
import '../clients/client_list_screen.dart';
import '../dashboard/widgets/business_switcher_sheet.dart';
import '../items/item_list_screen.dart';
import 'country_currency_picker_screen.dart';
import '../../common/country_flag_widget.dart';

class SettingsScreen extends StatefulWidget {
  final bool showBackButton;

  const SettingsScreen({super.key, this.showBackButton = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _prefixController;
  late TextEditingController _nextNumberController;
  late TextEditingController _termsController;
  late TextEditingController _notesController;

  bool _isControllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController();
    _nextNumberController = TextEditingController();
    _termsController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllersInitialized) {
      final settings = context.read<SettingsProvider>().settings;
      _prefixController.text = settings.invoicePrefix;
      _nextNumberController.text = settings.nextInvoiceNumber.toString();
      _termsController.text = settings.defaultTerms;
      _notesController.text = settings.defaultNotes;
      _isControllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(AppSettingsModel current) async {
    final nextNum = int.tryParse(_nextNumberController.text.trim()) ?? current.nextInvoiceNumber;
    final updated = current.copyWith(
      invoicePrefix: _prefixController.text.trim(),
      nextInvoiceNumber: nextNum,
      defaultTerms: _termsController.text.trim(),
      defaultNotes: _notesController.text.trim(),
    );

    await context.read<SettingsProvider>().updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved successfully!'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final activeBiz = bizProv.activeBusiness;

    if (settingsProv.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('App Settings'), automaticallyImplyLeading: widget.showBackButton),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final settings = settingsProv.settings;
    final country = settingsProv.selectedCountry;

    // Guard taxMode to match dropdown item values safely
    const validTaxModes = ['gst', 'vat', 'salestax', 'none'];
    final currentTaxMode = validTaxModes.contains(settings.taxMode.toLowerCase())
        ? settings.taxMode.toLowerCase()
        : 'gst';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('App Settings'), automaticallyImplyLeading: widget.showBackButton),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. ACTIVE BUSINESS CARD
          const Text(
            'Active Business Profile',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeBiz != null && activeBiz.businessName.isNotEmpty
                                ? activeBiz.businessName
                                : 'No Business Selected',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            activeBiz?.gstin != null && activeBiz!.gstin!.isNotEmpty
                                ? 'GSTIN: ${activeBiz.gstin}'
                                : (activeBiz?.state != null ? activeBiz!.state! : 'Tap Switch to select or add'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const BusinessSwitcherSheet(),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Switch / Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BusinessProfileScreen(business: activeBiz)),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. COUNTRY & CURRENCY
          const Text(
            'Country & Currency',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CountryFlagWidget(flag: country?.flag ?? '🇮🇳', width: 38, height: 26, borderRadius: 4),
                  title: Text(
                    '${settings.countryName} (${settings.currencyCode})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Symbol: ${settings.currencySymbol} • Tax: ${currentTaxMode.toUpperCase()}'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CountryCurrencyPickerScreen()));
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax Calculation Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      DropdownButton<String>(
                        value: currentTaxMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'gst', child: Text('Indian GST')),
                          DropdownMenuItem(value: 'vat', child: Text('VAT (Standard)')),
                          DropdownMenuItem(value: 'salestax', child: Text('Sales Tax')),
                          DropdownMenuItem(value: 'none', child: Text('None (No Tax)')),
                        ],
                        onChanged: (val) {
                          if (val != null) settingsProv.setTaxMode(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. MANAGE PROFILES & CATALOGS
          const Text(
            'Manage Data & Catalogs',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text('Customers & Clients', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage buyer profiles and GST Place of Supply'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientListScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.success,
                    child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text('Items & Services Catalog', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Products, HSN/SAC codes, and GST rates'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemListScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. INVOICE DEFAULTS & CUSTOMIZATION
          const Text(
            'Invoice Defaults & Sequence',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Row(
                //   children: [
                //     Expanded(
                //       child: TextFormField(
                //         controller: _prefixController,
                //         decoration: const InputDecoration(labelText: 'Invoice Prefix', hintText: 'INV-'),
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: TextFormField(
                //         controller: _nextNumberController,
                //         keyboardType: TextInputType.number,
                //         decoration: const InputDecoration(labelText: 'Next Sequence #'),
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),
                TextFormField(
                  controller: _termsController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Default Terms & Conditions'),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Save Defaults',
                  icon: Icons.check_circle_rounded,
                  onPressed: () => _saveSettings(settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
