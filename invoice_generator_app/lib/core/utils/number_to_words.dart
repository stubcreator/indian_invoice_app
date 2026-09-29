class NumberToWords {
  static const List<String> _units = [
    "",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
    "Ten",
    "Eleven",
    "Twelve",
    "Thirteen",
    "Fourteen",
    "Fifteen",
    "Sixteen",
    "Seventeen",
    "Eighteen",
    "Nineteen"
  ];

  static const List<String> _tens = [
    "",
    "",
    "Twenty",
    "Thirty",
    "Forty",
    "Fifty",
    "Sixty",
    "Seventy",
    "Eighty",
    "Ninety"
  ];

  static String _convertThreeDigits(int n) {
    String res = "";
    if (n >= 100) {
      res += "${_units[n ~/ 100]} Hundred ";
      n %= 100;
    }
    if (n >= 20) {
      res += "${_tens[n ~/ 10]} ";
      n %= 10;
    }
    if (n > 0) {
      res += "${_units[n]} ";
    }
    return res.trim();
  }

  /// Converts number to words in Indian Numbering System (Crore, Lakh, Thousand)
  static String convertIndian(double amount, {String currencyName = "Rupees", String subunitName = "Paise"}) {
    if (amount == 0) return "$currencyName Zero Only";

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    String result = "";

    int temp = rupees;
    if (temp >= 10000000) {
      int crore = temp ~/ 10000000;
      result += "${_convertThreeDigits(crore)} Crore ";
      temp %= 10000000;
    }
    if (temp >= 100000) {
      int lakh = temp ~/ 100000;
      result += "${_convertThreeDigits(lakh)} Lakh ";
      temp %= 100000;
    }
    if (temp >= 1000) {
      int thousand = temp ~/ 1000;
      result += "${_convertThreeDigits(thousand)} Thousand ";
      temp %= 1000;
    }
    if (temp > 0) {
      result += "${_convertThreeDigits(temp)} ";
    }

    result = result.trim();
    if (result.isEmpty) {
      result = "Zero";
    }

    String finalStr = "$currencyName $result";

    if (paise > 0) {
      finalStr += " and ${_convertThreeDigits(paise)} $subunitName";
    }

    return "$finalStr Only";
  }

  /// Converts number to words in International Numbering System (Billion, Million, Thousand)
  static String convertInternational(double amount, {String currencyName = "Dollars", String subunitName = "Cents"}) {
    if (amount == 0) return "$currencyName Zero Only";

    final int dollars = amount.floor();
    final int cents = ((amount - dollars) * 100).round();

    String result = "";
    int temp = dollars;

    if (temp >= 1000000000) {
      int billions = temp ~/ 1000000000;
      result += "${_convertThreeDigits(billions)} Billion ";
      temp %= 1000000000;
    }
    if (temp >= 1000000) {
      int millions = temp ~/ 1000000;
      result += "${_convertThreeDigits(millions)} Million ";
      temp %= 1000000;
    }
    if (temp >= 1000) {
      int thousands = temp ~/ 1000;
      result += "${_convertThreeDigits(thousands)} Thousand ";
      temp %= 1000;
    }
    if (temp > 0) {
      result += "${_convertThreeDigits(temp)} ";
    }

    result = result.trim();
    if (result.isEmpty) {
      result = "Zero";
    }

    String finalStr = "$result $currencyName";

    if (cents > 0) {
      finalStr += " and ${_convertThreeDigits(cents)} $subunitName";
    }

    return "$finalStr Only";
  }

  static String toWords(double amount, {String currencyCode = 'INR'}) {
    if (currencyCode.toUpperCase() == 'INR') {
      return convertIndian(amount, currencyName: "Rupees", subunitName: "Paise");
    } else {
      return convertInternational(amount, currencyName: currencyCode, subunitName: "Cents");
    }
  }
}
