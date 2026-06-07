import 'package:flutter/material.dart';
import '../../db/material_dao.dart';
import '../../models/material.dart';
import '../../l10n/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import 'add_material_screen.dart';

class MaterialsScreen extends StatefulWidget {
  final LocaleProvider locale;

  const MaterialsScreen({super.key, required this.locale});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<WorkshopMaterial> _allMaterials = [];
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
    final data = await MaterialDao.instance.getAll();
    setState(() {
      _allMaterials = data;
      _loading = false;
    });
  }

  List<WorkshopMaterial> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _allMaterials;
    return _allMaterials
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.category.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _incrementQuantity(WorkshopMaterial material) async {
    await MaterialDao.instance.incrementQuantity(material.id!, 1);
    _load();
  }

  Future<void> _decrementQuantity(WorkshopMaterial material) async {
    await MaterialDao.instance.decrementQuantity(material.id!, 1);
    _load();
  }

  Future<void> _delete(WorkshopMaterial material) async {
    final s = widget.locale.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteMaterial),
        content: Text(s.deleteMaterialConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await MaterialDao.instance.delete(material.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.materials,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${_allMaterials.length} ${s.total}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddMaterialScreen(locale: widget.locale)));
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
                hintText: '${s.search} ${s.materials.toLowerCase()}...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textMuted),
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
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: s.noMaterials,
                        subtitle: s.noMaterialsHint)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final material = _filtered[index];
                            return _MaterialTile(
                              locale: widget.locale,
                              material: material,
                              onIncrement: () =>
                                  _incrementQuantity(material),
                              onDecrement: () =>
                                  _decrementQuantity(material),
                              onEdit: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddMaterialScreen(
                                              locale: widget.locale,
                                              material: material,
                                            )));
                                _load();
                              },
                              onDelete: () => _delete(material),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _MaterialTile extends StatelessWidget {
  final LocaleProvider locale;
  final WorkshopMaterial material;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialTile({
    required this.locale,
    required this.material,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (material.category.isNotEmpty)
                        Text(
                          material.category,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(locale.s.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(locale.s.delete,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quantity controls and display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity display
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${material.quantity}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                      Text(
                        material.unit,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Increment/Decrement buttons
                Row(
                  children: [
                    // Decrement button
                    IconButton(
                      onPressed:
                          material.quantity > 0 ? onDecrement : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: material.quantity > 0
                          ? AppColors.primary
                          : Colors.grey,
                      tooltip: 'Decrease',
                    ),
                    const SizedBox(width: 8),
                    // Increment button
                    IconButton(
                      onPressed: onIncrement,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.accent,
                      tooltip: 'Increase',
                    ),
                  ],
                ),
              ],
            ),
            if (material.description != null &&
                material.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    material.description!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
