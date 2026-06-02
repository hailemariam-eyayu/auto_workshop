import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/employee_dao.dart';
import '../../db/borrow_dao.dart';
import '../../models/employee.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/locale_provider.dart';
import 'add_employee_screen.dart';
import '../borrow/employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final LocaleProvider locale;
  const EmployeesScreen({super.key, required this.locale});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> _employees = [];
  Map<int, int> _activeBorrowCounts = {};
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
    final employees = await EmployeeDao.instance.getAll();
    final borrows = await BorrowDao.instance.getAll();
    final counts = <int, int>{};
    for (final b in borrows) {
      counts[b.employeeId] = (counts[b.employeeId] ?? 0) + 1;
    }
    setState(() {
      _employees = employees;
      _activeBorrowCounts = counts;
      _loading = false;
    });
  }

  List<Employee> get _filtered {
    if (_search.isEmpty) return _employees;
    final q = _search.toLowerCase();
    return _employees
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.phone ?? '').contains(q))
        .toList();
  }

  Future<void> _delete(Employee e) async {
    final s = widget.locale.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteEmployee),
        content: Text(s.deleteEmployeeConfirm),
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
      await EmployeeDao.instance.delete(e.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.employees,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
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
                  builder: (_) =>
                      AddEmployeeScreen(locale: widget.locale)));
          _load();
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '${s.search}...',
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: s.noEmployees,
                        subtitle: s.noEmployeesHint)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final emp = _filtered[i];
                            final count =
                                _activeBorrowCounts[emp.id] ?? 0;
                            return _EmployeeCard(
                              employee: emp,
                              activeBorrows: count,
                              locale: widget.locale,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            EmployeeDetailScreen(
                                              employee: emp,
                                              locale: widget.locale,
                                            )));
                                _load();
                              },
                              onEdit: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddEmployeeScreen(
                                              locale: widget.locale,
                                              employee: emp,
                                            )));
                                _load();
                              },
                              onDelete: () => _delete(emp),
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

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final int activeBorrows;
  final LocaleProvider locale;
  final VoidCallback onTap, onEdit, onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.activeBorrows,
    required this.locale,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    final dt = DateTime.tryParse(employee.entryDate);
    final dateStr =
        dt != null ? DateFormat('MMM d, y').format(dt) : employee.entryDate;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    if (employee.phone != null &&
                        employee.phone!.isNotEmpty)
                      Text(employee.phone!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    Text('${s.registeredOn}: $dateStr',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (activeBorrows > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeBorrows ${s.activeborrows}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
