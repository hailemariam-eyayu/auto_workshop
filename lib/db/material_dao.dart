import '../models/material.dart';
import 'database_helper.dart';

class MaterialDao {
  static final MaterialDao instance = MaterialDao._();
  MaterialDao._();

  Future<List<WorkshopMaterial>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('materials', orderBy: 'category ASC, name ASC');
    return rows.map(WorkshopMaterial.fromMap).toList();
  }

  Future<List<WorkshopMaterial>> getByCategory(String category) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'materials',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return rows.map(WorkshopMaterial.fromMap).toList();
  }

  Future<WorkshopMaterial?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return WorkshopMaterial.fromMap(rows.first);
  }

  Future<int> insert(WorkshopMaterial material) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('materials', material.toMap());
  }

  Future<void> update(WorkshopMaterial material) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<void> updateQuantity(int id, double quantity) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'materials',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementQuantity(int id, double amount) async {
    final material = await getById(id);
    if (material != null) {
      await updateQuantity(id, material.quantity + amount);
    }
  }

  Future<void> decrementQuantity(int id, double amount) async {
    final material = await getById(id);
    if (material != null) {
      final newQuantity = (material.quantity - amount).clamp(0.0, double.infinity);
      await updateQuantity(id, newQuantity.toDouble());
    }
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, List<WorkshopMaterial>>> getGroupedByCategory() async {
    final materials = await getAll();
    final map = <String, List<WorkshopMaterial>>{};
    for (final material in materials) {
      map.putIfAbsent(material.category, () => []).add(material);
    }
    return map;
  }
}
