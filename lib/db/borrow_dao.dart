import '../models/borrow.dart';
import '../models/borrow_history.dart';
import 'database_helper.dart';

class BorrowDao {
  static final BorrowDao instance = BorrowDao._();
  BorrowDao._();

  // ── Active borrows ────────────────────────────────────────────────────────

  Future<List<Borrow>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT b.*, i.name AS item_name, e.name AS employee_name
      FROM borrows b
      JOIN items i ON i.id = b.item_id
      JOIN employees e ON e.id = b.employee_id
      ORDER BY e.name ASC, i.name ASC
    ''');
    return rows.map(Borrow.fromMap).toList();
  }

  Future<List<Borrow>> getByEmployee(int employeeId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT b.*, i.name AS item_name, e.name AS employee_name
      FROM borrows b
      JOIN items i ON i.id = b.item_id
      JOIN employees e ON e.id = b.employee_id
      WHERE b.employee_id = ?
      ORDER BY i.name ASC
    ''', [employeeId]);
    return rows.map(Borrow.fromMap).toList();
  }

  /// Upsert: if (employee, item) row exists → update quantity, else insert.
  /// Also logs to history.
  Future<void> upsertBorrow({
    required int employeeId,
    required int itemId,
    required int quantity,
    String? notes,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'borrows',
      where: 'employee_id = ? AND item_id = ?',
      whereArgs: [employeeId, itemId],
    );

    if (existing.isEmpty) {
      await db.insert('borrows', {
        'employee_id': employeeId,
        'item_id': itemId,
        'quantity': quantity,
        'borrowed_at': now,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } else {
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'borrows',
        {
          'quantity': currentQty + quantity,
          'borrowed_at': now,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        where: 'employee_id = ? AND item_id = ?',
        whereArgs: [employeeId, itemId],
      );
    }

    // Log history (with notes)
    await db.insert('borrow_history', {
      'employee_id': employeeId,
      'item_id': itemId,
      'quantity': quantity,
      'action': 'borrowed',
      'timestamp': now,
      'notes': notes,
    });
  }

  /// Return some or all of a borrow.
  /// If returnQty >= current quantity, the borrow row is deleted.
  Future<void> returnBorrow({
    required int borrowId,
    required int employeeId,
    required int itemId,
    required int returnQty,
    required int currentQty,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    // Fetch the current borrow row to get its notes
    final borrowRow = await db.query(
      'borrows',
      where: 'id = ?',
      whereArgs: [borrowId],
    );
    final notes = borrowRow.isNotEmpty ? borrowRow.first['notes'] as String? : null;

    if (returnQty >= currentQty) {
      await db.delete('borrows', where: 'id = ?', whereArgs: [borrowId]);
    } else {
      await db.update(
        'borrows',
        {'quantity': currentQty - returnQty},
        where: 'id = ?',
        whereArgs: [borrowId],
      );
    }

    // Log history with the notes from the borrow
    await db.insert('borrow_history', {
      'employee_id': employeeId,
      'item_id': itemId,
      'quantity': returnQty,
      'action': 'returned',
      'timestamp': now,
      'notes': notes,
    });
  }

  Future<void> returnAllForEmployee(int employeeId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'borrows',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
    );

    if (rows.isEmpty) return;

    final batch = db.batch();
    for (final row in rows) {
      final itemId = row['item_id'] as int;
      final quantity = row['quantity'] as int;
      final notes = row['notes'] as String?;
      batch.insert('borrow_history', {
        'employee_id': employeeId,
        'item_id': itemId,
        'quantity': quantity,
        'action': 'returned',
        'timestamp': now,
        'notes': notes,
      });
    }
    batch.delete('borrows', where: 'employee_id = ?', whereArgs: [employeeId]);
    await batch.commit(noResult: true);
  }

  /// Update the quantity of an existing borrow directly (for edit mode).
  Future<void> updateQuantity(int borrowId, int newQty) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'borrows',
      {'quantity': newQty},
      where: 'id = ?',
      whereArgs: [borrowId],
    );
  }

  Future<void> deleteBorrow(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('borrows', where: 'id = ?', whereArgs: [id]);
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<BorrowHistory>> getHistory({int? employeeId}) async {
    final db = await DatabaseHelper.instance.database;
    final where = employeeId != null ? 'WHERE h.employee_id = ?' : '';
    final args = employeeId != null ? [employeeId] : [];
    final rows = await db.rawQuery('''
      SELECT h.*, i.name AS item_name, e.name AS employee_name
      FROM borrow_history h
      JOIN items i ON i.id = h.item_id
      JOIN employees e ON e.id = h.employee_id
      $where
      ORDER BY h.timestamp DESC
    ''', args);
    return rows.map(BorrowHistory.fromMap).toList();
  }

  // ── Analysis helpers ──────────────────────────────────────────────────────

  /// Returns total borrowed and total returned per employee per item.
  Future<List<Map<String, dynamic>>> getAnalysis() async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT
        e.id   AS employee_id,
        e.name AS employee_name,
        i.id   AS item_id,
        i.name AS item_name,
        SUM(CASE WHEN h.action = 'borrowed' THEN h.quantity ELSE 0 END) AS total_borrowed,
        SUM(CASE WHEN h.action = 'returned' THEN h.quantity ELSE 0 END) AS total_returned
      FROM borrow_history h
      JOIN employees e ON e.id = h.employee_id
      JOIN items     i ON i.id = h.item_id
      GROUP BY e.id, i.id
      ORDER BY e.name ASC, i.name ASC
    ''');
  }
}
// import '../models/borrow.dart';
// import '../models/borrow_history.dart';
// import 'database_helper.dart';

// class BorrowDao {
//   static final BorrowDao instance = BorrowDao._();
//   BorrowDao._();

//   // ── Active borrows ────────────────────────────────────────────────────────

//   Future<List<Borrow>> getAll() async {
//     final db = await DatabaseHelper.instance.database;
//     final rows = await db.rawQuery('''
//       SELECT b.*, i.name AS item_name, e.name AS employee_name
//       FROM borrows b
//       JOIN items i ON i.id = b.item_id
//       JOIN employees e ON e.id = b.employee_id
//       ORDER BY e.name ASC, i.name ASC
//     ''');
//     return rows.map(Borrow.fromMap).toList();
//   }

//   Future<List<Borrow>> getByEmployee(int employeeId) async {
//     final db = await DatabaseHelper.instance.database;
//     final rows = await db.rawQuery(
//       '''
//       SELECT b.*, i.name AS item_name, e.name AS employee_name
//       FROM borrows b
//       JOIN items i ON i.id = b.item_id
//       JOIN employees e ON e.id = b.employee_id
//       WHERE b.employee_id = ?
//       ORDER BY i.name ASC
//     ''',
//       [employeeId],
//     );
//     return rows.map(Borrow.fromMap).toList();
//   }

//   /// Upsert: if (employee, item) row exists → update quantity, else insert.
//   /// Also logs to history.
//   Future<void> upsertBorrow({
//     required int employeeId,
//     required int itemId,
//     required int quantity,
//     String? notes,
//   }) async {
//     final db = await DatabaseHelper.instance.database;
//     final now = DateTime.now().toIso8601String();

//     final existing = await db.query(
//       'borrows',
//       where: 'employee_id = ? AND item_id = ?',
//       whereArgs: [employeeId, itemId],
//     );

//     if (existing.isEmpty) {
//       await db.insert('borrows', {
//         'employee_id': employeeId,
//         'item_id': itemId,
//         'quantity': quantity,
//         'borrowed_at': now,
//         if (notes != null && notes.isNotEmpty) 'notes': notes,
//       });
//     } else {
//       final currentQty = existing.first['quantity'] as int;
//       await db.update(
//         'borrows',
//         {
//           'quantity': currentQty + quantity,
//           'borrowed_at': now,
//           if (notes != null && notes.isNotEmpty) 'notes': notes,
//         },
//         where: 'employee_id = ? AND item_id = ?',
//         whereArgs: [employeeId, itemId],
//       );
//     }

//     // Log history
//     await db.insert('borrow_history', {
//       'employee_id': employeeId,
//       'item_id': itemId,
//       'quantity': quantity,
//       'action': 'borrowed',
//       'timestamp': now,
//       'notes': notes, // 👈 store the note here too
//     });
//   }

//   /// Return some or all of a borrow.
//   /// If returnQty >= current quantity, the borrow row is deleted.
//   // Future<void> returnBorrow({
//   //   required int borrowId,
//   //   required int employeeId,
//   //   required int itemId,
//   //   required int returnQty,
//   //   required int currentQty,
//   // }) async {
//   //   final db = await DatabaseHelper.instance.database;
//   //   final now = DateTime.now().toIso8601String();

//   //   if (returnQty >= currentQty) {
//   //     await db.delete('borrows', where: 'id = ?', whereArgs: [borrowId]);
//   //   } else {
//   //     await db.update(
//   //       'borrows',
//   //       {'quantity': currentQty - returnQty},
//   //       where: 'id = ?',
//   //       whereArgs: [borrowId],
//   //     );
//   //   }

//   //   // Log history
//   //   await db.insert('borrow_history', {
//   //     'employee_id': employeeId,
//   //     'item_id': itemId,
//   //     'quantity': returnQty,
//   //     'action': 'returned',
//   //     'timestamp': now,
//   //   });
//   // }
//   Future<void> returnBorrow({
//     required int borrowId,
//     required int employeeId,
//     required int itemId,
//     required int returnQty,
//     required int currentQty,
//   }) async {
//     final db = await DatabaseHelper.instance.database;
//     final now = DateTime.now().toIso8601String();

//     // 1. Fetch the current borrow row to get its notes (if any)
//     final borrowRow = await db.query(
//       'borrows',
//       where: 'id = ?',
//       whereArgs: [borrowId],
//     );
//     final notes = borrowRow.isNotEmpty
//         ? borrowRow.first['notes'] as String?
//         : null;

//     // 2. Update or delete the borrow
//     if (returnQty >= currentQty) {
//       await db.delete('borrows', where: 'id = ?', whereArgs: [borrowId]);
//     } else {
//       await db.update(
//         'borrows',
//         {'quantity': currentQty - returnQty},
//         where: 'id = ?',
//         whereArgs: [borrowId],
//       );
//     }

//     // 3. Log history with the notes
//     await db.insert('borrow_history', {
//       'employee_id': employeeId,
//       'item_id': itemId,
//       'quantity': returnQty,
//       'action': 'returned',
//       'timestamp': now,
//       'notes': notes, // 👈 include the note from the borrow
//     });
//   }

//   Future<void> returnAllForEmployee(int employeeId) async {
//     final db = await DatabaseHelper.instance.database;
//     final now = DateTime.now().toIso8601String();
//     final rows = await db.query(
//       'borrows',
//       where: 'employee_id = ?',
//       whereArgs: [employeeId],
//     );

//     if (rows.isEmpty) return;

//     // final batch = db.batch();
//     // for (final row in rows) {
//     //   final itemId = row['item_id'] as int;
//     //   final quantity = row['quantity'] as int;
//     //   batch.insert('borrow_history', {
//     //     'employee_id': employeeId,
//     //     'item_id': itemId,
//     //     'quantity': quantity,
//     //     'action': 'returned',
//     //     'timestamp': now,
//     //   });
//     // }
//     final batch = db.batch();
//     for (final row in rows) {
//       final itemId = row['item_id'] as int;
//       final quantity = row['quantity'] as int;
//       final notes = row['notes'] as String?; // 👈 get the note
//       batch.insert('borrow_history', {
//         'employee_id': employeeId,
//         'item_id': itemId,
//         'quantity': quantity,
//         'action': 'returned',
//         'timestamp': now,
//         'notes': notes, // 👈 store it
//       });
//     }
//     batch.delete('borrows', where: 'employee_id = ?', whereArgs: [employeeId]);
//     await batch.commit(noResult: true);
//   }

//   /// Update the quantity of an existing borrow directly (for edit mode).
//   Future<void> updateQuantity(int borrowId, int newQty) async {
//     final db = await DatabaseHelper.instance.database;
//     await db.update(
//       'borrows',
//       {'quantity': newQty},
//       where: 'id = ?',
//       whereArgs: [borrowId],
//     );
//   }

//   Future<void> deleteBorrow(int id) async {
//     final db = await DatabaseHelper.instance.database;
//     await db.delete('borrows', where: 'id = ?', whereArgs: [id]);
//   }

//   // ── History ───────────────────────────────────────────────────────────────

//   Future<List<BorrowHistory>> getHistory({int? employeeId}) async {
//     final db = await DatabaseHelper.instance.database;
//     final where = employeeId != null ? 'WHERE h.employee_id = ?' : '';
//     final args = employeeId != null ? [employeeId] : [];
//     final rows = await db.rawQuery('''
//       SELECT h.*, i.name AS item_name, e.name AS employee_name
//       FROM borrow_history h
//       JOIN items i ON i.id = h.item_id
//       JOIN employees e ON e.id = h.employee_id
//       $where
//       ORDER BY h.timestamp DESC
//     ''', args);
//     return rows.map(BorrowHistory.fromMap).toList();
//   }

//   // ── Analysis helpers ──────────────────────────────────────────────────────

//   /// Returns total borrowed and total returned per employee per item.
//   Future<List<Map<String, dynamic>>> getAnalysis() async {
//     final db = await DatabaseHelper.instance.database;
//     return db.rawQuery('''
//       SELECT
//         e.id   AS employee_id,
//         e.name AS employee_name,
//         i.id   AS item_id,
//         i.name AS item_name,
//         SUM(CASE WHEN h.action = 'borrowed' THEN h.quantity ELSE 0 END) AS total_borrowed,
//         SUM(CASE WHEN h.action = 'returned' THEN h.quantity ELSE 0 END) AS total_returned
//       FROM borrow_history h
//       JOIN employees e ON e.id = h.employee_id
//       JOIN items     i ON i.id = h.item_id
//       GROUP BY e.id, i.id
//       ORDER BY e.name ASC, i.name ASC
//     ''');
//   }
// }
