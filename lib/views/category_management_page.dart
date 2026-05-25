import 'package:flutter/material.dart';
import '../models/transaction_category.dart';
import '../services/database_helper.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  
  List<TransactionCategory> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<IconData> _availableIcons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.directions_car,
    Icons.power,
    Icons.movie,
    Icons.medical_services,
    Icons.work,
    Icons.trending_up,
    Icons.card_giftcard,
    Icons.home,
    Icons.flight,
    Icons.school,
    Icons.sports_esports,
    Icons.phone_android,
    Icons.pets,
    Icons.fitness_center,
    Icons.brush,
    Icons.more_horiz,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF118EEA), // Blue
    const Color(0xFF00C853), // Green
    const Color(0xFFF43F5E), // Rose/Red
    const Color(0xFFFF9100), // Orange
    const Color(0xFFFFD600), // Yellow
    const Color(0xFFAA00FF), // Purple
    const Color(0xFFEC407A), // Pink
    const Color(0xFF00B8D4), // Cyan
    const Color(0xFF00B0FF), // Light Blue
    const Color(0xFF00E676), // Light Green
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final cats = await _dbHelper.getCategories();
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori: $e')),
      );
    }
  }

  List<TransactionCategory> _getFilteredCategories(String type) {
    return _categories.where((cat) {
      final matchesType = cat.type == type;
      final matchesSearch = cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();
  }

  void _showCategoryFormSheet([TransactionCategory? category]) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? (_tabController.index == 0 ? 'expense' : 'income');
    IconData selectedIcon = category != null 
        ? IconData(category.iconCode, fontFamily: 'MaterialIcons') 
        : _availableIcons.first;
    Color selectedColor = category != null 
        ? Color(category.colorValue) 
        : _availableColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Ubah Kategori' : 'Tambah Kategori',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetContext),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Segmented Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                type = 'expense';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'expense' 
                                    ? const Color(0xFFF43F5E).withOpacity(0.1) 
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: type == 'expense' 
                                      ? const Color(0xFFF43F5E) 
                                      : Colors.grey.shade200,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    color: type == 'expense' ? const Color(0xFFF43F5E) : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                type = 'income';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'income' 
                                    ? const Color(0xFF00C853).withOpacity(0.1) 
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: type == 'income' 
                                      ? const Color(0xFF00C853) 
                                      : Colors.grey.shade200,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    color: type == 'income' ? const Color(0xFF00C853) : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name Input
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori',
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
                    ),
                    const SizedBox(height: 20),

                    // Color Selector Title
                    const Text(
                      'Pilih Warna',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // Color Grid
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final color = _availableColors[index];
                          final isSelected = color.value == selectedColor.value;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedColor = color;
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
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon Selector Title
                    const Text(
                      'Pilih Ikon',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // Icon Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _availableIcons[index];
                        final isSelected = icon.codePoint == selectedIcon.codePoint;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? selectedColor.withOpacity(0.2) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? selectedColor : Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? selectedColor : Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF118EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                          );
                          return;
                        }

                        final newCat = TransactionCategory(
                          id: category?.id,
                          name: name,
                          iconCode: selectedIcon.codePoint,
                          colorValue: selectedColor.value,
                          type: type,
                        );

                        if (isEdit) {
                          // Update logic - wait, does DatabaseHelper have updateCategory?
                          // Let's check DatabaseHelper. It only has insert and delete.
                          // Wait, we need to add updateCategory in DatabaseHelper or update directly.
                          // Let's execute raw update or updateCategory. Let's see if we should write a helper method or do it directly.
                          // Let's check DatabaseHelper. Yes! We can write an updateCategory method or do database.update
                          final db = await _dbHelper.database;
                          await db.update(
                            'categories',
                            newCat.toMap(),
                            where: 'id = ?',
                            whereArgs: [category.id],
                          );
                        } else {
                          await _dbHelper.insertCategory(newCat);
                        }

                        Navigator.pop(sheetContext);
                        _loadCategories();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit 
                                  ? 'Kategori berhasil diperbarui' 
                                  : 'Kategori baru berhasil ditambahkan'
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Buat Kategori',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(TransactionCategory category) async {
    // Show warning because delete uses cascade or might delete transactions
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus Kategori', style: TextStyle(color: Colors.black87)),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?\n\nPERINGATAN: Semua transaksi yang menggunakan kategori ini juga akan terhapus!',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteCategory(category.id!);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus kategori: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF118EEA)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF118EEA)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTabList('expense'),
                      _buildCategoryTabList('income'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF118EEA),
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryFormSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryTabList(String type) {
    final filteredList = _getFilteredCategories(type);

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada kategori ${type == 'expense' ? 'pengeluaran' : 'pemasukan'}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 88, top: 8),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cat = filteredList[index];
        final catColor = Color(cat.colorValue);

        return Container(
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                color: catColor,
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              cat.type == 'expense' ? 'Pengeluaran' : 'Pemasukan',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF118EEA), size: 22),
                  onPressed: () => _showCategoryFormSheet(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  onPressed: () => _deleteCategory(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
