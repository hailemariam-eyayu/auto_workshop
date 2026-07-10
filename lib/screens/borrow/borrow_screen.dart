import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/borrow_dao.dart';
import '../../db/employee_dao.dart';
import '../../models/borrow.dart';
import '../../models/employee.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/locale_provider.dart';
import 'add_borrow_screen.dart';
import 'employee_detail_screen.dart';

class BorrowScreen extends StatefulWidget {
  final LocaleProvider locale;
  const BorrowScreen({super.key, required this.locale});

  @override
  State<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends State<BorrowScreen> {
  List<Employee> _employees = [];
  List<Borrow> _borrows = [];
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
    setState(() {
      _employees = employees;
      _borrows = borrows;
      _loading = false;
    });
  }

  // Group borrows by employee
  Map<int, List<Borrow>> get _grouped {
    final map = <int, List<Borrow>>{};
    for (final b in _borrows) {
      map.putIfAbsent(b.employeeId, () => []).add(b);
    }
    return map;
  }

  List<Employee> get _filteredEmployees {
    final withBorrows = _employees
        .where((e) => _grouped.containsKey(e.id))
        .toList();
    if (_search.isEmpty) return withBorrows;
    final q = _search.toLowerCase();
    return withBorrows.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final totalBorrowed = _borrows.fold<int>(0, (sum, b) => sum + b.quantity);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.equipmentBorrow,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              '$totalBorrowed ${s.borrowed}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          if (_employees.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(s.noEmployees)));
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddBorrowScreen(locale: widget.locale),
            ),
          );
          _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
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
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                ? EmptyState(
                    icon: Icons.hardware_outlined,
                    title: s.noBorrows,
                    subtitle: s.noBorrowsHint,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: _filteredEmployees.length,
                      itemBuilder: (_, i) {
                        final emp = _filteredEmployees[i];
                        final items = _grouped[emp.id] ?? [];
                        return _EmployeeBorrowCard(
                          employee: emp,
                          borrows: items,
                          locale: widget.locale,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetailScreen(
                                  employee: emp,
                                  locale: widget.locale,
                                ),
                              ),
                            );
                            _load();
                          },
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

class _EmployeeBorrowCard extends StatelessWidget {
  final Employee employee;
  final List<Borrow> borrows;
  final LocaleProvider locale;
  final VoidCallback onTap;

  const _EmployeeBorrowCard({
    required this.employee,
    required this.borrows,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    final totalQty = borrows.fold<int>(0, (sum, b) => sum + b.quantity);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      employee.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$totalQty ${s.items}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Item rows
              // ...borrows.map((b) => Padding(
              //       padding: const EdgeInsets.symmetric(vertical: 3),
              //       child: Row(
              //         children: [
              //           const Icon(Icons.hardware_outlined,
              //               size: 14, color: AppColors.textMuted),
              //           const SizedBox(width: 6),
              //           Expanded(
              //             child: Text(b.itemName,
              //                 style: const TextStyle(
              //                     fontSize: 13,
              //                     color: AppColors.textDark)),
              //           ),
              //           Container(
              //             padding: const EdgeInsets.symmetric(
              //                 horizontal: 8, vertical: 2),
              //             decoration: BoxDecoration(
              //               color: AppColors.primary.withOpacity(0.08),
              //               borderRadius: BorderRadius.circular(6),
              //             ),
              //             child: Text(
              //               '× ${b.quantity}',
              //               style: const TextStyle(
              //                   fontSize: 12,
              //                   fontWeight: FontWeight.w700,
              //                   color: AppColors.primary),
              //             ),
              //           ),
              //         ],
              //       ),
              //     )),
              ...borrows.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.hardware_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b.itemName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '× ${b.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (b.notes != null && b.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 2),
                          child: Text(
                            '📝 ${b.notes}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${s.borrowed}: ${DateFormat('MMM d, y').format(DateTime.tryParse(borrows.first.borrowedAt) ?? DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
