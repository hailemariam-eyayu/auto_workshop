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
  Future<int> insertOrGet(String name) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('items',
        where: 'LOWER(name) = LOWER(?)', whereArgs: [name.trim()]);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return db.insert('items', {
      'name': name.trim(),
      'category': '',
      'is_parent': 0,
    });
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
