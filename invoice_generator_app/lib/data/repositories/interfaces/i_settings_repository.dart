import '../../models/app_settings_model.dart';
import '../../models/country_currency_model.dart';

abstract class ISettingsRepository {
  Future<AppSettingsModel> getSettings();
  Future<void> updateSettings(AppSettingsModel settings);
  Future<List<CountryCurrencyModel>> getAvailableCountries();
  Future<CountryCurrencyModel?> detectDeviceCountry();
}
