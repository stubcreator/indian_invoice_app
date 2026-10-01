class ClientModel {
  final int? id;
  final int? businessId;
  final String name;
  final String? companyName;
  final String? gstin;
  final String? email;
  final String? phone;
  final String? billingAddress;
  final String? shippingAddress;
  final String? state;
  final String? stateCode;
  final String country;
  final String? notes;

  ClientModel({
    this.id,
    this.businessId,
    required this.name,
    this.companyName,
    this.gstin,
    this.email,
    this.phone,
    this.billingAddress,
    this.shippingAddress,
    this.state,
    this.stateCode,
    this.country = 'India',
    this.notes,
  });

  String get displayName => companyName != null && companyName!.trim().isNotEmpty
      ? '$name ($companyName)'
      : name;

  ClientModel copyWith({
    int? id,
    int? businessId,
    String? name,
    String? companyName,
    String? gstin,
    String? email,
    String? phone,
    String? billingAddress,
    String? shippingAddress,
    String? state,
    String? stateCode,
    String? country,
    String? notes,
  }) {
    return ClientModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      country: country ?? this.country,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'business_id': businessId,
      'name': name,
      'company_name': companyName,
      'gstin': gstin,
      'email': email,
      'phone': phone,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'state': state,
      'state_code': stateCode,
      'country': country,
      'notes': notes,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int?,
      businessId: map['business_id'] as int?,
      name: map['name'] ?? '',
      companyName: map['company_name'],
      gstin: map['gstin'],
      email: map['email'],
      phone: map['phone'],
      billingAddress: map['billing_address'],
      shippingAddress: map['shipping_address'],
      state: map['state'],
      stateCode: map['state_code'],
      country: map['country'] ?? 'India',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel.fromMap(json);
}
