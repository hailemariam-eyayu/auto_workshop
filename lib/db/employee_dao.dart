import '../models/employee.dart';
import 'database_helper.dart';

class EmployeeDao {
  static final EmployeeDao instance = EmployeeDao._();
  EmployeeDao._();

  Future<List<Employee>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('employees', orderBy: 'name ASC');
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<int> insert(Employee e) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('employees', e.toMap());
  }

  Future<void> update(Employee e) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('employees', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }
}
