import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats amount in Indian numbering system: 1,23,45,678.00
  static String formatIndian(double amount, {String symbol = '₹', int decimalDigits = 2}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(decimalDigits).split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      
      // Group the remaining digits into pairs of 2
      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      integerPart = '${buffer.toString()},$lastThree';
    }

    final sign = isNegative ? '-' : '';
    return '$sign$symbol $integerPart$decimalPart';
  }

  /// Formats amount in International numbering system: 12,345,678.00
  static String formatInternational(double amount, {String symbol = '\$', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Adaptive formatter based on currency code (e.g., INR uses Indian format, USD uses standard)
  static String format(
    double amount, {
    String currencyCode = 'INR',
    String symbol = '₹',
    int decimalDigits = 2,
  }) {
    if (currencyCode.toUpperCase() == 'INR' || symbol == '₹') {
      return formatIndian(amount, symbol: symbol, decimalDigits: decimalDigits);
    } else {
      return formatInternational(amount, symbol: symbol, decimalDigits: decimalDigits);
    }
  }
}
