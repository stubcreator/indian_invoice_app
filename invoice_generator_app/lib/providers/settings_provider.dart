import 'package:flutter/material.dart';
import '../data/models/app_settings_model.dart';
import '../data/models/country_currency_model.dart';
import '../data/repositories/interfaces/i_settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final ISettingsRepository _repository;

  AppSettingsModel _settings = AppSettingsModel();
  List<CountryCurrencyModel> _countries = [];
  CountryCurrencyModel? _selectedCountry;
  bool _isLoading = false;

  SettingsProvider({required ISettingsRepository repository})
      : _repository = repository {
    init();
  }

  AppSettingsModel get settings => _settings;
  List<CountryCurrencyModel> get countries => _countries;
  CountryCurrencyModel? get selectedCountry => _selectedCountry;
  bool get isLoading => _isLoading;
  bool get isGstMode => _settings.isGstMode;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _countries = await _repository.getAvailableCountries();
      _settings = await _repository.getSettings();

      // Find matching country
      try {
        _selectedCountry = _countries.firstWhere(
          (c) => c.isoAlpha2.toUpperCase() == _settings.countryCode.toUpperCase(),
        );
      } catch (_) {
        _selectedCountry = CountryCurrencyModel.defaultIndia;
      }
    } catch (_) {
      _selectedCountry = CountryCurrencyModel.defaultIndia;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCountry(CountryCurrencyModel country) async {
    _selectedCountry = country;
    final isIndia = country.isoAlpha2.toUpperCase() == 'IN';

    // If country is India, default taxMode to GST. If foreign, default to VAT.
    final updatedTaxMode = isIndia ? 'gst' : 'vat';

    _settings = _settings.copyWith(
      countryCode: country.isoAlpha2,
      countryName: country.name,
      currencyCode: country.currencyCode,
      currencySymbol: country.currencySymbol,
      taxMode: updatedTaxMode,
    );

    await _repository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    _settings = _settings.copyWith(
      currencyCode: code,
      currencySymbol: symbol,
    );
    await _repository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> setTaxMode(String mode) async {
    _settings = _settings.copyWith(taxMode: mode);
    await _repository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    await _repository.updateSettings(_settings);
    notifyListeners();
  }
}
