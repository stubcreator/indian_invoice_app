import '../../../core/database/database_helper.dart';
import '../../models/business_model.dart';
import '../interfaces/i_business_repository.dart';

class SqliteBusinessRepository implements IBusinessRepository {
  final DatabaseHelper _dbHelper;

  SqliteBusinessRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<BusinessModel>> getAllBusinesses() async {
    final db = await _dbHelper.database;
    final results = await db.query('businesses', orderBy: 'id ASC');
    return results.map((m) => BusinessModel.fromMap(m)).toList();
  }

  @override
  Future<BusinessModel?> getBusinessById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('businesses', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return BusinessModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int?> getActiveBusinessId() async {
    final db = await _dbHelper.database;
    try {
      final results = await db.query('app_settings', columns: ['active_business_id'], where: 'id = 1');
      if (results.isNotEmpty) {
        return results.first['active_business_id'] as int?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> setActiveBusinessId(int businessId) async {
    final db = await _dbHelper.database;
    try {
      await db.update(
        'app_settings',
        {'active_business_id': businessId},
        where: 'id = 1',
      );
    } catch (_) {}
  }

  @override
  Future<BusinessModel?> getActiveBusiness() async {
    final activeId = await getActiveBusinessId();
    if (activeId != null) {
      final active = await getBusinessById(activeId);
      if (active != null) return active;
    }

    // Fallback to first business if active not found
    final all = await getAllBusinesses();
    if (all.isNotEmpty) {
      final first = all.first;
      if (first.id != null) {
        await setActiveBusinessId(first.id!);
      }
      return first;
    }

    return null;
  }

  @override
  Future<int> createBusiness(BusinessModel business) async {
    final db = await _dbHelper.database;
    final id = await db.insert('businesses', business.toMap());

    // If no active business, make this the active one
    final activeId = await getActiveBusinessId();
    if (activeId == null) {
      await setActiveBusinessId(id);
    }

    return id;
  }

  @override
  Future<int> saveBusinessProfile(BusinessModel business) async {
    if (business.id != null) {
      return await updateBusinessProfile(business);
    }
    return await createBusiness(business);
  }

  @override
  Future<int> updateBusinessProfile(BusinessModel business) async {
    final db = await _dbHelper.database;
    if (business.id != null) {
      await db.update(
        'businesses',
        business.toMap(),
        where: 'id = ?',
        whereArgs: [business.id],
      );
      return business.id!;
    } else {
      return await createBusiness(business);
    }
  }

  @override
  Future<int> deleteBusiness(int id) async {
    final db = await _dbHelper.database;
    final deleted = await db.delete('businesses', where: 'id = ?', whereArgs: [id]);

    final activeId = await getActiveBusinessId();
    if (activeId == id) {
      final remaining = await getAllBusinesses();
      if (remaining.isNotEmpty) {
        await setActiveBusinessId(remaining.first.id!);
      } else {
        try {
          await db.update('app_settings', {'active_business_id': null}, where: 'id = 1');
        } catch (_) {}
      }
    }

    return deleted;
  }
}
