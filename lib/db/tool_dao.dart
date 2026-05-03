import '../models/tool_transaction.dart';
import 'database_helper.dart';

class ToolDao {
  static final ToolDao instance = ToolDao._();
  ToolDao._();

  Future<List<ToolTransaction>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('tool_transactions', orderBy: 'timestamp DESC');
    return rows.map(ToolTransaction.fromMap).toList();
  }

  Future<int> insert(ToolTransaction t) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('tool_transactions', t.toMap());
  }

  Future<void> markReturned(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tool_transactions',
      {'status': 'Returned', 'timestamp': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tool_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
