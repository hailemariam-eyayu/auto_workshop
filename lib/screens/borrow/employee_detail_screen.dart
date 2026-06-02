import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/borrow_dao.dart';
import '../../models/borrow.dart';
import '../../models/borrow_history.dart';
import '../../models/employee.dart';
import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';
import 'add_borrow_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final LocaleProvider locale;

  const EmployeeDetailScreen(
      {super.key, required this.employee, required this.locale});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Borrow> _borrows = [];
  List<BorrowHistory> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final borrows =
        await BorrowDao.instance.getByEmployee(widget.employee.id!);
    final history =
        await BorrowDao.instance.getHistory(employeeId: widget.employee.id!);
    setState(() {
      _borrows = borrows;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _showReturnDialog(Borrow b) async {
    final s = widget.locale.s;
    int returnQty = 1;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(s.returnItem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.itemName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('${s.borrowedQty}: ${b.quantity}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Text(s.qtyToReturn,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DlgBtn(
                    icon: Icons.remove,
                    onTap: () {
                      if (returnQty > 1) setDlg(() => returnQty--);
                    },
                  ),
                  Container(
                    width: 56,
                    alignment: Alignment.center,
                    child: Text('$returnQty',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  _DlgBtn(
                    icon: Icons.add,
                    onTap: () {
                      if (returnQty < b.quantity) setDlg(() => returnQty++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Text('${s.maxIs}: ${b.quantity}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await BorrowDao.instance.returnBorrow(
                  borrowId: b.id!,
                  employeeId: b.employeeId,
                  itemId: b.itemId,
                  returnQty: returnQty,
                  currentQty: b.quantity,
                );
                _load();
              },
              child: Text(s.returnItems),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Borrow b) async {
    final s = widget.locale.s;
    int qty = b.quantity;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(s.editBorrow),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.itemName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              Text(s.quantity,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DlgBtn(
                    icon: Icons.remove,
                    onTap: () {
                      if (qty > 1) setDlg(() => qty--);
                    },
                  ),
                  Container(
                    width: 56,
                    alignment: Alignment.center,
                    child: Text('$qty',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  _DlgBtn(
                    icon: Icons.add,
                    onTap: () => setDlg(() => qty++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await BorrowDao.instance.updateQuantity(b.id!, qty);
                _load();
              },
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBorrow(Borrow b) async {
    final s = widget.locale.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteBorrow),
        content: Text(s.deleteBorrowConfirm),
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
      await BorrowDao.instance.deleteBorrow(b.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final emp = widget.employee;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(emp.name),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: s.currentlyBorrowed),
            Tab(text: s.history),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: s.borrowEquipment,
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddBorrowScreen(
                            locale: widget.locale,
                            preselectedEmployeeId: emp.id,
                          )));
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _BorrowsTab(
                  borrows: _borrows,
                  locale: widget.locale,
                  onReturn: _showReturnDialog,
                  onEdit: _showEditDialog,
                  onDelete: _deleteBorrow,
                ),
                _HistoryTab(history: _history, locale: widget.locale),
              ],
            ),
    );
  }
}

// ── Currently Borrowed Tab ────────────────────────────────────────────────────

class _BorrowsTab extends StatelessWidget {
  final List<Borrow> borrows;
  final LocaleProvider locale;
  final Future<void> Function(Borrow) onReturn;
  final Future<void> Function(Borrow) onEdit;
  final Future<void> Function(Borrow) onDelete;

  const _BorrowsTab({
    required this.borrows,
    required this.locale,
    required this.onReturn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    if (borrows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: AppColors.success),
            const SizedBox(height: 12),
            Text(s.noActiveborrows,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: borrows.length,
      itemBuilder: (_, i) {
        final b = borrows[i];
        final dt = DateTime.tryParse(b.borrowedAt);
        final dateStr =
            dt != null ? DateFormat('MMM d, y').format(dt) : b.borrowedAt;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hardware_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b.itemName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '× ${b.quantity}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${s.borrowedOn}: $dateStr',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onReturn(b),
                        icon: const Icon(Icons.undo, size: 15),
                        label: Text(s.returnItems,
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(
                              color: AppColors.success),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onEdit(b),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 16),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onDelete(b),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      ),
                      child: const Icon(Icons.delete_outline, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<BorrowHistory> history;
  final LocaleProvider locale;

  const _HistoryTab({required this.history, required this.locale});

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    if (history.isEmpty) {
      return Center(
        child: Text(s.noHistory,
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final isBorrow = h.action == 'borrowed';
        final dt = DateTime.tryParse(h.timestamp);
        final dateStr = dt != null
            ? DateFormat('MMM d, y  HH:mm').format(dt)
            : h.timestamp;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isBorrow
                  ? AppColors.accent.withOpacity(0.12)
                  : AppColors.success.withOpacity(0.12),
              child: Icon(
                isBorrow ? Icons.arrow_upward : Icons.arrow_downward,
                color: isBorrow ? AppColors.accent : AppColors.success,
                size: 18,
              ),
            ),
            title: Text(h.itemName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(dateStr,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '× ${h.quantity}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isBorrow
                          ? AppColors.accent
                          : AppColors.success),
                ),
                Text(
                  isBorrow ? s.borrowed : s.returned,
                  style: TextStyle(
                      fontSize: 11,
                      color: isBorrow
                          ? AppColors.accent
                          : AppColors.success),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DlgBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DlgBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18),
        ),
      );
}
