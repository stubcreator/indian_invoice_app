import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import '../../models/invoice_payment_model.dart';
import '../../models/client_model.dart';
import '../../models/business_model.dart';
import '../interfaces/i_invoice_repository.dart';

class SqliteInvoiceRepository implements IInvoiceRepository {
  final DatabaseHelper _dbHelper;

  SqliteInvoiceRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<InvoiceModel>> getInvoices({String? status, String? searchQuery}) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      whereClauses.add('status = ?');
      whereArgs.add(status.toLowerCase());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('(invoice_number LIKE ? OR client_name LIKE ? OR client_company_name LIKE ?)');
      whereArgs.addAll([query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    return results.map((m) => InvoiceModel.fromMap(m)).toList();
  }

  @override
  Future<InvoiceModel?> getInvoiceById(int id) async {
    final db = await _dbHelper.database;
    final invoiceResults = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (invoiceResults.isEmpty) return null;

    final invoiceMap = invoiceResults.first;

    // Fetch items
    final itemResults = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final items = itemResults.map((m) => InvoiceItemModel.fromMap(m)).toList();

    // Fetch payments
    final paymentResults = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final payments = paymentResults.map((m) => InvoicePaymentModel.fromMap(m)).toList();

    // Fetch client
    ClientModel? client;
    final clientId = invoiceMap['client_id'] as int?;
    if (clientId != null) {
      final cResults = await db.query('clients', where: 'id = ?', whereArgs: [clientId]);
      if (cResults.isNotEmpty) {
        client = ClientModel.fromMap(cResults.first);
      }
    }

    // Fetch business
    BusinessModel? business;
    final bResults = await db.query('businesses', limit: 1);
    if (bResults.isNotEmpty) {
      business = BusinessModel.fromMap(bResults.first);
    }

    return InvoiceModel.fromMap(
      invoiceMap,
      items: items,
      client: client,
      business: business,
      payments: payments,
    );
  }

  @override
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Insert invoice header
      final invoiceMap = invoice.toMap();
      final invoiceId = await txn.insert('invoices', invoiceMap);

      // 2. Insert items
      for (var item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoiceId).toMap();
        await txn.insert('invoice_items', itemMap);
      }

      // 3. Increment next invoice number in settings
      await txn.rawUpdate('''
        UPDATE app_settings 
        SET next_invoice_number = next_invoice_number + 1 
        WHERE id = 1
      ''');

      return invoiceId;
    });
  }

  @override
  Future<int> updateInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return 0;
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Update invoice header
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // 2. Delete old items and insert new ones
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoice.id).toMap();
        await txn.insert('invoice_items', itemMap);
      }

      return invoice.id!;
    });
  }

  @override
  Future<int> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<String> generateNextInvoiceNumber(String prefix) async {
    final db = await _dbHelper.database;
    final settings = await db.query('app_settings', where: 'id = 1');
    int nextNum = 1;
    String activePrefix = prefix;

    if (settings.isNotEmpty) {
      nextNum = (settings.first['next_invoice_number'] as int?) ?? 1;
      activePrefix = (settings.first['invoice_prefix'] as String?) ?? prefix;
    }

    // Format: INV-0001
    final formattedNumber = nextNum.toString().padLeft(4, '0');
    return '$activePrefix$formattedNumber';
  }

  @override
  Future<int> addPayment(InvoicePaymentModel payment) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Insert payment record
      final pId = await txn.insert('invoice_payments', payment.toMap());

      // 2. Recalculate invoice totals
      final invoiceRes =
          await txn.query('invoices', where: 'id = ?', whereArgs: [payment.invoiceId]);
      if (invoiceRes.isNotEmpty) {
        final currentPaid = (invoiceRes.first['paid_amount'] as num?)?.toDouble() ?? 0.0;
        final grandTotal = (invoiceRes.first['grand_total'] as num?)?.toDouble() ?? 0.0;
        final newPaid = currentPaid + payment.amount;
        final newBalance = (grandTotal - newPaid).clamp(0.0, double.infinity);

        String newStatus = 'unpaid';
        if (newPaid >= grandTotal && grandTotal > 0) {
          newStatus = 'paid';
        } else if (newPaid > 0) {
          newStatus = 'partially_paid';
        }

        await txn.update(
          'invoices',
          {
            'paid_amount': newPaid,
            'balance_due': newBalance,
            'status': newStatus,
          },
          where: 'id = ?',
          whereArgs: [payment.invoiceId],
        );
      }

      return pId;
    });
  }

  @override
  Future<List<InvoicePaymentModel>> getPayments(int invoiceId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
    return results.map((m) => InvoicePaymentModel.fromMap(m)).toList();
  }

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(grand_total) as total_invoiced,
        SUM(paid_amount) as total_paid,
        SUM(balance_due) as total_unpaid,
        SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_count,
        SUM(CASE WHEN status IN ('unpaid', 'partially_paid') THEN 1 ELSE 0 END) as unpaid_count,
        SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_count,
        SUM(CASE WHEN status = 'overdue' THEN balance_due ELSE 0 END) as overdue_amount
      FROM invoices
    ''');

    if (results.isNotEmpty) {
      final row = results.first;
      return DashboardMetrics(
        totalInvoiced: (row['total_invoiced'] as num?)?.toDouble() ?? 0.0,
        totalPaid: (row['total_paid'] as num?)?.toDouble() ?? 0.0,
        totalUnpaid: (row['total_unpaid'] as num?)?.toDouble() ?? 0.0,
        totalOverdue: (row['overdue_amount'] as num?)?.toDouble() ?? 0.0,
        totalCount: (row['total_count'] as int?) ?? 0,
        paidCount: (row['paid_count'] as int?) ?? 0,
        unpaidCount: (row['unpaid_count'] as int?) ?? 0,
        overdueCount: (row['overdue_count'] as int?) ?? 0,
      );
    }

    return DashboardMetrics();
  }
}
