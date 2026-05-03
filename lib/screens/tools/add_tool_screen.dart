import 'package:flutter/material.dart';
import '../../db/tool_dao.dart';
import '../../models/tool_transaction.dart';
import '../../theme/app_colors.dart';

const _commonTools = [
  'Wrench', 'Socket Set', 'Screwdriver', 'Pliers', 'Jack Stand',
  'Torque Wrench', 'Oil Filter Wrench', 'Multimeter', 'Air Gun', 'Hammer',
];

class AddToolScreen extends StatefulWidget {
  const AddToolScreen({super.key});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeCtrl = TextEditingController();
  final _toolCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _quantity = 1;
  String _status = 'Borrowed';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ToolDao.instance.insert(ToolTransaction(
      employee: _employeeCtrl.text.trim(),
      toolName: _toolCtrl.text.trim(),
      quantity: _quantity,
      status: _status,
      timestamp: DateTime.now().toIso8601String(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Log Tool'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status toggle
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: ['Borrowed', 'Returned'].map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: s == 'Borrowed' ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _status == s ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _status == s ? AppColors.primary : AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s == 'Borrowed' ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: _status == s ? Colors.white : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(s,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _status == s ? Colors.white : AppColors.textMuted,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Employee
            const Text('Employee Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _employeeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Abebe Kebede',
                filled: true, fillColor: Colors.white,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Tool name
            const Text('Tool Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _toolCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Torque Wrench',
                filled: true, fillColor: Colors.white,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            const Text('Quick pick:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _commonTools.map((t) => GestureDetector(
                onTap: () { _toolCtrl.text = t; setState(() {}); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _toolCtrl.text == t ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _toolCtrl.text == t ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(t,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _toolCtrl.text == t ? Colors.white : AppColors.textMuted,
                      )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Quantity
            const Text('Quantity *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _QtyBtn(icon: Icons.remove,
                    onTap: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99))),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
                _QtyBtn(icon: Icons.add,
                    onTap: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99))),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
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
                  : const Text('Save Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textDark),
    ),
  );
}
