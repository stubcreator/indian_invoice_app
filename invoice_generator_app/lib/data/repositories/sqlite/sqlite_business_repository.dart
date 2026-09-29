import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../models/business_model.dart';
import '../interfaces/i_business_repository.dart';

class SqliteBusinessRepository implements IBusinessRepository {
  final DatabaseHelper _dbHelper;

  SqliteBusinessRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<BusinessModel?> getBusinessProfile() async {
    final db = await _dbHelper.database;
    final results = await db.query('businesses', limit: 1);
    if (results.isNotEmpty) {
      return BusinessModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int> saveBusinessProfile(BusinessModel business) async {
    final db = await _dbHelper.database;
    // Check if one exists
    final existing = await db.query('businesses', limit: 1);
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'businesses',
        business.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    } else {
      return await db.insert('businesses', business.toMap());
    }
  }

  @override
  Future<int> updateBusinessProfile(BusinessModel business) async {
    return await saveBusinessProfile(business);
  }
}
