import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workshop.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tool_transactions (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        employee  TEXT    NOT NULL,
        tool_name TEXT    NOT NULL,
        quantity  INTEGER NOT NULL DEFAULT 1,
        status    TEXT    NOT NULL CHECK(status IN ('Borrowed','Returned')),
        timestamp TEXT    NOT NULL,
        notes     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        plate      TEXT    NOT NULL,
        model      TEXT    NOT NULL,
        entry_date TEXT    NOT NULL,
        status     TEXT    NOT NULL DEFAULT 'Not Started',
        total_bill REAL    NOT NULL DEFAULT 0,
        notes      TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        name       TEXT    NOT NULL,
        price      REAL    NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL
      )
    ''');
  }
}
