import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_card.dart';
import '../business/business_profile_screen.dart';
import '../clients/client_list_screen.dart';
import '../items/item_list_screen.dart';
import 'country_currency_picker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final settings = settingsProv.settings;
    final country = settingsProv.selectedCountry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Localization & Currency
          const Text('Country & Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Text(country?.flag ?? '🇮🇳', style: const TextStyle(fontSize: 28)),
                  title: Text(
                    '${settings.countryName} (${settings.currencyCode})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Symbol: ${settings.currencySymbol} • Tax: ${settings.taxMode.toUpperCase()}'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CountryCurrencyPickerScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax Calculation Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      DropdownButton<String>(
                        value: settings.taxMode.toLowerCase(),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'gst', child: Text('🇮🇳 Indian GST')),
                          DropdownMenuItem(value: 'vat', child: Text('🌍 VAT (Standard)')),
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

          // 2. Business & Entities Management
          const Text('Manage Profiles & Catalogs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.business_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text('Business Profile & GST', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Company name, GSTIN, bank & UPI QR details'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text('Customers & Clients', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage buyer profiles and GST Place of Supply'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClientListScreen()),
                    );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ItemListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Invoice Numbering & Defaults
          const Text('Invoice Customization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: settings.invoicePrefix,
                        decoration: const InputDecoration(labelText: 'Invoice Prefix', hintText: 'INV-'),
                        onChanged: (v) {
                          settingsProv.updateSettings(settings.copyWith(invoicePrefix: v));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: settings.nextInvoiceNumber.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Next Sequence #'),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) {
                            settingsProv.updateSettings(settings.copyWith(nextInvoiceNumber: n));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.defaultTerms,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Default Terms & Conditions'),
                  onChanged: (v) {
                    settingsProv.updateSettings(settings.copyWith(defaultTerms: v));
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.defaultNotes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Default Invoice Notes'),
                  onChanged: (v) {
                    settingsProv.updateSettings(settings.copyWith(defaultNotes: v));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // App Info
          const Center(
            child: Column(
              children: [
                Text(
                  'Invoice Generator Pro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                SizedBox(height: 2),
                Text(
                  'Version 1.0.0 • Indian GST Ready',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
