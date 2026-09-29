class BusinessModel {
  final int? id;
  final String businessName;
  final String? tradeName;
  final String? ownerName;
  final String? gstin;
  final String? pan;
  final String? email;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? stateCode;
  final String? pincode;
  final String country;
  final String? logoPath;
  final String? signaturePath;

  // Bank & UPI Details
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;
  final String? upiId;

  BusinessModel({
    this.id,
    required this.businessName,
    this.tradeName,
    this.ownerName,
    this.gstin,
    this.pan,
    this.email,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.stateCode,
    this.pincode,
    this.country = 'India',
    this.logoPath,
    this.signaturePath,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.upiId,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      if (state != null && state!.isNotEmpty) '$state${stateCode != null ? " ($stateCode)" : ""}',
      pincode,
      country,
    ].where((e) => e != null && e.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  BusinessModel copyWith({
    int? id,
    String? businessName,
    String? tradeName,
    String? ownerName,
    String? gstin,
    String? pan,
    String? email,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? stateCode,
    String? pincode,
    String? country,
    String? logoPath,
    String? signaturePath,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? upiId,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      tradeName: tradeName ?? this.tradeName,
      ownerName: ownerName ?? this.ownerName,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      upiId: upiId ?? this.upiId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'business_name': businessName,
      'trade_name': tradeName,
      'owner_name': ownerName,
      'gstin': gstin,
      'pan': pan,
      'email': email,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'state_code': stateCode,
      'pincode': pincode,
      'country': country,
      'logo_path': logoPath,
      'signature_path': signaturePath,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_holder_name': accountHolderName,
      'upi_id': upiId,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] as int?,
      businessName: map['business_name'] ?? '',
      tradeName: map['trade_name'],
      ownerName: map['owner_name'],
      gstin: map['gstin'],
      pan: map['pan'],
      email: map['email'],
      phone: map['phone'],
      addressLine1: map['address_line1'],
      addressLine2: map['address_line2'],
      city: map['city'],
      state: map['state'],
      stateCode: map['state_code'],
      pincode: map['pincode'],
      country: map['country'] ?? 'India',
      logoPath: map['logo_path'],
      signaturePath: map['signature_path'],
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      ifscCode: map['ifsc_code'],
      accountHolderName: map['account_holder_name'],
      upiId: map['upi_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel.fromMap(json);
}
