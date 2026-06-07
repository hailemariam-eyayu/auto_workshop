import 'package:flutter/material.dart';
import '../../db/material_dao.dart';
import '../../models/material.dart';
import '../../l10n/locale_provider.dart';
import '../../theme/app_colors.dart';

class AddMaterialScreen extends StatefulWidget {
  final LocaleProvider locale;
  final WorkshopMaterial? material;

  const AddMaterialScreen({
    super.key,
    required this.locale,
    this.material,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descriptionCtrl;
  String _selectedUnit = 'piece';
  bool _saving = false;

  // Available units
  final List<String> _units = [
    'piece',
    'mm',
    'cm',
    'm',
    'kg',
    'g',
    'l',
    'ml',
    'pensa', // Portuguese/Amharic word for caliper or measurement
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.material?.name ?? '');
    _categoryCtrl = TextEditingController(
        text: widget.material?.category ?? '');
    _descriptionCtrl = TextEditingController(
        text: widget.material?.description ?? '');
    _selectedUnit = widget.material?.unit ?? 'piece';
  }

  Future<void> _save() async {
    final s = widget.locale.s;

    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.required)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final quantity = widget.material?.quantity ?? 0;

      if (widget.material == null) {
        // Create new material
        await MaterialDao.instance.insert(
          WorkshopMaterial(
            name: _nameCtrl.text.trim(),
            category: _categoryCtrl.text.trim(),
            unit: _selectedUnit,
            quantity: quantity,
            description: _descriptionCtrl.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.materialRegistered)),
          );
        }
      } else {
        // Update existing material
        await MaterialDao.instance.update(
          widget.material!.copyWith(
            name: _nameCtrl.text.trim(),
            category: _categoryCtrl.text.trim(),
            unit: _selectedUnit,
            quantity: quantity,
            description: _descriptionCtrl.text.trim(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.materialUpdated)),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.locale.s;
    final isEditing = widget.material != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
            isEditing ? s.editMaterial : s.registerMaterial),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material Name
              Text(
                s.materialName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: s.enterItemName,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                s.materialCategory,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Tools, Parts, Chemicals',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Unit Dropdown
              Text(
                s.materialUnit,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _units
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedUnit = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                s.materialDescription,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.optional,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? s.saving : s.save,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }
}
