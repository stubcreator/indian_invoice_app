class CountryCurrencyModel {
  final int id;
  final String name;
  final String isoAlpha2;
  final String isoAlpha3;
  final int isoNumeric;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final String flag;

  CountryCurrencyModel({
    required this.id,
    required this.name,
    required this.isoAlpha2,
    required this.isoAlpha3,
    required this.isoNumeric,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.flag,
  });

  factory CountryCurrencyModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>? ?? {};
    return CountryCurrencyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isoAlpha2: json['isoAlpha2'] ?? '',
      isoAlpha3: json['isoAlpha3'] ?? '',
      isoNumeric: json['isoNumeric'] ?? 0,
      currencyCode: currency['code'] ?? 'INR',
      currencyName: currency['name'] ?? 'Indian Rupee',
      currencySymbol: currency['symbol'] ?? '₹',
      flag: json['flag'] ?? '🇮🇳',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isoAlpha2': isoAlpha2,
      'isoAlpha3': isoAlpha3,
      'isoNumeric': isoNumeric,
      'currency': {
        'code': currencyCode,
        'name': currencyName,
        'symbol': currencySymbol,
      },
      'flag': flag,
    };
  }

  /// Default India profile
  static CountryCurrencyModel get defaultIndia => CountryCurrencyModel(
        id: 101,
        name: "India",
        isoAlpha2: "IN",
        isoAlpha3: "IND",
        isoNumeric: 356,
        currencyCode: "INR",
        currencyName: "Indian Rupee",
        currencySymbol: "₹",
        flag: "🇮🇳",
      );
}
