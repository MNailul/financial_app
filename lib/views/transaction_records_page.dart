import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/preference_service.dart';
import '../utils/formatters.dart';
import 'transaction_form_page.dart';

class TransactionRecordsPage extends StatefulWidget {
  final VoidCallback onDataChanged;

  const TransactionRecordsPage({super.key, required this.onDataChanged});

  @override
  State<TransactionRecordsPage> createState() => TransactionRecordsPageState();
}

class TransactionRecordsPageState extends State<TransactionRecordsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferenceService _prefService = PreferenceService();
  final TextEditingController _searchController = TextEditingController();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _filterType = 'all';
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = _prefService.currencySymbol;
    _searchController.addListener(_applyFilters);
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    _currency = _prefService.currencySymbol;
    await _loadTransactions(showLoading: false);
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final transactions = await _dbHelper.getAllTransactions();

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    final filtered = _transactions.where((tx) {
      final matchType = _filterType == 'all' || tx.type == _filterType;
      final matchSearch = tx.title.toLowerCase().contains(query) ||
          tx.categoryName.toLowerCase().contains(query) ||
          (tx.notes ?? '').toLowerCase().contains(query);

      return matchType && matchSearch;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _openTransactionForm([TransactionModel? transaction]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormPage(
          transaction: transaction,
          onSave: () {
            _loadTransactions(showLoading: false);
            widget.onDataChanged();
          },
        ),
      ),
    );

    await _loadTransactions(showLoading: false);
    widget.onDataChanged();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus Transaksi'),
        content: Text('Yakin ingin menghapus "${transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || transaction.id == null) return;

    await _dbHelper.deleteTransaction(transaction.id!);
    await _loadTransactions(showLoading: false);
    widget.onDataChanged();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan transaksi berhasil dihapus')),
    );
  }

  double get _totalIncome {
    return _filteredTransactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (total, tx) => total + tx.amount);
  }

  double get _totalExpense {
    return _filteredTransactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (total, tx) => total + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF118EEA);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openTransactionForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 12),
                  _buildSummaryHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  if (_filteredTransactions.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredTransactions.map(_buildTransactionCard),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF118EEA), Color(0xFF0056A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF118EEA).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Transaksi',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${_filteredTransactions.length} transaksi tercatat',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Pemasukan',
                  value: Formatters.formatCurrency(_totalIncome, _currency),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Pengeluaran',
                  value: Formatters.formatCurrency(_totalExpense, _currency),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari judul, kategori, atau catatan...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('Semua', 'all'),
        const SizedBox(width: 8),
        _buildFilterChip('Pemasukan', 'income'),
        const SizedBox(width: 8),
        _buildFilterChip('Pengeluaran', 'expense'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterType == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF118EEA),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() {
          _filterType = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final typeColor = isIncome ? const Color(0xFF00C853) : const Color(0xFFF43F5E);
    final categoryColor = Color(tx.categoryColorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTransactionForm(tx),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: categoryColor.withOpacity(0.12),
              child: Icon(
                IconData(tx.categoryIconCode, fontFamily: 'MaterialIcons'),
                color: categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.categoryName} - ${Formatters.formatDate(tx.date)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if ((tx.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      tx.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${Formatters.formatCurrency(tx.amount, _currency)}',
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteTransaction(tx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.grey[400], size: 56),
          const SizedBox(height: 12),
          const Text(
            'Belum ada catatan transaksi',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan pemasukan atau pengeluaran lewat tombol plus.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}