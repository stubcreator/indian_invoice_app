import '../../../core/database/database_helper.dart';
import '../../models/client_model.dart';
import '../interfaces/i_client_repository.dart';

class SqliteClientRepository implements IClientRepository {
  final DatabaseHelper _dbHelper;

  SqliteClientRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<ClientModel>> getClients({String? searchQuery, int? businessId}) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (businessId != null) {
      whereClauses.add('(business_id = ? OR business_id IS NULL)');
      whereArgs.add(businessId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('(name LIKE ? OR company_name LIKE ? OR phone LIKE ? OR gstin LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final results = await db.query(
      'clients',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return results.map((m) => ClientModel.fromMap(m)).toList();
  }

  @override
  Future<ClientModel?> getClientById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return ClientModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int> insertClient(ClientModel client) async {
    final db = await _dbHelper.database;
    return await db.insert('clients', client.toMap());
  }

  @override
  Future<int> updateClient(ClientModel client) async {
    final db = await _dbHelper.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  @override
  Future<int> deleteClient(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }
}
