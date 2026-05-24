import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/preference_service.dart';
import '../utils/formatters.dart';

class MonthlyReportPage extends StatefulWidget {
  final VoidCallback onDataChanged;
  const MonthlyReportPage({super.key, required this.onDataChanged});

  @override
  State<MonthlyReportPage> createState() => MonthlyReportPageState();
}

class MonthlyReportPageState extends State<MonthlyReportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferenceService _prefService = PreferenceService();

  DateTime _selectedDate = DateTime.now();
  List<TransactionModel> _monthlyTransactions = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  Map<String, double> _categoryExpenses = {};
  Map<String, int> _categoryColors = {};
  Map<String, int> _categoryIcons = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Preferences
  late String _currency;
  late bool _hideBalance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadMonthlyData();
  }

  void _loadPreferences() {
    _currency = _prefService.currencySymbol;
    _hideBalance = _prefService.hideBalance;
  }

  Future<void> reload() async {
    _loadPreferences();
    await _loadMonthlyData(showLoading: false);
  }

  Future<void> _loadMonthlyData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final transactions = await _dbHelper.getTransactionsByMonth(
        _selectedDate.year,
        _selectedDate.month,
      );

      double income = 0.0;
      double expense = 0.0;
      final Map<String, double> catExpenses = {};
      final Map<String, int> catColors = {};
      final Map<String, int> catIcons = {};

      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else {
          expense += tx.amount;
          catExpenses[tx.categoryName] = (catExpenses[tx.categoryName] ?? 0.0) + tx.amount;
          catColors[tx.categoryName] = tx.categoryColorValue;
          catIcons[tx.categoryName] = tx.categoryIconCode;
        }
      }

      if (mounted) {
        setState(() {
          _monthlyTransactions = transactions;
          _totalIncome = income;
          _totalExpense = expense;
          _categoryExpenses = catExpenses;
          _categoryColors = catColors;
          _categoryIcons = catIcons;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading monthly report: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    });
    _loadMonthlyData();
  }

  Future<void> _deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    _loadMonthlyData();
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final netSavings = _totalIncome - _totalExpense;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF118EEA)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat laporan bulanan',
                  style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadMonthlyData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF118EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month Picker Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black87),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        Formatters.formatMonthYear(_selectedDate),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.black87),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Overview grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pemasukan',
                          amount: _totalIncome,
                          color: const Color(0xFF10B981),
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pengeluaran',
                          amount: _totalExpense,
                          color: const Color(0xFFF43F5E),
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSavingsCard(netSavings),
                  const SizedBox(height: 24),

                  // Charts Section
                  const Text(
                    'Kategori Pengeluaran',
                    style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_categoryExpenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Tidak ada pengeluaran di bulan ini',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else ...[
                    // Pie Chart Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: _getPieChartSections(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Custom Legends
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _categoryExpenses.keys.map((catName) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(_categoryColors[catName]!),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    catName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Breakdown List
                    const Text(
                      'Rincian per Kategori',
                      style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categoryExpenses.length,
                      itemBuilder: (context, index) {
                        final catName = _categoryExpenses.keys.elementAt(index);
                        final amount = _categoryExpenses[catName]!;
                        final color = Color(_categoryColors[catName]!);
                        final iconCode = _categoryIcons[catName]!;
                        final percent = _totalExpense > 0 ? (amount / _totalExpense) * 100 : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      IconData(iconCode, fontFamily: 'MaterialIcons'),
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(amount, _currency),
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent / 100,
                                        backgroundColor: Colors.grey.shade200,
                                        color: color,
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${percent.toStringAsFixed(1)}%',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Transaction List for the Month
                  const Text(
                    'Riwayat Transaksi Bulan Ini',
                    style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_monthlyTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi bulan ini',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _monthlyTransactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = _monthlyTransactions[index];
                        final isExpense = tx.type == 'expense';
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
                            ]
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(tx.categoryColorValue).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconData(tx.categoryIconCode, fontFamily: 'MaterialIcons'),
                                color: Color(tx.categoryColorValue),
                              ),
                            ),
                            title: Text(
                              tx.title,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tx.categoryName} • ${Formatters.formatDate(tx.date)}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                if (tx.notes != null)
                                  Text(
                                    tx.notes!,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isExpense ? "-" : "+"}${Formatters.formatCurrency(tx.amount, _currency)}',
                                  style: TextStyle(
                                    color: isExpense ? Colors.red : const Color(0xFF00C853),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text('Hapus Transaksi', style: TextStyle(color: Colors.black87)),
                                        content: Text(
                                          'Apakah Anda yakin ingin menghapus transaksi ini?',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogCtx),
                                            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogCtx);
                                              _deleteTransaction(tx.id!);
                                            },
                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hideBalance ? '••••••' : Formatters.formatCurrency(amount, _currency),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(double netSavings) {
    final isNegative = netSavings < 0;
    final displayColor = isNegative ? const Color(0xFFF43F5E) : const Color(0xFF118EEA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: displayColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNegative ? Icons.trending_down : Icons.savings,
                  color: displayColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tabungan Bersih',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  Text(
                    isNegative ? 'Defisit Bulan Ini' : 'Sisa Tabungan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Text(
            _hideBalance ? '••••••' : Formatters.formatCurrency(netSavings, _currency),
            style: TextStyle(
              color: displayColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    int index = 0;
    return _categoryExpenses.entries.map((entry) {
      final catName = entry.key;
      final amount = entry.value;
      final color = Color(_categoryColors[catName]!);
      final percent = _totalExpense > 0 ? (amount / _totalExpense) * 100 : 0.0;

      final isTouched = index == 0; // Simple highlight first item
      final double radius = isTouched ? 55 : 50;

      index++;
      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percent.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
