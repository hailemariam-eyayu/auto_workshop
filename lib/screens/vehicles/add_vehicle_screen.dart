import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/vehicle_dao.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';

const _vehicleTypes = [
  'Toyota Corolla', 'Toyota Hilux', 'Toyota Land Cruiser',
  'Hyundai Elantra', 'Hyundai Tucson',
  'Nissan Navara', 'Nissan Patrol',
  'Isuzu D-Max', 'Mitsubishi L200',
  'Ford Ranger', 'Suzuki Jimny',
];

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = await VehicleDao.instance.insert(Vehicle(
      plate: _plateCtrl.text.trim().toUpperCase(),
      model: _modelCtrl.text.trim(),
      entryDate: DateTime.now().toIso8601String(),
      status: 'Not Started',
      totalBill: 0,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    if (mounted) {
      Navigator.pop(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('MMM d, y  HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('New Vehicle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Entry date info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Entry date/time will be recorded as: $now',
                        style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plate
            const Text('License Plate Number *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: 2, color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: 'AA 12345',
                filled: true, fillColor: Colors.white,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Model
            const Text('Vehicle Type / Model *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Toyota Hilux 2022',
                filled: true, fillColor: Colors.white,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            const Text('Quick pick:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _vehicleTypes.map((t) => GestureDetector(
                onTap: () { _modelCtrl.text = t; setState(() {}); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _modelCtrl.text == t ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _modelCtrl.text == t ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(t,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _modelCtrl.text == t ? Colors.white : AppColors.textMuted,
                      )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Customer name, phone, special instructions...',
                filled: true, fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Vehicle',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
