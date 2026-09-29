class GstSlabs {
  static const List<double> standardRates = [0.0, 0.1, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0];

  static const List<String> commonUnits = [
    "PCS",
    "NOS",
    "KGS",
    "GMS",
    "BOX",
    "SET",
    "MTR",
    "LTR",
    "HRS",
    "DAYS",
    "PKT",
    "BAG",
    "ROLL",
    "SQFT",
    "SQMT",
    "CAN",
    "BTL",
  ];
}

enum TaxMode {
  gst, // Indian GST (CGST + SGST or IGST based on State vs POS)
  vat, // Global VAT (Single percentage)
  salesTax, // Sales Tax
  none, // No Tax
}

extension TaxModeExtension on TaxMode {
  String get displayName {
    switch (this) {
      case TaxMode.gst:
        return "GST (CGST/SGST/IGST)";
      case TaxMode.vat:
        return "VAT";
      case TaxMode.salesTax:
        return "Sales Tax";
      case TaxMode.none:
        return "None (No Tax)";
    }
  }

  static TaxMode fromString(String? val) {
    if (val == null) return TaxMode.gst;
    switch (val.toLowerCase()) {
      case 'vat':
        return TaxMode.vat;
      case 'salestax':
      case 'sales_tax':
        return TaxMode.salesTax;
      case 'none':
        return TaxMode.none;
      case 'gst':
      default:
        return TaxMode.gst;
    }
  }
}
