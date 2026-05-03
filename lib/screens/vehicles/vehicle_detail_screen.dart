import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/vehicle_dao.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';

const _commonServices = [
  ('Oil Change', 500.0),
  ('Tire Change', 300.0),
  ('Brake Service', 800.0),
  ('Battery Replacement', 1200.0),
  ('Air Filter', 250.0),
  ('Wheel Alignment', 600.0),
  ('Engine Tune-up', 1500.0),
  ('Transmission Service', 2000.0),
  ('AC Service', 900.0),
  ('Suspension Check', 700.0),
];

class VehicleDetailScreen extends StatefulWidget {
  final int id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final v = await VehicleDao.instance.getById(widget.id);
    setState(() { _vehicle = v; _loading = false; });
  }

  Future<void> _changeStatus() async {
    final v = _vehicle!;
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Update Status'),
        children: Vehicle.statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, s),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(s),
                if (v.status == s) const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        )).toList(),
      ),
    );
    if (chosen != null && chosen != v.status) {
      await VehicleDao.instance.updateStatus(v.id!, chosen);
      _load();
    }
  }

  Future<void> _addService() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Service',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Service Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Oil Change',
                  filled: true, fillColor: Color(0xFFF8F9FA),
                ),
              ),
              const SizedBox(height: 8),
              // Quick pick
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _commonServices.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        nameCtrl.text = s.$1;
                        priceCtrl.text = s.$2.toStringAsFixed(0);
                        setModal(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: nameCtrl.text == s.$1
                              ? AppColors.primary : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.$1,
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: nameCtrl.text == s.$1
                                      ? Colors.white : AppColors.textMuted,
                                )),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Price (ETB)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: 'ETB ',
                  filled: true, fillColor: Color(0xFFF8F9FA),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    await VehicleDao.instance.addService(Service(
                      vehicleId: widget.id,
                      name: nameCtrl.text.trim(),
                      price: price,
                      createdAt: DateTime.now().toIso8601String(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Add Service',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Delete ${_vehicle!.plate}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await VehicleDao.instance.delete(widget.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_vehicle == null) return const Scaffold(body: Center(child: Text('Not found')));

    final v = _vehicle!;
    final statusIndex = Vehicle.statuses.indexOf(v.status);
    final dt = DateTime.tryParse(v.entryDate);
    final entryStr = dt != null ? DateFormat('MMM d, y  HH:mm').format(dt) : v.entryDate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(v.plate,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFCA5A5)),
            onPressed: _deleteVehicle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(Icons.directions_car_outlined, 'Model', v.model),
                  const Divider(height: 16),
                  _InfoRow(Icons.calendar_today_outlined, 'Entry', entryStr),
                  if (v.notes != null && v.notes!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _InfoRow(Icons.notes_outlined, 'Notes', v.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _changeStatus,
                    child: Row(
                      children: [
                        StatusBadge(v.status),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                        const Spacer(),
                        const Text('Tap to change',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  Row(
                    children: List.generate(Vehicle.statuses.length, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < Vehicle.statuses.length - 1 ? 3 : 0),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= statusIndex ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: Vehicle.statuses.map((s) => Expanded(
                      child: Text(s.split('/').first,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Services card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Services Performed',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ElevatedButton.icon(
                        onPressed: _addService,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (v.services.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('No services added yet',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ),
                    )
                  else
                    ...v.services.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.name,
                                style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                          ),
                          Text('ETB ${NumberFormat('#,##0').format(s.price)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await VehicleDao.instance.deleteService(s.id!, widget.id);
                              _load();
                            },
                            child: const Icon(Icons.cancel_outlined,
                                size: 18, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Total bill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white70)),
                Text('ETB ${NumberFormat('#,##0').format(v.totalBill)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 8),
      SizedBox(width: 52,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
      ),
    ],
  );
}
