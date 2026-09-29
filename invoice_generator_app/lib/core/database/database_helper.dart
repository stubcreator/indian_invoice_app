import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'indian_invoice_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Business Profile Table
    await db.execute('''
      CREATE TABLE businesses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_name TEXT NOT NULL,
        trade_name TEXT,
        owner_name TEXT,
        gstin TEXT,
        pan TEXT,
        email TEXT,
        phone TEXT,
        address_line1 TEXT,
        address_line2 TEXT,
        city TEXT,
        state TEXT,
        state_code TEXT,
        pincode TEXT,
        country TEXT DEFAULT 'India',
        logo_path TEXT,
        signature_path TEXT,
        bank_name TEXT,
        account_number TEXT,
        ifsc_code TEXT,
        account_holder_name TEXT,
        upi_id TEXT
      )
    ''');

    // 2. Clients Table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company_name TEXT,
        gstin TEXT,
        email TEXT,
        phone TEXT,
        billing_address TEXT,
        shipping_address TEXT,
        state TEXT,
        state_code TEXT,
        country TEXT DEFAULT 'India',
        notes TEXT
      )
    ''');

    // 3. Products/Services Catalog Table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        hsn_sac_code TEXT,
        unit_price REAL NOT NULL DEFAULT 0,
        unit TEXT DEFAULT 'PCS',
        gst_rate REAL DEFAULT 18.0,
        cess_rate REAL DEFAULT 0.0,
        stock_quantity REAL DEFAULT 0.0,
        is_service INTEGER DEFAULT 0
      )
    ''');

    // 4. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        invoice_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        po_number TEXT,
        po_date TEXT,
        client_id INTEGER,
        client_name TEXT NOT NULL,
        client_company_name TEXT,
        client_gstin TEXT,
        business_id INTEGER,
        place_of_supply TEXT,
        place_of_supply_code TEXT,
        is_reverse_charge INTEGER DEFAULT 0,
        currency_code TEXT DEFAULT 'INR',
        currency_symbol TEXT DEFAULT '₹',
        tax_mode TEXT DEFAULT 'gst',
        subtotal REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        discount_rate REAL DEFAULT 0,
        discount_type TEXT DEFAULT 'flat',
        total_cgst REAL DEFAULT 0,
        total_sgst REAL DEFAULT 0,
        total_igst REAL DEFAULT 0,
        total_cess REAL DEFAULT 0,
        shipping_charge REAL DEFAULT 0,
        round_off REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        balance_due REAL DEFAULT 0,
        status TEXT DEFAULT 'unpaid',
        notes TEXT,
        terms_conditions TEXT,
        signature_path TEXT,
        template_id INTEGER DEFAULT 1,
        created_at TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL,
        FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE SET NULL
      )
    ''');

    // 5. Invoice Line Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_id INTEGER,
        item_name TEXT NOT NULL,
        description TEXT,
        hsn_sac_code TEXT,
        quantity REAL NOT NULL DEFAULT 1,
        unit TEXT DEFAULT 'PCS',
        unit_price REAL NOT NULL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        taxable_amount REAL NOT NULL DEFAULT 0,
        gst_rate REAL DEFAULT 0,
        cgst_amount REAL DEFAULT 0,
        sgst_amount REAL DEFAULT 0,
        igst_amount REAL DEFAULT 0,
        cess_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 6. Invoice Payments Table
    await db.execute('''
      CREATE TABLE invoice_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_mode TEXT DEFAULT 'UPI',
        reference_no TEXT,
        notes TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 7. App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY,
        country_code TEXT,
        country_name TEXT,
        currency_code TEXT,
        currency_symbol TEXT,
        tax_mode TEXT,
        invoice_prefix TEXT,
        next_invoice_number INTEGER,
        default_terms TEXT,
        default_notes TEXT,
        signature_path TEXT,
        active_business_id INTEGER,
        default_template_id INTEGER
      )
    ''');

    // Seed default settings row
    await db.rawInsert('''
      INSERT INTO app_settings (
        id, country_code, country_name, currency_code, currency_symbol, tax_mode,
        invoice_prefix, next_invoice_number, default_terms, default_notes, default_template_id
      ) VALUES (
        1, 'IN', 'India', 'INR', '₹', 'gst', 'INV-', 1,
        '1. Goods once sold will not be taken back.\n2. Interest @18% p.a. will be charged if payment is not made within the due date.\n3. Subject to jurisdiction.',
        'Thank you for your business!', 1
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
