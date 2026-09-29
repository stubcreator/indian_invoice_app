import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../../core/database/database_helper.dart';
import '../../models/app_settings_model.dart';
import '../../models/country_currency_model.dart';
import '../interfaces/i_settings_repository.dart';

class SqliteSettingsRepository implements ISettingsRepository {
  final DatabaseHelper _dbHelper;
  List<CountryCurrencyModel>? _cachedCountries;

  SqliteSettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<AppSettingsModel> getSettings() async {
    final db = await _dbHelper.database;
    final results = await db.query('app_settings', where: 'id = 1');
    if (results.isNotEmpty) {
      return AppSettingsModel.fromMap(results.first);
    }
    return AppSettingsModel();
  }

  @override
  Future<void> updateSettings(AppSettingsModel settings) async {
    final db = await _dbHelper.database;
    await db.update(
      'app_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }

  @override
  Future<List<CountryCurrencyModel>> getAvailableCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;

    try {
      final jsonString = await rootBundle.loadString('assets/currency/countries.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedCountries = jsonList.map((e) => CountryCurrencyModel.fromJson(e)).toList();
      return _cachedCountries!;
    } catch (_) {
      // Fallback if asset load fails
      return [CountryCurrencyModel.defaultIndia];
    }
  }

  @override
  Future<CountryCurrencyModel?> detectDeviceCountry() async {
    try {
      final countries = await getAvailableCountries();
      final localeName = Platform.localeName; // e.g., 'en_IN' or 'en_US'
      String countryCode = 'IN';

      if (localeName.contains('_')) {
        countryCode = localeName.split('_').last.toUpperCase();
      } else if (localeName.contains('-')) {
        countryCode = localeName.split('-').last.toUpperCase();
      }

      final match = countries.firstWhere(
        (c) => c.isoAlpha2.toUpperCase() == countryCode,
        orElse: () => CountryCurrencyModel.defaultIndia,
      );

      return match;
    } catch (_) {
      return CountryCurrencyModel.defaultIndia;
    }
  }
}
