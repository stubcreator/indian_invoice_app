import '../../models/invoice_model.dart';
import '../../models/invoice_payment_model.dart';

class DashboardMetrics {
  final double totalInvoiced;
  final double totalPaid;
  final double totalUnpaid;
  final double totalOverdue;
  final int totalCount;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;

  DashboardMetrics({
    this.totalInvoiced = 0.0,
    this.totalPaid = 0.0,
    this.totalUnpaid = 0.0,
    this.totalOverdue = 0.0,
    this.totalCount = 0,
    this.paidCount = 0,
    this.unpaidCount = 0,
    this.overdueCount = 0,
  });
}

abstract class IInvoiceRepository {
  Future<List<InvoiceModel>> getInvoices({String? status, String? searchQuery});
  Future<InvoiceModel?> getInvoiceById(int id);
  Future<int> insertInvoice(InvoiceModel invoice);
  Future<int> updateInvoice(InvoiceModel invoice);
  Future<int> deleteInvoice(int id);
  Future<String> generateNextInvoiceNumber(String prefix);
  Future<int> addPayment(InvoicePaymentModel payment);
  Future<List<InvoicePaymentModel>> getPayments(int invoiceId);
  Future<DashboardMetrics> getDashboardMetrics();
}
