import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/country_currency_model.dart';
import '../../../providers/settings_provider.dart';
import '../../common/country_flag_widget.dart';

class CountryCurrencyPickerScreen extends StatefulWidget {
  const CountryCurrencyPickerScreen({super.key});

  @override
  State<CountryCurrencyPickerScreen> createState() => _CountryCurrencyPickerScreenState();
}

class _CountryCurrencyPickerScreenState extends State<CountryCurrencyPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCurrencyModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    final countries = context.read<SettingsProvider>().countries;
    _filtered = countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final all = context.read<SettingsProvider>().countries;
    if (query.trim().isEmpty) {
      setState(() => _filtered = all);
    } else {
      final q = query.trim().toLowerCase();
      setState(() {
        _filtered = all.where((c) {
          return c.name.toLowerCase().contains(q) ||
              c.currencyCode.toLowerCase().contains(q) ||
              c.currencyName.toLowerCase().contains(q) ||
              c.isoAlpha2.toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final activeCountry = settingsProv.selectedCountry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Select Country & Currency')),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search country or currency (e.g. India, USD, INR)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Countries List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No matching countries found'))
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      final isSelected = activeCountry?.isoAlpha2.toUpperCase() == item.isoAlpha2.toUpperCase();

                      return ListTile(
                        leading: CountryFlagWidget(
                          flag: item.flag,
                          width: 38,
                          height: 26,
                          borderRadius: 4,
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            if (item.isoAlpha2 == 'IN') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GST READY',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${item.currencyName} (${item.currencyCode}) • Symbol: ${item.currencySymbol}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await settingsProv.setCountry(item);
                          nav.pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
