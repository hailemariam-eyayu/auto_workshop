// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// // ── Equipment catalog seed data ───────────────────────────────────────────────

// const _sizes = [
//   '4mm',
//   '4.5mm',
//   '5mm',
//   '5.5mm',
//   '6mm',
//   '7mm',
//   '8mm',
//   '9mm',
//   '10mm',
//   '12mm',
//   '13mm',
//   '14mm',
//   '15mm',
//   '16mm',
//   '17mm',
//   '18mm',
//   '19mm',
//   '21mm',
//   '22mm',
//   '24mm',
//   '27mm',
//   '30mm',
//   '32mm',
// ];

// const _alenkiSizes = [
//   '2mm',
//   '2.5mm',
//   '3mm',
//   '4mm',
//   '5mm',
//   '6mm',
//   '7mm',
//   '8mm',
//   '10mm',
//   '12mm',
//   '14mm',
//   '17mm',
//   '19mm',
// ];

// // Groups that have size variants
// final _sizedGroups = {
//   'ስቴላ': _sizes,
//   'ፊሳ': _sizes,
//   'ሜዞ': _sizes,
//   'ጆደር': _sizes,
//   'አለንኪ': _alenkiSizes,
//   'ፒንሳ': ['1', '2', '3'],
// };

// // Single-item groups (no size variants)
// const _singleGroups = [
//   'አሜሪካ ካቻቢቴ',
//   'ፊሳ ካቻቢቴ',
//   'ማኒኮ',
//   'ፊልትሮ መፍቻ',
//   'መስቀለኛ',
//   'ማስረዘሚያ ቱቦ',
//   'ማስረዘሚያ',
//   'ካቤንግሊዝ',
//   'መዶሻ',
//   'ማሳ መዶሻ',
//   'ማግኔት',
//   'ስካርቤሎ',
//   'ካሊፐር',
//   'ስፔሰር',
//   'እስኳድራ',
// ];

// Future<void> _seedEquipment(Database db) async {
//   // Sized groups
//   for (final entry in _sizedGroups.entries) {
//     final category = entry.key;
//     final sizes = entry.value;
//     for (final size in sizes) {
//       final itemName = '$category $size';
//       final existing = await db.query(
//         'items',
//         where: 'LOWER(name) = LOWER(?)',
//         whereArgs: [itemName],
//       );
//       if (existing.isEmpty) {
//         await db.insert('items', {
//           'name': itemName,
//           'category': category,
//           'is_parent': 0,
//         });
//       }
//     }
//   }

//   // Single groups
//   for (final name in _singleGroups) {
//     final existing = await db.query(
//       'items',
//       where: 'LOWER(name) = LOWER(?)',
//       whereArgs: [name],
//     );
//     if (existing.isEmpty) {
//       await db.insert('items', {
//         'name': name,
//         'category': name,
//         'is_parent': 0,
//       });
//     }
//   }
// }

// // ── DatabaseHelper ────────────────────────────────────────────────────────────

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;

