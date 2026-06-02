import 'package:flutter/material.dart';
import '../../db/borrow_dao.dart';
import '../../db/employee_dao.dart';
import '../../db/item_dao.dart';
import '../../models/employee.dart';
import '../../models/item.dart';
import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';

// ── Selection model ───────────────────────────────────────────────────────────

class _SelectedItem {
  final Item item;
  int quantity;
  _SelectedItem({required this.item, this.quantity = 1});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AddBorrowScreen extends StatefulWidget {
  final LocaleProvider locale;
  final int? preselectedEmployeeId;

  const AddBorrowScreen(
      {super.key, required this.locale, this.preselectedEmployeeId});

  @override
  State<AddBorrowScreen> createState() => _AddBorrowScreenState();
}

class _AddBorrowScreenState extends State<AddBorrowScreen> {
  List<Employee> _employees = [];
  Map<String, List<Item>> _grouped = {};
  Employee? _selectedEmployee;
  // key = item.id, value = selection
  final Map<int, _SelectedItem> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await EmployeeDao.instance.getAll();
    final grouped = await ItemDao.instance.getGrouped();
    setState(() {
      _employees = employees;
      _grouped = grouped;
      if (widget.preselectedEmployeeId != null && employees.isNotEmpty) {
        _selectedEmployee = employees.firstWhere(
          (e) => e.id == widget.preselectedEmployeeId,
          orElse: () => employees.first,
        );
      }
      _loading = false;
    });
  }

  bool get _canSave =>
      _selectedEmployee != null && _selected.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    for (final sel in _selected.values) {
      await BorrowDao.instance.upsertBorrow(
        employeeId: _selectedEmployee!.id!,
        itemId: sel.item.id!,
        quantity: sel.quantity,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  void _toggle(Item item) {
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected[item.id!] = _SelectedItem(item: item);
      }
    });
  }

  void _selectAll(List<Item> items) {
    setState(() {
      for (final item in items) {
        _selected.putIfAbsent(item.id!, () => _SelectedItem(item: item));
      }
    });
  }

  void _clearAll(List<Item> items) {
    setState(() {
      for (final item in items) {
        _selected.remove(item.id);
      }
    });
  }

  void _increment(Item item) {
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected[item.id!]!.quantity++;
      } else {
        _selected[item.id!] = _SelectedItem(item: item, quantity: 1);
      }
    });
  }

  void _decrement(Item item) {
    setState(() {
      final sel = _selected[item.id];
      if (sel == null) return;
      if (sel.quantity > 1) {
        sel.quantity--;
      } else {
        _selected.remove(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final totalSelected = _selected.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.borrowEquipment,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              '$totalSelected ${s.items} ${s.borrowed}',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (_saving || !_canSave) ? null : _save,
            child: Text(
              s.save,
              style: TextStyle(
                color: _canSave ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Employee selector ─────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Employee>(
                      value: _selectedEmployee,
                      isExpanded: true,
                      hint: Text(s.selectEmployee,
                          style: const TextStyle(
                              color: AppColors.textMuted)),
                      items: _employees
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.12),
                                      child: Text(
                                        e.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(e.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (e) =>
                          setState(() => _selectedEmployee = e),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // ── Equipment list ────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _grouped.length,
                    itemBuilder: (_, i) {
                      final category =
                          _grouped.keys.elementAt(i);
                      final items = _grouped[category]!;
                      return _CategorySection(
                        category: category,
                        items: items,
                        selected: _selected,
                        onToggle: _toggle,
                        onSelectAll: () => _selectAll(items),
                        onClearAll: () => _clearAll(items),
                        onIncrement: _increment,
                        onDecrement: _decrement,
                        rowNumber: i + 1,
                        isSingleItem: items.length == 1,
                      );
                    },
                  ),
                ),

                // ── Bottom bar ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalSelected ${s.items} ${s.borrowed}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark),
                            ),
                            if (_selectedEmployee != null)
                              Text(
                                _selectedEmployee!.name,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            (_saving || !_canSave) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('CONFIRM',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Category section widget ───────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Item> items;
  final Map<int, _SelectedItem> selected;
  final void Function(Item) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final void Function(Item) onIncrement;
  final void Function(Item) onDecrement;
  final int rowNumber;
  final bool isSingleItem;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onIncrement,
    required this.onDecrement,
    required this.rowNumber,
    required this.isSingleItem,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected =
        items.every((i) => selected.containsKey(i.id));
    final anySelected =
        items.any((i) => selected.containsKey(i.id));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: anySelected
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Row number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$rowNumber',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                ),
                if (!isSingleItem) ...[
                  _HeaderBtn(
                    label: 'SELECT ALL',
                    active: allSelected,
                    onTap: allSelected ? onClearAll : onSelectAll,
                  ),
                  const SizedBox(width: 6),
                  _HeaderBtn(
                    label: 'CLEAR ALL',
                    active: false,
                    onTap: onClearAll,
                    isDestructive: true,
                  ),
                ] else
                  // Single item: just a CLICK/UNCLICK button
                  _HeaderBtn(
                    label: selected.containsKey(items.first.id)
                        ? 'UNCLICK'
                        : 'CLICK',
                    active: selected.containsKey(items.first.id),
                    onTap: () => onToggle(items.first),
                  ),
              ],
            ),
          ),

          // ── Size chips (only for multi-size groups) ──────────────
          if (!isSingleItem)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((item) {
                  final sel = selected[item.id];
                  final isSelected = sel != null;
                  // Extract size label (e.g. "ስቴላ 4mm" → "4mm")
                  final label = item.name.contains(' ')
                      ? item.name.split(' ').last
                      : item.name;

                  return GestureDetector(
                    onTap: () => onToggle(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            // Count badge with +/- controls
                            _CountBadge(
                              count: sel.quantity,
                              onIncrement: () => onIncrement(item),
                              onDecrement: () => onDecrement(item),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Count badge (+/-) ─────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CountBadge({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement (also removes if count reaches 0)
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.remove,
                size: 10, color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$count',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add,
                size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── Header button ─────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDestructive;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    if (active) {
      bg = AppColors.primary;
      fg = Colors.white;
      border = AppColors.primary;
    } else if (isDestructive) {
      bg = Colors.white;
      fg = AppColors.textMuted;
      border = AppColors.border;
    } else {
      bg = Colors.white;
      fg = AppColors.primary;
      border = AppColors.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3),
        ),
      ),
    );
  }
}
