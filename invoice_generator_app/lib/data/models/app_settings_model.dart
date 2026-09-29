class AppSettingsModel {
  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final String taxMode; // 'gst', 'vat', 'salestax', 'none'
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String defaultTerms;
  final String defaultNotes;
  final String? signaturePath;
  final int? activeBusinessId;
  final int defaultTemplateId;

  AppSettingsModel({
    this.countryCode = 'IN',
    this.countryName = 'India',
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.taxMode = 'gst',
    this.invoicePrefix = 'INV-',
    this.nextInvoiceNumber = 1,
    this.defaultTerms =
        "1. Goods once sold will not be taken back.\n2. Interest @18% p.a. will be charged if payment is not made within the due date.\n3. Subject to jurisdiction.",
    this.defaultNotes = "Thank you for your business!",
    this.signaturePath,
    this.activeBusinessId,
    this.defaultTemplateId = 1,
  });

  bool get isGstMode => taxMode.toLowerCase() == 'gst';

  AppSettingsModel copyWith({
    String? countryCode,
    String? countryName,
    String? currencyCode,
    String? currencySymbol,
    String? taxMode,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? defaultTerms,
    String? defaultNotes,
    String? signaturePath,
    int? activeBusinessId,
    int? defaultTemplateId,
  }) {
    return AppSettingsModel(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxMode: taxMode ?? this.taxMode,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      signaturePath: signaturePath ?? this.signaturePath,
      activeBusinessId: activeBusinessId ?? this.activeBusinessId,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'country_code': countryCode,
      'country_name': countryName,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'tax_mode': taxMode,
      'invoice_prefix': invoicePrefix,
      'next_invoice_number': nextInvoiceNumber,
      'default_terms': defaultTerms,
      'default_notes': defaultNotes,
      'signature_path': signaturePath,
      'active_business_id': activeBusinessId,
      'default_template_id': defaultTemplateId,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      countryCode: map['country_code'] ?? 'IN',
      countryName: map['country_name'] ?? 'India',
      currencyCode: map['currency_code'] ?? 'INR',
      currencySymbol: map['currency_symbol'] ?? '₹',
      taxMode: map['tax_mode'] ?? 'gst',
      invoicePrefix: map['invoice_prefix'] ?? 'INV-',
      nextInvoiceNumber: (map['next_invoice_number'] as int?) ?? 1,
      defaultTerms: map['default_terms'] ??
          "1. Goods once sold will not be taken back.\n2. Interest @18% p.a. will be charged if payment is not made within the due date.\n3. Subject to jurisdiction.",
      defaultNotes: map['default_notes'] ?? "Thank you for your business!",
      signaturePath: map['signature_path'],
      activeBusinessId: map['active_business_id'] as int?,
      defaultTemplateId: (map['default_template_id'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel.fromMap(json);
}
