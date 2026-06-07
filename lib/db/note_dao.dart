import '../models/note.dart';
import 'database_helper.dart';

class NoteDao {
  static final NoteDao instance = NoteDao._();
  NoteDao._();

  Future<List<Note>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map((row) => Note.fromMap(row)).toList();
  }

  Future<Note> insert(Note note) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  Future<void> update(Note note) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
