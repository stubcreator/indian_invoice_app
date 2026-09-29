import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontHelper {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.ThemeData> getPdfTheme() async {
    if (_regular == null || _bold == null) {
      final regData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      _regular = pw.Font.ttf(regData);
      _bold = pw.Font.ttf(boldData);
    }

    return pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
    );
  }
}
