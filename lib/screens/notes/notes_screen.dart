import 'package:flutter/material.dart';
import '../../db/note_dao.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';
import 'add_note_screen.dart';
import '../../widgets/empty_state.dart';

class NotesScreen extends StatefulWidget {
  final LocaleProvider locale;
  const NotesScreen({super.key, required this.locale});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = await NoteDao.instance.getAll();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  List<Note> get _filtered {
    if (_search.isEmpty) return _notes;
    final q = _search.toLowerCase();
    return _notes
        .where((note) =>
            note.name.toLowerCase().contains(q) ||
            note.content.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _delete(Note note) async {
    final s = widget.locale.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteNote),
        content: Text(s.deleteNoteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.delete,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await NoteDao.instance.delete(note.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.notes,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => AddNoteScreen(locale: widget.locale)));
          if (changed == true) _load();
        },
        child: const Icon(Icons.note_add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '${s.search}...'.replaceAll('...', ''),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.note_alt_outlined,
                        title: s.noNotes,
                        subtitle: s.noNotesHint,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (_, index) {
                            final note = _filtered[index];
                            final date = DateTime.tryParse(note.updatedAt);
                            final dateStr = date != null
                                ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                                : note.updatedAt;
                            final snippet = note.content.split('\n').first;
                            return _NoteCard(
                              note: note,
                              dateLabel: dateStr,
                              snippet: snippet,
                              locale: widget.locale,
                              onEdit: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddNoteScreen(
                                      locale: widget.locale,
                                      note: note,
                                    ),
                                  ),
                                );
                                if (changed == true) _load();
                              },
                              onDelete: () => _delete(note),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final String dateLabel;
  final String snippet;
  final LocaleProvider locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.dateLabel,
    required this.snippet,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.name.isNotEmpty ? note.name : snippet,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                ),
                Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(s.edit,
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(s.delete,
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
