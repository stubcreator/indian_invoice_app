import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM, yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _shortDisplayFormat = DateFormat('dd/MM/yyyy');

  static String formatDisplay(DateTime? date) {
    if (date == null) return '';
    return _displayFormat.format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '';
    return _shortDisplayFormat.format(date);
  }

  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        return _shortDisplayFormat.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }
}
