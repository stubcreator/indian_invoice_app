import 'client_model.dart';
import 'business_model.dart';
import 'invoice_item_model.dart';
import 'invoice_payment_model.dart';

class InvoiceModel {
  final int? id;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final String? poNumber;
  final String? poDate;

  final int? clientId;
  final String clientName;
  final String? clientCompanyName;
  final String? clientGstin;

  final int? businessId;
  final String? placeOfSupply;
  final String? placeOfSupplyCode;
  final bool isReverseCharge;

  final String currencyCode;
  final String currencySymbol;
  final String taxMode; // 'gst', 'vat', 'none'

  final double subtotal;
  final double discountAmount;
  final double discountRate;
  final String discountType; // 'flat' or 'percent'
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalCess;
  final double shippingCharge;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final double balanceDue;

  final String status; // 'draft', 'unpaid', 'paid', 'partially_paid', 'overdue'
  final String? notes;
  final String? termsConditions;
  final String? signaturePath;
  final int templateId;
  final String createdAt;

  // Attached relational data
  final List<InvoiceItemModel> items;
  final ClientModel? client;
  final BusinessModel? business;
  final List<InvoicePaymentModel> payments;

  InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    this.poNumber,
    this.poDate,
    this.clientId,
    required this.clientName,
    this.clientCompanyName,
    this.clientGstin,
    this.businessId,
    this.placeOfSupply,
    this.placeOfSupplyCode,
    this.isReverseCharge = false,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.taxMode = 'gst',
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.discountRate = 0.0,
    this.discountType = 'flat',
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.totalCess = 0.0,
    this.shippingCharge = 0.0,
    this.roundOff = 0.0,
    this.grandTotal = 0.0,
    this.paidAmount = 0.0,
    this.balanceDue = 0.0,
    this.status = 'unpaid',
    this.notes,
    this.termsConditions,
    this.signaturePath,
    this.templateId = 1,
    required this.createdAt,
    this.items = const [],
    this.client,
    this.business,
    this.payments = const [],
  });

  /// Recalculates all totals based on items, discounts, shipping, and payments
  static InvoiceModel calculate({
    int? id,
    required String invoiceNumber,
    required String invoiceDate,
    required String dueDate,
    String? poNumber,
    String? poDate,
    int? clientId,
    required String clientName,
    String? clientCompanyName,
    String? clientGstin,
    int? businessId,
    String? placeOfSupply,
    String? placeOfSupplyCode,
    bool isReverseCharge = false,
    String currencyCode = 'INR',
    String currencySymbol = '₹',
    String taxMode = 'gst',
    double overallDiscountInput = 0.0,
    String discountType = 'flat', // 'flat' or 'percent'
    double shippingCharge = 0.0,
    double paidAmount = 0.0,
    String? notes,
    String? termsConditions,
    String? signaturePath,
    int templateId = 1,
    String? createdAt,
    required List<InvoiceItemModel> items,
    ClientModel? client,
    BusinessModel? business,
    List<InvoicePaymentModel> payments = const [],
  }) {
    double subtotal = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;
    double cess = 0.0;

    for (var item in items) {
      subtotal += item.taxableAmount;
      cgst += item.cgstAmount;
      sgst += item.sgstAmount;
      igst += item.igstAmount;
      cess += item.cessAmount;
    }

    // Compute overall invoice discount
    double calculatedDiscount = 0.0;
    if (discountType == 'percent') {
      calculatedDiscount = (subtotal * overallDiscountInput) / 100.0;
    } else {
      calculatedDiscount = overallDiscountInput;
    }

    final double totalTaxes = cgst + sgst + igst + cess;
    final double unroundedTotal =
        (subtotal - calculatedDiscount + totalTaxes + shippingCharge).clamp(0.0, double.infinity);

    final double roundedTotal = unroundedTotal.roundToDouble();
    final double roundOff = roundedTotal - unroundedTotal;

    final double balance = (roundedTotal - paidAmount).clamp(0.0, double.infinity);

    // Determine status
    String status = 'unpaid';
    if (paidAmount >= roundedTotal && roundedTotal > 0) {
      status = 'paid';
    } else if (paidAmount > 0 && paidAmount < roundedTotal) {
      status = 'partially_paid';
    } else {
      // Check overdue
      try {
        final due = DateTime.parse(dueDate);
        if (DateTime.now().isAfter(due)) {
          status = 'overdue';
        }
      } catch (_) {}
    }

    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      poNumber: poNumber,
      poDate: poDate,
      clientId: clientId,
      clientName: clientName,
      clientCompanyName: clientCompanyName,
      clientGstin: clientGstin,
      businessId: businessId,
      placeOfSupply: placeOfSupply,
      placeOfSupplyCode: placeOfSupplyCode,
      isReverseCharge: isReverseCharge,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      taxMode: taxMode,
      subtotal: subtotal,
      discountAmount: calculatedDiscount,
      discountRate: overallDiscountInput,
      discountType: discountType,
      totalCgst: cgst,
      totalSgst: sgst,
      totalIgst: igst,
      totalCess: cess,
      shippingCharge: shippingCharge,
      roundOff: roundOff,
      grandTotal: roundedTotal,
      paidAmount: paidAmount,
      balanceDue: balance,
      status: status,
      notes: notes,
      termsConditions: termsConditions,
      signaturePath: signaturePath,
      templateId: templateId,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
      items: items,
      client: client,
      business: business,
      payments: payments,
    );
  }

  InvoiceModel copyWith({
    int? id,
    String? invoiceNumber,
    String? invoiceDate,
    String? dueDate,
    String? poNumber,
    String? poDate,
    int? clientId,
    String? clientName,
    String? clientCompanyName,
    String? clientGstin,
    int? businessId,
    String? placeOfSupply,
    String? placeOfSupplyCode,
    bool? isReverseCharge,
    String? currencyCode,
    String? currencySymbol,
    String? taxMode,
    double? subtotal,
    double? discountAmount,
    double? discountRate,
    String? discountType,
    double? totalCgst,
    double? totalSgst,
    double? totalIgst,
    double? totalCess,
    double? shippingCharge,
    double? roundOff,
    double? grandTotal,
    double? paidAmount,
    double? balanceDue,
    String? status,
    String? notes,
    String? termsConditions,
    String? signaturePath,
    int? templateId,
    String? createdAt,
    List<InvoiceItemModel>? items,
    ClientModel? client,
    BusinessModel? business,
    List<InvoicePaymentModel>? payments,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      poNumber: poNumber ?? this.poNumber,
      poDate: poDate ?? this.poDate,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientCompanyName: clientCompanyName ?? this.clientCompanyName,
      clientGstin: clientGstin ?? this.clientGstin,
      businessId: businessId ?? this.businessId,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      placeOfSupplyCode: placeOfSupplyCode ?? this.placeOfSupplyCode,
      isReverseCharge: isReverseCharge ?? this.isReverseCharge,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxMode: taxMode ?? this.taxMode,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountRate: discountRate ?? this.discountRate,
      discountType: discountType ?? this.discountType,
      totalCgst: totalCgst ?? this.totalCgst,
      totalSgst: totalSgst ?? this.totalSgst,
      totalIgst: totalIgst ?? this.totalIgst,
      totalCess: totalCess ?? this.totalCess,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsConditions: termsConditions ?? this.termsConditions,
      signaturePath: signaturePath ?? this.signaturePath,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      client: client ?? this.client,
      business: business ?? this.business,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'due_date': dueDate,
      'po_number': poNumber,
      'po_date': poDate,
      'client_id': clientId,
      'client_name': clientName,
      'client_company_name': clientCompanyName,
      'client_gstin': clientGstin,
      'business_id': businessId,
      'place_of_supply': placeOfSupply,
      'place_of_supply_code': placeOfSupplyCode,
      'is_reverse_charge': isReverseCharge ? 1 : 0,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'tax_mode': taxMode,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_rate': discountRate,
      'discount_type': discountType,
      'total_cgst': totalCgst,
      'total_sgst': totalSgst,
      'total_igst': totalIgst,
      'total_cess': totalCess,
      'shipping_charge': shippingCharge,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      'status': status,
      'notes': notes,
      'terms_conditions': termsConditions,
      'signature_path': signaturePath,
      'template_id': templateId,
      'created_at': createdAt,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, {List<InvoiceItemModel>? items, ClientModel? client, BusinessModel? business, List<InvoicePaymentModel>? payments}) {
    return InvoiceModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] ?? '',
      invoiceDate: map['invoice_date'] ?? '',
      dueDate: map['due_date'] ?? '',
      poNumber: map['po_number'],
      poDate: map['po_date'],
      clientId: map['client_id'] as int?,
      clientName: map['client_name'] ?? '',
      clientCompanyName: map['client_company_name'],
      clientGstin: map['client_gstin'],
      businessId: map['business_id'] as int?,
      placeOfSupply: map['place_of_supply'],
      placeOfSupplyCode: map['place_of_supply_code'],
      isReverseCharge: (map['is_reverse_charge'] as int?) == 1,
      currencyCode: map['currency_code'] ?? 'INR',
      currencySymbol: map['currency_symbol'] ?? '₹',
      taxMode: map['tax_mode'] ?? 'gst',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountRate: (map['discount_rate'] as num?)?.toDouble() ?? 0.0,
      discountType: map['discount_type'] ?? 'flat',
      totalCgst: (map['total_cgst'] as num?)?.toDouble() ?? 0.0,
      totalSgst: (map['total_sgst'] as num?)?.toDouble() ?? 0.0,
      totalIgst: (map['total_igst'] as num?)?.toDouble() ?? 0.0,
      totalCess: (map['total_cess'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (map['shipping_charge'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'unpaid',
      notes: map['notes'],
      termsConditions: map['terms_conditions'],
      signaturePath: map['signature_path'],
      templateId: map['template_id'] as int? ?? 1,
      createdAt: map['created_at'] ?? '',
      items: items ?? [],
      client: client,
      business: business,
      payments: payments ?? [],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel.fromMap(json);
}
