import 'package:flutter/material.dart';
import '../../db/borrow_dao.dart';
import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';
import '../../widgets/empty_state.dart';

class AnalysisScreen extends StatefulWidget {
  final LocaleProvider locale;
  const AnalysisScreen({super.key, required this.locale});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await BorrowDao.instance.getAnalysis();
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  // Group rows by employee
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in _data) {
      final emp = row['employee_name'] as String;
      map.putIfAbsent(emp, () => []).add(row);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.analysis,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
              ? EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: s.noHistory,
                  subtitle: s.noHistoryHint)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: grouped.entries.map((entry) {
                      final empName = entry.key;
                      final rows = entry.value;
                      final totalBorrowed = rows.fold<int>(
                          0,
                          (sum, r) =>
                              sum + (r['total_borrowed'] as int? ?? 0));
                      final totalReturned = rows.fold<int>(
                          0,
                          (sum, r) =>
                              sum + (r['total_returned'] as int? ?? 0));
                      final outstanding = totalBorrowed - totalReturned;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Employee header
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      empName[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(empName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark)),
                                  ),
                                  if (outstanding > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$outstanding ${s.borrowed}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Summary row
                              Row(
                                children: [
                                  _StatChip(
                                    label: s.totalBorrowed,
                                    value: '$totalBorrowed',
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatChip(
                                    label: s.totalReturned,
                                    value: '$totalReturned',
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Per-item breakdown
                              ...rows.map((r) {
                                final tb = r['total_borrowed'] as int? ?? 0;
                                final tr = r['total_returned'] as int? ?? 0;
                                final out = tb - tr;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hardware_outlined,
                                          size: 14,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                            r['item_name'] as String? ?? '',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textDark)),
                                      ),
                                      _MiniStat(
                                          label: '↑$tb',
                                          color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      _MiniStat(
                                          label: '↓$tr',
                                          color: AppColors.success),
                                      const SizedBox(width: 6),
                                      if (out > 0)
                                        _MiniStat(
                                            label: '=$out',
                                            color: AppColors.primary),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}
