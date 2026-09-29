class IndianState {
  final String code; // 2-digit code e.g. "24"
  final String name;

  const IndianState({required this.code, required this.name});

  @override
  String toString() => '$code - $name';
}

class IndianStates {
  static const List<IndianState> all = [
    IndianState(code: "01", name: "Jammu and Kashmir"),
    IndianState(code: "02", name: "Himachal Pradesh"),
    IndianState(code: "03", name: "Punjab"),
    IndianState(code: "04", name: "Chandigarh"),
    IndianState(code: "05", name: "Uttarakhand"),
    IndianState(code: "06", name: "Haryana"),
    IndianState(code: "07", name: "Delhi"),
    IndianState(code: "08", name: "Rajasthan"),
    IndianState(code: "09", name: "Uttar Pradesh"),
    IndianState(code: "10", name: "Bihar"),
    IndianState(code: "11", name: "Sikkim"),
    IndianState(code: "12", name: "Arunachal Pradesh"),
    IndianState(code: "13", name: "Nagaland"),
    IndianState(code: "14", name: "Manipur"),
    IndianState(code: "15", name: "Mizoram"),
    IndianState(code: "16", name: "Tripura"),
    IndianState(code: "17", name: "Meghalaya"),
    IndianState(code: "18", name: "Assam"),
    IndianState(code: "19", name: "West Bengal"),
    IndianState(code: "20", name: "Jharkhand"),
    IndianState(code: "21", name: "Odisha"),
    IndianState(code: "22", name: "Chhattisgarh"),
    IndianState(code: "23", name: "Madhya Pradesh"),
    IndianState(code: "24", name: "Gujarat"),
    IndianState(code: "26", name: "Dadra & Nagar Haveli and Daman & Diu"),
    IndianState(code: "27", name: "Maharashtra"),
    IndianState(code: "28", name: "Andhra Pradesh (Old)"),
    IndianState(code: "29", name: "Karnataka"),
    IndianState(code: "30", name: "Goa"),
    IndianState(code: "31", name: "Lakshadweep"),
    IndianState(code: "32", name: "Kerala"),
    IndianState(code: "33", name: "Tamil Nadu"),
    IndianState(code: "34", name: "Puducherry"),
    IndianState(code: "35", name: "Andaman and Nicobar Islands"),
    IndianState(code: "36", name: "Telangana"),
    IndianState(code: "37", name: "Andhra Pradesh (New)"),
    IndianState(code: "38", name: "Ladakh"),
    IndianState(code: "97", name: "Other Territory"),
    IndianState(code: "99", name: "Centre Jurisdiction"),
  ];

  static IndianState? findByCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.padLeft(2, '0');
    try {
      return all.firstWhere((s) => s.code == normalized);
    } catch (_) {
      return null;
    }
  }

  static IndianState? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    final lower = name.trim().toLowerCase();
    try {
      return all.firstWhere((s) => s.name.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Extracts the 2-digit state code from a 15-character GSTIN
  static String? getStateCodeFromGSTIN(String? gstin) {
    if (gstin == null) return null;
    final clean = gstin.trim().toUpperCase();
    if (clean.length >= 2) {
      final code = clean.substring(0, 2);
      if (RegExp(r'^\d{2}$').hasMatch(code)) {
        return code;
      }
    }
    return null;
  }

  /// Validates standard Indian 15-character GSTIN format
  /// Format: 2 digits (State) + 10 alphanumeric (PAN) + 1 digit (entity number) + 'Z' + 1 checksum
  static bool isValidGSTIN(String? gstin) {
    if (gstin == null) return false;
    final pattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return pattern.hasMatch(gstin.trim().toUpperCase());
  }

  /// Extracts 10-character PAN from GSTIN
  static String? getPANFromGSTIN(String? gstin) {
    if (gstin == null) return null;
    final clean = gstin.trim().toUpperCase();
    if (clean.length >= 12) {
      return clean.substring(2, 12);
    }
    return null;
  }
}
