import 'package:flutter/material.dart';
import '../../db/employee_dao.dart';
import '../../models/employee.dart';
import '../../theme/app_colors.dart';
import '../../l10n/locale_provider.dart';

class AddEmployeeScreen extends StatefulWidget {
  final LocaleProvider locale;
  final Employee? employee; // null = new, non-null = edit

  const AddEmployeeScreen({super.key, required this.locale, this.employee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.employee?.name ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.employee?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final phone = _phoneCtrl.text.trim();
    if (_isEdit) {
      await EmployeeDao.instance.update(widget.employee!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: phone.isEmpty ? null : phone,
      ));
    } else {
      await EmployeeDao.instance.insert(Employee(
        name: _nameCtrl.text.trim(),
        phone: phone.isEmpty ? null : phone,
        entryDate: DateTime.now().toIso8601String(),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? s.editEmployee : s.registerEmployee),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(s.save,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar preview
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Text(s.employeeName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: s.enterEmployeeName,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? s.required : null,
            ),
            const SizedBox(height: 16),

            // Phone
            Text('${s.phone} (${s.optional})',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: s.enterPhone,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(s.save,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
