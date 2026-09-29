import '../../../core/database/database_helper.dart';
import '../../models/item_model.dart';
import '../interfaces/i_item_repository.dart';

class SqliteItemRepository implements IItemRepository {
  final DatabaseHelper _dbHelper;

  SqliteItemRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<ItemModel>> getItems({String? searchQuery}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> results;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      results = await db.query(
        'items',
        where: 'name LIKE ? OR hsn_sac_code LIKE ? OR description LIKE ?',
        whereArgs: [query, query, query],
        orderBy: 'name ASC',
      );
    } else {
      results = await db.query('items', orderBy: 'name ASC');
    }

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
