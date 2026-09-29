class InvoiceItemModel {
  final int? id;
  final int? invoiceId;
  final int? itemId;
  final String itemName;
  final String? description;
  final String? hsnSacCode;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountAmount;
  final double taxableAmount;
  final double gstRate; // Total GST % (e.g. 18.0)
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalAmount;

  InvoiceItemModel({
    this.id,
    this.invoiceId,
    this.itemId,
    required this.itemName,
    this.description,
    this.hsnSacCode,
    required this.quantity,
    this.unit = 'PCS',
    required this.unitPrice,
    this.discountAmount = 0.0,
    required this.taxableAmount,
    this.gstRate = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
    required this.totalAmount,
  });

  /// Factory method to calculate line item taxes automatically
  /// based on whether it is intra-state (CGST+SGST) or inter-state (IGST),
  /// or simple VAT / Sales tax.
  factory InvoiceItemModel.calculate({
    int? id,
    int? invoiceId,
    int? itemId,
    required String itemName,
    String? description,
    String? hsnSacCode,
    required double quantity,
    String unit = 'PCS',
    required double unitPrice,
    double discountAmount = 0.0,
    double gstRate = 0.0,
    double cessRate = 0.0,
    bool isIntraState = true,
    bool isGstMode = true,
  }) {
    final double rawAmount = quantity * unitPrice;
    final double taxable = (rawAmount - discountAmount).clamp(0.0, double.infinity);

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;
    double cess = 0.0;

    if (isGstMode) {
      if (isIntraState) {
        final halfRate = gstRate / 2.0;
        cgst = (taxable * halfRate) / 100.0;
        sgst = (taxable * halfRate) / 100.0;
      } else {
        igst = (taxable * gstRate) / 100.0;
      }
    } else {
      // International / VAT mode: place entire tax in igstAmount or simple tax
      igst = (taxable * gstRate) / 100.0;
    }

    if (cessRate > 0) {
      cess = (taxable * cessRate) / 100.0;
    }

    final double total = taxable + cgst + sgst + igst + cess;

    return InvoiceItemModel(
      id: id,
      invoiceId: invoiceId,
      itemId: itemId,
      itemName: itemName,
      description: description,
      hsnSacCode: hsnSacCode,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      discountAmount: discountAmount,
      taxableAmount: taxable,
      gstRate: gstRate,
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      cessAmount: cess,
      totalAmount: total,
    );
  }

  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    String? itemName,
    String? description,
    String? hsnSacCode,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? discountAmount,
    double? taxableAmount,
    double? gstRate,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? cessAmount,
    double? totalAmount,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      gstRate: gstRate ?? this.gstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      cessAmount: cessAmount ?? this.cessAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'item_id': itemId,
      'item_name': itemName,
      'description': description,
      'hsn_sac_code': hsnSacCode,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'taxable_amount': taxableAmount,
      'gst_rate': gstRate,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'cess_amount': cessAmount,
      'total_amount': totalAmount,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      itemId: map['item_id'] as int?,
      itemName: map['item_name'] ?? '',
      description: map['description'],
      hsnSacCode: map['hsn_sac_code'],
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'PCS',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (map['taxable_amount'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (map['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (map['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (map['igst_amount'] as num?)?.toDouble() ?? 0.0,
      cessAmount: (map['cess_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) => InvoiceItemModel.fromMap(json);
}
