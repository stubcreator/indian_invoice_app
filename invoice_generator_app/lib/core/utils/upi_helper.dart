class UpiHelper {
  /// Generates a standard NPCI UPI URI string that can be encoded into a QR code
  /// Format: upi://pay?pa=upiId&pn=PayeeName&am=100.00&cu=INR&tn=InvoiceNo
  static String generateUpiUri({
    required String upiId,
    required String payeeName,
    double? amount,
    String? transactionNote,
  }) {
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final note = transactionNote != null ? Uri.encodeComponent(transactionNote.trim()) : '';

    String uri = 'upi://pay?pa=$cleanUpi&pn=$cleanName&cu=INR';

    if (amount != null && amount > 0) {
      uri += '&am=${amount.toStringAsFixed(2)}';
    }

    if (note.isNotEmpty) {
      uri += '&tn=$note';
    }

    return uri;
  }

  /// Simple check for a valid UPI ID (e.g. name@bank)
  static bool isValidUpiId(String? upiId) {
    if (upiId == null) return false;
    final pattern = RegExp(r'^[\w.-]+@[\w.-]+$');
    return pattern.hasMatch(upiId.trim());
  }
}
