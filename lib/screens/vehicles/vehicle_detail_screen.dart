import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/vehicle_dao.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/locale_provider.dart';

const _commonServices = [
  'Oil Change', 'Tire Change', 'Brake Service',
  'Battery Replacement', 'Air Filter', 'Wheel Alignment',
  'Engine Tune-up', 'Transmission Service', 'AC Service',
  'Suspension Check', 'Spark Plugs', 'Coolant Flush',
  'Clutch Repair', 'Exhaust Repair', 'Radiator Service',
];

// ── Editable row ──────────────────────────────────────────────────────────────
class _ServiceRow {
  final TextEditingController nameCtrl;
  final TextEditingController feeCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController notesCtrl;
  int quantity;

  _ServiceRow()
      : nameCtrl = TextEditingController(),
        feeCtrl = TextEditingController(),
        discountCtrl = TextEditingController(),
        notesCtrl = TextEditingController(),
        quantity = 1;

  _ServiceRow.fromService(Service s)
      : nameCtrl = TextEditingController(text: s.name),
        feeCtrl = TextEditingController(
            text: s.unitPrice > 0 ? s.unitPrice.toStringAsFixed(0) : ''),
        discountCtrl = TextEditingController(
            text: s.discount > 0 ? s.discount.toStringAsFixed(0) : ''),
        notesCtrl = TextEditingController(text: s.notes ?? ''),
        quantity = s.quantity;

  double get unitPrice => double.tryParse(feeCtrl.text) ?? 0;
  double get discount => double.tryParse(discountCtrl.text) ?? 0;
  double get subtotal => unitPrice * quantity;
  double get total => subtotal - discount;
  bool get isValid => nameCtrl.text.trim().isNotEmpty;

  void dispose() {
    nameCtrl.dispose();
    feeCtrl.dispose();
    discountCtrl.dispose();
    notesCtrl.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class VehicleDetailScreen extends StatefulWidget {
  final int? id;
  final LocaleProvider? locale;
  const VehicleDetailScreen({super.key, required this.id, this.locale});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;
  bool _saving = false;
  late final LocaleProvider _locale;

  final _plateCtrl = TextEditingController();
  final _globalNotesCtrl = TextEditingController();
  String _status = 'Not Started';
  final List<_ServiceRow> _rows = [];

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? LocaleProvider();
    _load();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _globalNotesCtrl.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_isNew) {
      _rows.add(_ServiceRow());
      setState(() => _loading = false);
      return;
    }
    final v = await VehicleDao.instance.getById(widget.id!);
    if (v == null) { setState(() => _loading = false); return; }
    _vehicle = v;
    _plateCtrl.text = v.plate;
    _globalNotesCtrl.text = v.notes ?? '';
    _status = v.status;
    for (final r in _rows) r.dispose();
    _rows.clear();
    if (v.services.isEmpty) {
      _rows.add(_ServiceRow());
    } else {
      for (final s in v.services) _rows.add(_ServiceRow.fromService(s));
    }
    setState(() => _loading = false);
  }

  double get _grandTotal => _rows.fold(0, (sum, r) => sum + r.total);

