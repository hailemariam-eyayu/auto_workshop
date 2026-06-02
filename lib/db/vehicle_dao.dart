import '../models/vehicle.dart';
import 'database_helper.dart';

class VehicleDao {
  static final VehicleDao instance = VehicleDao._();
  VehicleDao._();

  Future<List<Vehicle>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('vehicles', orderBy: 'entry_date DESC');
    return rows.map((r) => Vehicle.fromMap(r)).toList();
  }

  Future<Vehicle?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows =
        await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final services = await _getServices(id);
    return Vehicle.fromMap(rows.first, services: services);
  }

  Future<List<Service>> _getServices(int vehicleId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'services',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Service.fromMap).toList();
  }

  Future<int> insert(Vehicle v) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('vehicles', v.toMap());
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('vehicles', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateVehicle(Vehicle v) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('vehicles', v.toMap(),
        where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteAllServices(int vehicleId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('services',
        where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    await _recalcBill(vehicleId);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addService(Service s) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('services', s.toMap());
    await _recalcBill(s.vehicleId);
    return id;
  }

  Future<void> updateService(Service s) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('services', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
    await _recalcBill(s.vehicleId);
  }

  Future<void> deleteService(int serviceId, int vehicleId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('services', where: 'id = ?', whereArgs: [serviceId]);
    await _recalcBill(vehicleId);
  }

  Future<void> _recalcBill(int vehicleId) async {
    final db = await DatabaseHelper.instance.database;
    // total = SUM((unit_price * quantity) - discount)
    await db.rawUpdate(
      '''UPDATE vehicles
         SET total_bill = (
           SELECT COALESCE(SUM((unit_price * quantity) - discount), 0)
           FROM services WHERE vehicle_id = ?
         )
         WHERE id = ?''',
      [vehicleId, vehicleId],
    );
  }
}
