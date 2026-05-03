import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/tool_dao.dart';
import '../../models/tool_transaction.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import 'add_tool_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  List<ToolTransaction> _all = [];
  String _filter = 'All';
  String _search = '';
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ToolDao.instance.getAll();
    setState(() { _all = data; _loading = false; });
  }

  List<ToolTransaction> get _filtered => _all.where((t) {
    final matchFilter = _filter == 'All' || t.status == _filter;
    final q = _search.toLowerCase();
    final matchSearch = q.isEmpty ||
        t.employee.toLowerCase().contains(q) ||
        t.toolName.toLowerCase().contains(q);
    return matchFilter && matchSearch;
  }).toList();

  Future<void> _markReturned(ToolTransaction t) async {
    await ToolDao.instance.markReturned(t.id!);
    _load();
  }

  Future<void> _delete(ToolTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete "${t.toolName}" record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) { await ToolDao.instance.delete(t.id!); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final borrowed = _all.where((t) => t.status == 'Borrowed').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tool Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('$borrowed currently borrowed',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddToolScreen()));
          _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search employee or tool...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
                filled: true, fillColor: Colors.white,
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Borrowed', 'Returned'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _filter == f ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ),
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: _filter == f ? AppColors.primary : AppColors.border),
                ),
              )).toList(),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.hardware_outlined,
                        title: 'No tool records',
                        subtitle: 'Tap + to log a borrowed tool')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _ToolCard(
                            item: _filtered[i],
                            onReturn: () => _markReturned(_filtered[i]),
                            onDelete: () => _delete(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolTransaction item;
  final VoidCallback onReturn, onDelete;

  const _ToolCard({required this.item, required this.onReturn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.tryParse(item.timestamp);
    final formatted = ts != null ? DateFormat('MMM d, y  HH:mm').format(ts) : item.timestamp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.toolName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ),
                StatusBadge(item.status),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(item.employee,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(width: 16),
              const Icon(Icons.layers_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Qty: ${item.quantity}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(formatted,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.notes!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
                      fontStyle: FontStyle.italic)),
            ],
            if (item.status == 'Borrowed') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Returned'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
