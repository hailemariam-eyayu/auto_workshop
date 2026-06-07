import '../models/item.dart';
import 'database_helper.dart';

class ItemDao {
  static final ItemDao instance = ItemDao._();
  ItemDao._();

  Future<List<Item>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('items', orderBy: 'category ASC, name ASC');
    return rows.map(Item.fromMap).toList();
  }

  /// Returns all non-parent items grouped by category.
  /// Map key = category name, value = list of size variants.
  Future<Map<String, List<Item>>> getGrouped() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'items',
      where: 'is_parent = 0',
      orderBy: 'category ASC, name ASC',
    );
    final items = rows.map(Item.fromMap).toList();
    final map = <String, List<Item>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// Insert if not exists (by name), return the id either way.
  Future<int> insertOrGet(String name, {String category = ''}) async {
    final db = await DatabaseHelper.instance.database;
    final trimmedName = name.trim();
    final existing = await db.query('items',
        where: 'LOWER(name) = LOWER(?)', whereArgs: [trimmedName]);
    if (existing.isNotEmpty) {
      final row = existing.first;
      final id = row['id'] as int;
      final currentCategory = (row['category'] as String?) ?? '';
      if (category.isNotEmpty && currentCategory.isEmpty) {
        await db.update(
          'items',
          {'category': category},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      return id;
    }

    return db.insert('items', {
      'name': trimmedName,
      'category': category,
      'is_parent': 0,
    });
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
