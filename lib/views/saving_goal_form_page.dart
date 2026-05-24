import 'package:flutter/material.dart';
import '../models/saving_goal.dart';
import '../services/database_helper.dart';
import '../services/preference_service.dart';
import '../utils/formatters.dart';

class SavingGoalFormPage extends StatefulWidget {
  final SavingGoal? goal;
  final VoidCallback onSave;

  const SavingGoalFormPage({super.key, this.goal, required this.onSave});

  @override
  State<SavingGoalFormPage> createState() => _SavingGoalFormPageState();
}

class _SavingGoalFormPageState extends State<SavingGoalFormPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferenceService _prefService = PreferenceService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late Color _selectedColor;

  final List<String> _categories = [
    'Gadget',
    'Travel',
    'Pendidikan',
    'Kendaraan',
    'Investasi',
    'Darurat',
    'Lainnya'
  ];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.teal,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetAmountController = TextEditingController(
      text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '',
    );
    _currentAmountController = TextEditingController(
      text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '0',
    );
    _selectedDate = goal?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    _selectedCategory = goal?.category ?? _categories.first;
    _selectedColor = goal != null ? Color(goal.colorValue) : _availableColors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF118EEA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final target = double.parse(_targetAmountController.text);
    final current = double.parse(_currentAmountController.text);

    if (current > target) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabungan awal tidak boleh melebihi target tabungan')),
      );
      return;
    }

    final newGoal = SavingGoal(
      id: widget.goal?.id,
      title: title,
      targetAmount: target,
      currentAmount: current,
      targetDate: _selectedDate,
      category: _selectedCategory,
      colorValue: _selectedColor.value,
      status: current >= target ? 'completed' : (widget.goal?.status ?? 'active'),
    );

    if (widget.goal == null) {
      await _dbHelper.insertSavingGoal(newGoal);
    } else {
      await _dbHelper.updateSavingGoal(newGoal);
    }

    widget.onSave();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.goal == null ? 'Target tabungan berhasil ditambahkan' : 'Target tabungan berhasil diperbarui',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = _prefService.currencySymbol;
    final isEdit = widget.goal != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Target Tabungan' : 'Tambah Target Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nama Target (misal: Beli PS5)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF118EEA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama target tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Amount Field
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Jumlah Target Tabungan',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixText: '$currency ',
                  prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF118EEA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Jumlah target tidak boleh kosong';
                  }
                  final amt = double.tryParse(val);
                  if (amt == null || amt <= 0) {
                    return 'Masukkan jumlah target yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Current Amount Field (Only active if not edit, or just always open)
              TextFormField(
                controller: _currentAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Tabungan Awal Terkumpul',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixText: '$currency ',
                  prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF118EEA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Tabungan awal tidak boleh kosong (isi 0 jika baru mulai)';
                  }
                  final amt = double.tryParse(val);
                  if (amt == null || amt < 0) {
                    return 'Masukkan jumlah tabungan awal yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF118EEA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Date Picker Card
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tenggat Waktu Target',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatDate(_selectedDate),
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Color Selector
              const Text(
                'Warna Tema Target',
                style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = color.value == _selectedColor.value;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black87 : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF118EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveForm,
                child: Text(
                  isEdit ? 'Perbarui Target' : 'Buat Target Sekarang',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
