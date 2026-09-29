import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/sqlite/sqlite_business_repository.dart';
import 'data/repositories/sqlite/sqlite_client_repository.dart';
import 'data/repositories/sqlite/sqlite_invoice_repository.dart';
import 'data/repositories/sqlite/sqlite_item_repository.dart';
import 'data/repositories/sqlite/sqlite_settings_repository.dart';
import 'providers/business_provider.dart';
import 'providers/client_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/item_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate Repositories
  final settingsRepo = SqliteSettingsRepository();
  final businessRepo = SqliteBusinessRepository();
  final clientRepo = SqliteClientRepository();
  final itemRepo = SqliteItemRepository();
  final invoiceRepo = SqliteInvoiceRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(repository: settingsRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => BusinessProvider(repository: businessRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientProvider(repository: clientRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ItemProvider(repository: itemRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(repository: invoiceRepo),
        ),
      ],
      child: const InvoiceApp(),
    ),
  );
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
