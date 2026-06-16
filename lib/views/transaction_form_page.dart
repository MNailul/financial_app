import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../services/database_helper.dart';
import '../services/preference_service.dart';
import '../utils/formatters.dart';
import 'category_management_page.dart';

class TransactionFormPage extends StatefulWidget {
  final TransactionModel? transaction;
  final VoidCallback onSave;

  const TransactionFormPage({super.key, this.transaction, required this.onSave});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferenceService _prefService = PreferenceService();
  final _formKey = GlobalKey<FormState>();

  late String _type; // 'expense' or 'income'
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  
  TransactionCategory? _selectedCategory;
  List<TransactionCategory> _categories = [];
  bool _isLoadingCategories = true;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = _prefService.currencySymbol;
    final tx = widget.transaction;

    _type = tx?.type ?? 'expense';
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(0) : '',
    );
    _titleController = TextEditingController(text: tx?.title ?? '');
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _selectedDate = tx?.date ?? DateTime.now();

    _loadCategoriesAndSelect();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndSelect() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final cats = await _dbHelper.getCategories(type: _type);
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
        
        // Try to select initial category
        if (widget.transaction != null && widget.transaction!.type == _type) {
          final matched = cats.where((c) => c.id == widget.transaction!.categoryId);
          if (matched.isNotEmpty) {
            _selectedCategory = matched.first;
          } else {
            _selectedCategory = cats.isNotEmpty ? cats.first : null;
          }
        } else {
          _selectedCategory = cats.isNotEmpty ? cats.first : null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        const primaryBlue = Color(0xFF2563EB);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
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
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih kategori transaksi')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transaksi yang valid')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    final newTx = TransactionModel(
      id: widget.transaction?.id,
      title: title,
      amount: amount,
      type: _type,
      categoryId: _selectedCategory!.id!,
      categoryName: _selectedCategory!.name,
      categoryIconCode: _selectedCategory!.iconCode,
      categoryColorValue: _selectedCategory!.colorValue,
      date: _selectedDate,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      if (widget.transaction == null) {
        await _dbHelper.insertTransaction(newTx);
      } else {
        await _dbHelper.updateTransaction(newTx);
      }
      widget.onSave();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction == null 
                  ? 'Transaksi berhasil ditambahkan' 
                  : 'Transaksi berhasil diperbarui',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          isEdit ? 'Ubah Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Transaction Type Toggle Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Expense Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_type != 'expense') {
                            setState(() {
                              _type = 'expense';
                              _selectedCategory = null;
                            });
                            _loadCategoriesAndSelect();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'expense' 
                                ? const Color(0xFFF43F5E) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: _type == 'expense' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Income Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_type != 'income') {
                            setState(() {
                              _type = 'income';
                              _selectedCategory = null;
                            });
                            _loadCategoriesAndSelect();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'income' 
                                ? const Color(0xFF00C853) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: _type == 'income' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Amount Input Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMINAL ${_type == 'expense' ? 'PENGELUARAN' : 'PEMASUKAN'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '$_currency ',
                        prefixStyle: const TextStyle(
                          color: primaryBlue,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: primaryBlue.withOpacity(0.3),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Harap masukkan nominal';
                        }
                        final amt = double.tryParse(val);
                        if (amt == null || amt <= 0) {
                          return 'Masukkan nominal yang valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Category Grid Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PILIH KATEGORI',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingCategories
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: primaryBlue),
                          ))
                        : _categories.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'Belum ada kategori ${_type == 'expense' ? 'pengeluaran' : 'pemasukan'}.\nSilakan tambahkan di menu Pengaturan.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final catColor = Color(cat.colorValue);
                                  final isSelected = _selectedCategory?.id == cat.id;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? catColor 
                                                : catColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.black87 : Colors.transparent,
                                              width: 2.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: catColor.withOpacity(0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    )
                                                  ]
                                                : [],
                                          ),
                                          child: Icon(
                                            IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                                            color: isSelected ? Colors.white : catColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          cat.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? Colors.black87 : Colors.grey[700],
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Details Fields Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Input
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Judul Transaksi',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryBlue),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Harap isi judul transaksi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Trigger
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Transaksi',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatDate(_selectedDate),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_rounded, color: primaryBlue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Input
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryBlue),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // extra padding for scrolling past the button
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ]
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _saveForm,
            child: Text(
              isEdit ? 'Perbarui Transaksi' : 'Simpan Transaksi',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