  Future<void> _save() async {
    final s = _locale.s;
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.plateRequired)));
      return;
    }
    final validRows = _rows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.atLeastOneService)));
      return;
    }
    setState(() => _saving = true);
    final notes = _globalNotesCtrl.text.trim();
    final now = DateTime.now().toIso8601String();

    if (_isNew) {
      final vehicleId = await VehicleDao.instance.insert(Vehicle(
        plate: plate,
        entryDate: now,
        status: _status,
        totalBill: 0,
        notes: notes.isEmpty ? null : notes,
      ));
      for (final r in validRows) {
        await VehicleDao.instance.addService(Service(
          vehicleId: vehicleId,
          name: r.nameCtrl.text.trim(),
          unitPrice: r.unitPrice,
          quantity: r.quantity,
          discount: r.discount,
          notes: r.notesCtrl.text.trim().isEmpty ? null : r.notesCtrl.text.trim(),
          createdAt: now,
        ));
      }
    } else {
      await VehicleDao.instance.updateVehicle(_vehicle!.copyWith(
        plate: plate, status: _status,
        notes: notes.isEmpty ? null : notes,
      ));
      await VehicleDao.instance.deleteAllServices(widget.id!);
      for (final r in validRows) {
        await VehicleDao.instance.addService(Service(
          vehicleId: widget.id!,
          name: r.nameCtrl.text.trim(),
          unitPrice: r.unitPrice,
          quantity: r.quantity,
          discount: r.discount,
          notes: r.notesCtrl.text.trim().isEmpty ? null : r.notesCtrl.text.trim(),
          createdAt: now,
        ));
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteVehicle() async {
    final s = _locale.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteRecord),
        content: Text(s.deleteRecordConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await VehicleDao.instance.delete(widget.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickStatus() async {
    final s = _locale.s;
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(s.updateStatus),
        children: Vehicle.statuses.map((st) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, st),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(st),
                if (_status == st)
                  const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        )).toList(),
      ),
    );
    if (chosen != null) setState(() => _status = chosen);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final s = _locale.s;
    final fmt = NumberFormat('#,##0.##');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          _isNew ? s.newServiceBill : (_vehicle?.plate ?? s.edit),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFCA5A5)),
              onPressed: _deleteVehicle,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? s.saving : s.save,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plate
          Text(s.vehiclePlateNumber,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                letterSpacing: 2, color: AppColors.primary),
            decoration: InputDecoration(
              hintText: s.platePlaceholder,
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Status
          Text(s.status,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  StatusBadge(_status),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                  const Spacer(),
                  Text(s.tapToChange,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Service items header
          Row(
            children: [
              Expanded(
                child: Text(s.serviceItems,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Text('${_rows.length} ${s.itemCount}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),

          // Service rows
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return _ServiceItemCard(
              key: ObjectKey(row),
              index: i,
              row: row,
              locale: _locale,
              canRemove: _rows.length > 1,
              onRemove: () => setState(() { row.dispose(); _rows.removeAt(i); }),
              onChanged: () => setState(() {}),
            );
          }),

          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() => _rows.add(_ServiceRow())),
            icon: const Icon(Icons.add, size: 16),
            label: Text(s.addAnotherService),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Grand total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.totalBill,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70)),
                Text('ETB ${fmt.format(_grandTotal)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Global notes
          Text('${s.name.isEmpty ? "" : ""}${s.optional} — Notes',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _globalNotesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.globalNotesHint,
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(s.save,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Service item card ─────────────────────────────────────────────────────────
class _ServiceItemCard extends StatefulWidget {
  final int index;
  final _ServiceRow row;
  final bool canRemove;
  final LocaleProvider locale;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ServiceItemCard({
    super.key,
    required this.index,
    required this.row,
    required this.canRemove,
    required this.locale,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ServiceItemCard> createState() => _ServiceItemCardState();
}

class _ServiceItemCardState extends State<_ServiceItemCard> {
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _showNotes = widget.row.notesCtrl.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final row = widget.row;
    final fmt = NumberFormat('#,##0.##');
    final subtotal = row.subtotal;
    final total = row.total;
    final hasDiscount = row.discount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text(s.serviceItem,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const Spacer(),
                if (widget.canRemove)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name
                Text(s.serviceName,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 5),
                TextField(
                  controller: row.nameCtrl,
                  onChanged: (_) { setState(() {}); widget.onChanged(); },
                  decoration: InputDecoration(
                    hintText: s.serviceNameHint,
                    isDense: true, filled: true, fillColor: const Color(0xFFF8F9FA),
                  ),
                ),
                const SizedBox(height: 6),

                // Quick pick chips
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _commonServices.map((svc) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          row.nameCtrl.text = svc;
                          setState(() {}); widget.onChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: row.nameCtrl.text == svc
                                ? AppColors.primary : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(svc,
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: row.nameCtrl.text == svc
                                    ? Colors.white : AppColors.textMuted,
                              )),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Fee + Quantity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.feePerItem,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: row.feeCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) { setState(() {}); widget.onChanged(); },
                            decoration: const InputDecoration(
                              hintText: '0', prefixText: 'ETB ',
                              isDense: true, filled: true, fillColor: Color(0xFFF8F9FA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(s.number,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.textMuted)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _StepBtn(
                              icon: Icons.remove,
                              onTap: () {
                                if (row.quantity > 1) {
                                  setState(() => row.quantity--);
                                  widget.onChanged();
                                }
                              },
                            ),
                            Container(
                              width: 42, height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text('${row.quantity}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                            _StepBtn(
                              icon: Icons.add,
                              onTap: () { setState(() => row.quantity++); widget.onChanged(); },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total per item (readonly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${s.totalPerItem}  (${row.feeCtrl.text.isEmpty ? "0" : row.feeCtrl.text} × ${row.quantity})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Text('ETB ${fmt.format(subtotal)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Discount
                Text(s.discount,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 5),
                TextField(
                  controller: row.discountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) { setState(() {}); widget.onChanged(); },
                  decoration: const InputDecoration(
                    hintText: '0', prefixText: '- ETB ',
                    isDense: true, filled: true, fillColor: Color(0xFFF8F9FA),
                  ),
                ),

                // Net total after discount
                if (hasDiscount) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Text(s.netTotal,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.textMuted)),
                        const Spacer(),
                        Text('ETB ${fmt.format(total < 0 ? 0 : total)}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                ],

                // Notes toggle
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _showNotes = !_showNotes),
                  child: Row(
                    children: [
                      Icon(
                        _showNotes ? Icons.expand_less : Icons.expand_more,
                        size: 16, color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showNotes ? s.hideNotes : s.addNotes,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_showNotes) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: row.notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: s.notesForService,
                      isDense: true, filled: true, fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stepper button ────────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.textDark),
        ),
      );
}
