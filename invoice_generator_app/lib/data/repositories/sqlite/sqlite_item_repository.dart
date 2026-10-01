import '../../../core/database/database_helper.dart';
import '../../models/item_model.dart';
import '../interfaces/i_item_repository.dart';

class SqliteItemRepository implements IItemRepository {
  final DatabaseHelper _dbHelper;

  SqliteItemRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<ItemModel>> getItems({String? searchQuery, int? businessId}) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (businessId != null) {
      whereClauses.add('(business_id = ? OR business_id IS NULL)');
      whereArgs.add(businessId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClauses.add('(name LIKE ? OR hsn_sac_code LIKE ? OR description LIKE ?)');
      whereArgs.addAll([query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final results = await db.query(
      'items',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return results.map((m) => ItemModel.fromMap(m)).toList();
  }

  @override
  Future<ItemModel?> getItemById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return ItemModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int> insertItem(ItemModel item) async {
    final db = await _dbHelper.database;
    return await db.insert('items', item.toMap());
  }

  @override
  Future<int> updateItem(ItemModel item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
