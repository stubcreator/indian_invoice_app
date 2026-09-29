import '../../../core/database/database_helper.dart';
import '../../models/client_model.dart';
import '../interfaces/i_client_repository.dart';

class SqliteClientRepository implements IClientRepository {
  final DatabaseHelper _dbHelper;

  SqliteClientRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<ClientModel>> getClients({String? searchQuery}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> results;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      results = await db.query(
        'clients',
        where: 'name LIKE ? OR company_name LIKE ? OR phone LIKE ? OR gstin LIKE ?',
        whereArgs: [query, query, query, query],
        orderBy: 'name ASC',
      );
    } else {
      results = await db.query('clients', orderBy: 'name ASC');
    }

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
