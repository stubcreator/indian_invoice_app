import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import '../data/models/invoice_item_model.dart';
import '../data/models/invoice_payment_model.dart';
import '../data/models/client_model.dart';
import '../data/models/business_model.dart';
import '../data/models/app_settings_model.dart';
import '../data/repositories/interfaces/i_invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  final IInvoiceRepository _repository;

  List<InvoiceModel> _invoices = [];
  DashboardMetrics _metrics = DashboardMetrics();
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  // Active Draft state for creating/editing invoice
  InvoiceModel? _draftInvoice;

  InvoiceProvider({required IInvoiceRepository repository})
      : _repository = repository {
    loadInvoices();
    loadMetrics();
  }

  List<InvoiceModel> get invoices => _invoices;
  DashboardMetrics get metrics => _metrics;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  InvoiceModel? get draftInvoice => _draftInvoice;

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _repository.getInvoices(
        status: _selectedStatus,
        searchQuery: _searchQuery,
      );
    } catch (_) {
      _invoices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMetrics() async {
    try {
      _metrics = await _repository.getDashboardMetrics();
      notifyListeners();
    } catch (_) {}
  }

  void setFilterStatus(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      loadInvoices();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadInvoices();
  }

  /// Initializes a new draft invoice
  Future<void> initNewDraft({
    required BusinessModel? business,
    required AppSettingsModel settings,
  }) async {
    final nextNumber = await _repository.generateNextInvoiceNumber(settings.invoicePrefix);
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final due = now.add(const Duration(days: 15));
    final dueDate = "${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}";

    _draftInvoice = InvoiceModel(
      invoiceNumber: nextNumber,
      invoiceDate: today,
      dueDate: dueDate,
      businessId: business?.id,
      clientName: '',
      currencyCode: settings.currencyCode,
      currencySymbol: settings.currencySymbol,
      taxMode: settings.taxMode,
      termsConditions: settings.defaultTerms,
      notes: settings.defaultNotes,
      signaturePath: business?.signaturePath ?? settings.signaturePath,
      templateId: settings.defaultTemplateId,
      createdAt: DateTime.now().toIso8601String(),
      items: [],
      business: business,
    );
    notifyListeners();
  }

  /// Sets an existing invoice as draft for editing
  Future<void> loadDraftForEdit(int invoiceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _draftInvoice = await _repository.getInvoiceById(invoiceId);
    } catch (_) {
      _draftInvoice = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to check if current draft is Intra-State (CGST+SGST) or Inter-State (IGST)
  bool get isDraftIntraState {
    if (_draftInvoice == null) return true;
    final bizState = _draftInvoice!.business?.stateCode?.trim().toUpperCase();
    final posState = _draftInvoice!.placeOfSupplyCode?.trim().toUpperCase();

    if (bizState != null && posState != null && bizState.isNotEmpty && posState.isNotEmpty) {
      return bizState == posState;
    }
    return true; // Default to intra-state if not specified
  }

  /// Set or change the client on the draft
  void setDraftClient(ClientModel client) {
    if (_draftInvoice == null) return;

    _draftInvoice = _draftInvoice!.copyWith(
      clientId: client.id,
      clientName: client.name,
      clientCompanyName: client.companyName,
      clientGstin: client.gstin,
      placeOfSupply: client.state,
      placeOfSupplyCode: client.stateCode,
      client: client,
    );

    // Recalculate line items with new Place of Supply (Intra vs Inter)
    _recalculateDraft();
  }

  void updateDraftHeader({
    String? invoiceNumber,
    String? invoiceDate,
    String? dueDate,
    String? poNumber,
    String? poDate,
    String? placeOfSupply,
    String? placeOfSupplyCode,
    bool? isReverseCharge,
    String? notes,
    String? termsConditions,
    String? signaturePath,
    int? templateId,
  }) {
    if (_draftInvoice == null) return;

    _draftInvoice = _draftInvoice!.copyWith(
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      poNumber: poNumber,
      poDate: poDate,
      placeOfSupply: placeOfSupply,
      placeOfSupplyCode: placeOfSupplyCode,
      isReverseCharge: isReverseCharge,
      notes: notes,
      termsConditions: termsConditions,
      signaturePath: signaturePath,
      templateId: templateId,
    );

    _recalculateDraft();
  }

  void updateDraftFinancials({
    double? overallDiscountInput,
    String? discountType,
    double? shippingCharge,
    double? paidAmount,
  }) {
    if (_draftInvoice == null) return;

    final discRate = overallDiscountInput ?? _draftInvoice!.discountRate;
    final discType = discountType ?? _draftInvoice!.discountType;
    final shipping = shippingCharge ?? _draftInvoice!.shippingCharge;
    final paid = paidAmount ?? _draftInvoice!.paidAmount;

    _recalculateDraft(
      discountRate: discRate,
      discountType: discType,
      shippingCharge: shipping,
      paidAmount: paid,
    );
  }

  /// Add line item to draft
  void addDraftItem(InvoiceItemModel item) {
    if (_draftInvoice == null) return;

    final updatedItems = List<InvoiceItemModel>.from(_draftInvoice!.items)..add(item);
    _draftInvoice = _draftInvoice!.copyWith(items: updatedItems);
    _recalculateDraft();
  }

  /// Update line item in draft
  void updateDraftItem(int index, InvoiceItemModel item) {
    if (_draftInvoice == null || index < 0 || index >= _draftInvoice!.items.length) return;

    final updatedItems = List<InvoiceItemModel>.from(_draftInvoice!.items);
    updatedItems[index] = item;
    _draftInvoice = _draftInvoice!.copyWith(items: updatedItems);
    _recalculateDraft();
  }

  /// Remove line item from draft
  void removeDraftItem(int index) {
    if (_draftInvoice == null || index < 0 || index >= _draftInvoice!.items.length) return;

    final updatedItems = List<InvoiceItemModel>.from(_draftInvoice!.items)..removeAt(index);
    _draftInvoice = _draftInvoice!.copyWith(items: updatedItems);
    _recalculateDraft();
  }

  /// Recalculates items and totals
  void _recalculateDraft({
    double? discountRate,
    String? discountType,
    double? shippingCharge,
    double? paidAmount,
  }) {
    if (_draftInvoice == null) return;

    final isIntra = isDraftIntraState;
    final isGst = _draftInvoice!.taxMode.toLowerCase() == 'gst';

    // Recalculate each item's tax split based on current intra/inter status
    final recalculatedItems = _draftInvoice!.items.map((item) {
      return InvoiceItemModel.calculate(
        id: item.id,
        invoiceId: item.invoiceId,
        itemId: item.itemId,
        itemName: item.itemName,
        description: item.description,
        hsnSacCode: item.hsnSacCode,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        discountAmount: item.discountAmount,
        gstRate: item.gstRate,
        cessRate: 0.0,
        isIntraState: isIntra,
        isGstMode: isGst,
      );
    }).toList();

    _draftInvoice = InvoiceModel.calculate(
      id: _draftInvoice!.id,
      invoiceNumber: _draftInvoice!.invoiceNumber,
      invoiceDate: _draftInvoice!.invoiceDate,
      dueDate: _draftInvoice!.dueDate,
      poNumber: _draftInvoice!.poNumber,
      poDate: _draftInvoice!.poDate,
      clientId: _draftInvoice!.clientId,
      clientName: _draftInvoice!.clientName,
      clientCompanyName: _draftInvoice!.clientCompanyName,
      clientGstin: _draftInvoice!.clientGstin,
      businessId: _draftInvoice!.businessId,
      placeOfSupply: _draftInvoice!.placeOfSupply,
      placeOfSupplyCode: _draftInvoice!.placeOfSupplyCode,
      isReverseCharge: _draftInvoice!.isReverseCharge,
      currencyCode: _draftInvoice!.currencyCode,
      currencySymbol: _draftInvoice!.currencySymbol,
      taxMode: _draftInvoice!.taxMode,
      overallDiscountInput: discountRate ?? _draftInvoice!.discountRate,
      discountType: discountType ?? _draftInvoice!.discountType,
      shippingCharge: shippingCharge ?? _draftInvoice!.shippingCharge,
      paidAmount: paidAmount ?? _draftInvoice!.paidAmount,
      notes: _draftInvoice!.notes,
      termsConditions: _draftInvoice!.termsConditions,
      signaturePath: _draftInvoice!.signaturePath,
      templateId: _draftInvoice!.templateId,
      createdAt: _draftInvoice!.createdAt,
      items: recalculatedItems,
      client: _draftInvoice!.client,
      business: _draftInvoice!.business,
      payments: _draftInvoice!.payments,
    );

    notifyListeners();
  }

  /// Saves the active draft to database
  Future<int?> saveDraft() async {
    if (_draftInvoice == null) return null;

    try {
      int savedId;
      if (_draftInvoice!.id == null) {
        savedId = await _repository.insertInvoice(_draftInvoice!);
      } else {
        savedId = await _repository.updateInvoice(_draftInvoice!);
      }

      await loadInvoices();
      await loadMetrics();

      // Refresh draft with saved ID
      _draftInvoice = await _repository.getInvoiceById(savedId);
      notifyListeners();
      return savedId;
    } catch (_) {
      return null;
    }
  }

  /// Delete an invoice
  Future<bool> deleteInvoice(int id) async {
    try {
      await _repository.deleteInvoice(id);
      await loadInvoices();
      await loadMetrics();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Record payment on an invoice
  Future<bool> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentMode,
    String? referenceNo,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final payment = InvoicePaymentModel(
        invoiceId: invoiceId,
        amount: amount,
        paymentDate: dateStr,
        paymentMode: paymentMode,
        referenceNo: referenceNo,
        notes: notes,
      );

      await _repository.addPayment(payment);
      await loadInvoices();
      await loadMetrics();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get single invoice by ID
  Future<InvoiceModel?> getInvoice(int id) async {
    return await _repository.getInvoiceById(id);
  }
}