//   DatabaseHelper._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('workshop2.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String fileName) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, fileName);
//     return await openDatabase(
//       path,
//       version: 5,
//       onCreate: _createDB,
//       onUpgrade: _onUpgrade,
//       onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
//     );
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     if (oldVersion < 2) {
//       // Add category and is_parent columns to existing items table
//       try {
//         await db.execute(
//           "ALTER TABLE items ADD COLUMN category TEXT NOT NULL DEFAULT ''",
//         );
//       } catch (_) {}
//       try {
//         await db.execute(
//           'ALTER TABLE items ADD COLUMN is_parent INTEGER NOT NULL DEFAULT 0',
//         );
//       } catch (_) {}
//       // Seed the new equipment data
//       await _seedEquipment(db);
//     }
//     if (oldVersion < 3) {
//       try {
//         await db.execute('ALTER TABLE employees ADD COLUMN notes TEXT');
//       } catch (_) {}
//     }
//     if (oldVersion < 4) {
//       // Create notes table
//       try {
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS notes (
//             id         INTEGER PRIMARY KEY AUTOINCREMENT,
//             name       TEXT    NOT NULL DEFAULT '',
//             content    TEXT    NOT NULL,
//             created_at TEXT    NOT NULL,
//             updated_at TEXT    NOT NULL
//           )
//         ''');
//       } catch (_) {}
//     }
//     if (oldVersion < 5) {
//       // Add notes column to borrows table
//       try {
//         await db.execute('ALTER TABLE borrows ADD COLUMN notes TEXT');
//       } catch (_) {}
//     }
//   }

//   Future<void> _createDB(Database db, int version) async {
//     // Employees
//     await db.execute('''
//       CREATE TABLE employees (
//         id         INTEGER PRIMARY KEY AUTOINCREMENT,
//         name       TEXT    NOT NULL,
//         phone      TEXT,
//         entry_date TEXT    NOT NULL,
//         notes      TEXT
//       )
//     ''');

//     // Item catalog with category grouping
//     await db.execute('''
//       CREATE TABLE items (
//         id        INTEGER PRIMARY KEY AUTOINCREMENT,
//         name      TEXT    NOT NULL UNIQUE,
//         category  TEXT    NOT NULL DEFAULT '',
//         is_parent INTEGER NOT NULL DEFAULT 0
//       )
//     ''');

//     // Active borrows: one row per (employee, item) pair
//     await db.execute('''
//       CREATE TABLE borrows (
//         id          INTEGER PRIMARY KEY AUTOINCREMENT,
//         employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
//         item_id     INTEGER NOT NULL REFERENCES items(id)     ON DELETE CASCADE,
//         quantity    INTEGER NOT NULL DEFAULT 1,
//         borrowed_at TEXT    NOT NULL,
//         notes       TEXT,
//         UNIQUE(employee_id, item_id)
//       )
//     ''');

//     // Full history log
//     await db.execute('''
//       CREATE TABLE borrow_history (
//         id          INTEGER PRIMARY KEY AUTOINCREMENT,
//         employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
//         item_id     INTEGER NOT NULL REFERENCES items(id)     ON DELETE CASCADE,
//         quantity    INTEGER NOT NULL,
//         action      TEXT    NOT NULL CHECK(action IN ('borrowed','returned')),
//         timestamp   TEXT    NOT NULL
//       )
//     ''');

//     // After creating the table, run an ALTER if the column is missing.
//     // Simpler: add the column unconditionally (SQLite ignores if already exists).
//     await db.execute('ALTER TABLE borrow_history ADD COLUMN notes TEXT');
//     // Vehicles / Services (Service & Billing module)
//     await db.execute('''
//       CREATE TABLE vehicles (
//         id         INTEGER PRIMARY KEY AUTOINCREMENT,
//         plate      TEXT    NOT NULL,
//         entry_date TEXT    NOT NULL,
//         status     TEXT    NOT NULL DEFAULT 'Not Started',
//         total_bill REAL    NOT NULL DEFAULT 0,
//         notes      TEXT
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE services (
//         id         INTEGER PRIMARY KEY AUTOINCREMENT,
//         vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
//         name       TEXT    NOT NULL,
//         unit_price REAL    NOT NULL DEFAULT 0,
//         quantity   INTEGER NOT NULL DEFAULT 1,
//         discount   REAL    NOT NULL DEFAULT 0,
//         notes      TEXT,
//         created_at TEXT    NOT NULL
//       )
//     ''');

//     // Materials/Inventory with quantity tracking
//     await db.execute('''
//       CREATE TABLE materials (
//         id          INTEGER PRIMARY KEY AUTOINCREMENT,
//         name        TEXT    NOT NULL UNIQUE,
//         category    TEXT    NOT NULL DEFAULT '',
//         unit        TEXT    NOT NULL DEFAULT 'piece',
//         quantity    REAL    NOT NULL DEFAULT 0,
//         description TEXT,
//         created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
//       )
//     ''');

//     // Seed equipment on fresh install
//     await _seedEquipment(db);

//     // Notes
//     await db.execute('''
//       CREATE TABLE notes (
//         id         INTEGER PRIMARY KEY AUTOINCREMENT,
//         name       TEXT    NOT NULL DEFAULT '',
//         content    TEXT    NOT NULL,
//         created_at TEXT    NOT NULL,
//         updated_at TEXT    NOT NULL
//       )
//     ''');
//   }
// }
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ── Equipment catalog seed data ───────────────────────────────────────────────

const _sizes = [
  '4mm',
  '4.5mm',
  '5mm',
  '5.5mm',
  '6mm',
  '7mm',
  '8mm',
  '9mm',
  '10mm',
  '12mm',
  '13mm',
  '14mm',
  '15mm',
  '16mm',
  '17mm',
  '18mm',
  '19mm',
  '21mm',
  '22mm',
  '24mm',
  '27mm',
  '30mm',
  '32mm',
];

const _alenkiSizes = [
  '2mm',
  '2.5mm',
  '3mm',
  '4mm',
  '5mm',
  '6mm',
  '7mm',
  '8mm',
  '10mm',
  '12mm',
  '14mm',
  '17mm',
  '19mm',
];

// Groups that have size variants
final _sizedGroups = {
  'ስቴላ': _sizes,
  'ፊሳ': _sizes,
  'ሜዞ': _sizes,
  'ጆደር': _sizes,
  'አለንኪ': _alenkiSizes,
  'ፒንሳ': ['1', '2', '3'],
};

// Single-item groups (no size variants)
const _singleGroups = [
  'አሜሪካ ካቻቢቴ',
  'ፊሳ ካቻቢቴ',
  'ማኒኮ',
  'ፊልትሮ መፍቻ',
  'መስቀለኛ',
  'ማስረዘሚያ ቱቦ',
  'ማስረዘሚያ',
  'ካቤንግሊዝ',
  'መዶሻ',
  'ማሳ መዶሻ',
  'ማግኔት',
  'ስካርቤሎ',
  'ካሊፐር',
  'ስፔሰር',
  'እስኳድራ',
];

Future<void> _seedEquipment(Database db) async {
  // Sized groups
  for (final entry in _sizedGroups.entries) {
    final category = entry.key;
    final sizes = entry.value;
    for (final size in sizes) {
      final itemName = '$category $size';
      final existing = await db.query(
        'items',
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [itemName],
      );
      if (existing.isEmpty) {
        await db.insert('items', {
          'name': itemName,
          'category': category,
          'is_parent': 0,
        });
      }
    }
  }

  // Single groups
  for (final name in _singleGroups) {
    final existing = await db.query(
      'items',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
    );
    if (existing.isEmpty) {
      await db.insert('items', {
        'name': name,
        'category': name,
        'is_parent': 0,
      });
    }
  }
}

// ── DatabaseHelper ────────────────────────────────────────────────────────────

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workshop2.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE items ADD COLUMN category TEXT NOT NULL DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE items ADD COLUMN is_parent INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      await _seedEquipment(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE employees ADD COLUMN notes TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notes (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT    NOT NULL DEFAULT '',
            content    TEXT    NOT NULL,
            created_at TEXT    NOT NULL,
            updated_at TEXT    NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      // Add notes column to borrows table
      try {
        await db.execute('ALTER TABLE borrows ADD COLUMN notes TEXT');
      } catch (_) {}
      // 👇 CRITICAL: add notes column to borrow_history table
      try {
        await db.execute('ALTER TABLE borrow_history ADD COLUMN notes TEXT');
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Employees
    await db.execute('''
      CREATE TABLE employees (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        phone      TEXT,
        entry_date TEXT    NOT NULL,
        notes      TEXT
      )
    ''');

    // Item catalog with category grouping
    await db.execute('''
      CREATE TABLE items (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL UNIQUE,
        category  TEXT    NOT NULL DEFAULT '',
        is_parent INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Active borrows: one row per (employee, item) pair
    await db.execute('''
      CREATE TABLE borrows (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        item_id     INTEGER NOT NULL REFERENCES items(id)     ON DELETE CASCADE,
        quantity    INTEGER NOT NULL DEFAULT 1,
        borrowed_at TEXT    NOT NULL,
        notes       TEXT,
        UNIQUE(employee_id, item_id)
      )
    ''');

    // Full history log – now includes notes column
    await db.execute('''
      CREATE TABLE borrow_history (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        item_id     INTEGER NOT NULL REFERENCES items(id)     ON DELETE CASCADE,
        quantity    INTEGER NOT NULL,
        action      TEXT    NOT NULL CHECK(action IN ('borrowed','returned')),
        timestamp   TEXT    NOT NULL,
        notes       TEXT
      )
    ''');

    // Vehicles / Services (Service & Billing module)
    await db.execute('''
      CREATE TABLE vehicles (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        plate      TEXT    NOT NULL,
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
        unit_price REAL    NOT NULL DEFAULT 0,
        quantity   INTEGER NOT NULL DEFAULT 1,
        discount   REAL    NOT NULL DEFAULT 0,
        notes      TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    // Materials/Inventory with quantity tracking
    await db.execute('''
      CREATE TABLE materials (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL UNIQUE,
        category    TEXT    NOT NULL DEFAULT '',
        unit        TEXT    NOT NULL DEFAULT 'piece',
        quantity    REAL    NOT NULL DEFAULT 0,
        description TEXT,
        created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Seed equipment on fresh install
    await _seedEquipment(db);

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL DEFAULT '',
        content    TEXT    NOT NULL,
        created_at TEXT    NOT NULL,
        updated_at TEXT    NOT NULL
      )
    ''');
  }
}