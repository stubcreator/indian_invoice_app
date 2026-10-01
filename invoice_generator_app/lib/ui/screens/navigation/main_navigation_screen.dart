import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/item_provider.dart';
import '../clients/client_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../items/item_list_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ItemListScreen(showBackButton: false),
    ClientListScreen(showBackButton: false),
    SettingsScreen(showBackButton: false),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeBiz = context.read<BusinessProvider>().activeBusiness;
      if (activeBiz?.id != null) {
        context.read<InvoiceProvider>().setBusinessId(activeBiz!.id);
        context.read<ClientProvider>().setBusinessId(activeBiz.id);
        context.read<ItemProvider>().setBusinessId(activeBiz.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            height: 64,
            elevation: 0,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: 'Invoices',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                label: 'Catalog',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
