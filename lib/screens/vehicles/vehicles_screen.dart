import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/vehicle_dao.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/locale_provider.dart';
import 'vehicle_detail_screen.dart';

class VehiclesScreen extends StatefulWidget {
  final LocaleProvider? locale;
  const VehiclesScreen({super.key, this.locale});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Vehicle> _all = [];
  String _filter = 'All';
  String _search = '';
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  late final LocaleProvider _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? LocaleProvider();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await VehicleDao.instance.getAll();
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<Vehicle> get _filtered => _all.where((v) {
        final matchFilter =
            _filter == _locale.s.all || v.status == _filter;
        final q = _search.toLowerCase();
        final matchSearch =
            q.isEmpty || v.plate.toLowerCase().contains(q);
        return matchFilter && matchSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final s = _locale.s;
    final inProgress =
        _all.where((v) => v.status == 'In Progress').length;
    final allStatuses = [s.all, ...Vehicle.statuses];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.serviceBilling,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text('$inProgress ${s.inProgress}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VehicleDetailScreen(
                      id: null, locale: _locale)));
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
                hintText: s.searchPlate,
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted),
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
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: allStatuses
                  .map((st) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(st,
                              style:
                                  const TextStyle(fontSize: 12)),
                          selected: _filter == st,
                          onSelected: (_) =>
                              setState(() => _filter = st),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _filter == st
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                              color: _filter == st
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: s.noVehicles,
                        subtitle: s.noVehiclesHint)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.only(bottom: 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _VehicleCard(
                            vehicle: _filtered[i],
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VehicleDetailScreen(
                                              id: _filtered[i].id,
                                              locale: _locale)));
                              _load();
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const _VehicleCard(
      {required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(vehicle.entryDate);
    final dateStr = dt != null
        ? DateFormat('MMM d, y').format(dt)
        : vehicle.entryDate.substring(0, 10);
    final fmt = NumberFormat('#,##0.##');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(vehicle.plate,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                  ),
                  const Spacer(),
                  StatusBadge(vehicle.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ]),
                  Text(
                    'ETB ${fmt.format(vehicle.totalBill)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
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
