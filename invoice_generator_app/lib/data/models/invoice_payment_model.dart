class InvoicePaymentModel {
  final int? id;
  final int invoiceId;
  final double amount;
  final String paymentDate;
  final String paymentMode; // Cash, UPI, Bank Transfer, Cheque, Card
  final String? referenceNo;
  final String? notes;

  InvoicePaymentModel({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.paymentMode = 'UPI',
    this.referenceNo,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_mode': paymentMode,
      'reference_no': referenceNo,
      'notes': notes,
    };
  }

  factory InvoicePaymentModel.fromMap(Map<String, dynamic> map) {
    return InvoicePaymentModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['payment_date'] ?? '',
      paymentMode: map['payment_mode'] ?? 'UPI',
      referenceNo: map['reference_no'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) => InvoicePaymentModel.fromMap(json);
}
