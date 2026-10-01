class ItemModel {
  final int? id;
  final int? businessId;
  final String name;
  final String? description;
  final String? hsnSacCode;
  final double unitPrice;
  final String unit;
  final double gstRate; // e.g. 18.0
  final double cessRate; // e.g. 0.0
  final double stockQuantity; // For inventory readiness
  final bool isService;

  ItemModel({
    this.id,
    this.businessId,
    required this.name,
    this.description,
    this.hsnSacCode,
    required this.unitPrice,
    this.unit = 'PCS',
    this.gstRate = 18.0,
    this.cessRate = 0.0,
    this.stockQuantity = 0.0,
    this.isService = false,
  });

  ItemModel copyWith({
    int? id,
    int? businessId,
    String? name,
    String? description,
    String? hsnSacCode,
    double? unitPrice,
    String? unit,
    double? gstRate,
    double? cessRate,
    double? stockQuantity,
    bool? isService,
  }) {
    return ItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      gstRate: gstRate ?? this.gstRate,
      cessRate: cessRate ?? this.cessRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isService: isService ?? this.isService,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'hsn_sac_code': hsnSacCode,
      'unit_price': unitPrice,
      'unit': unit,
      'gst_rate': gstRate,
      'cess_rate': cessRate,
      'stock_quantity': stockQuantity,
      'is_service': isService ? 1 : 0,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      businessId: map['business_id'] as int?,
      name: map['name'] ?? '',
      description: map['description'],
      hsnSacCode: map['hsn_sac_code'],
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'PCS',
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 18.0,
      cessRate: (map['cess_rate'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      isService: (map['is_service'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel.fromMap(json);
}
