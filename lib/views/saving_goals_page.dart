import 'package:flutter/material.dart';
import '../models/saving_goal.dart';
import '../services/database_helper.dart';
import '../services/preference_service.dart';
import '../utils/formatters.dart';
import 'saving_goal_form_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SavingGoalsPage extends StatefulWidget {
  final VoidCallback onDataChanged;
  const SavingGoalsPage({super.key, required this.onDataChanged});

  @override
  State<SavingGoalsPage> createState() => SavingGoalsPageState();
}

class SavingGoalsPageState extends State<SavingGoalsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferenceService _prefService = PreferenceService();

  List<SavingGoal> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalTarget = 0.0;
  double _totalSaved = 0.0;

  // Preferences
  late String _currency;
  late bool _hideBalance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadGoals();
  }

  void _loadPreferences() {
    _currency = _prefService.currencySymbol;
    _hideBalance = _prefService.hideBalance;
  }

  Future<void> reload() async {
    _loadPreferences();
    await _loadGoals(showLoading: false);
  }

  Future<void> _loadGoals({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final goals = await _dbHelper.getAllSavingGoals();

      double totalTar = 0.0;
      double totalSav = 0.0;

      for (var g in goals) {
        if (g.status == 'active') {
          totalTar += g.targetAmount;
          totalSav += g.currentAmount;
        }
      }

      if (mounted) {
        setState(() {
          _goals = goals;
          _totalTarget = totalTar;
          _totalSaved = totalSav;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading goals: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGoal(int id) async {
    await _dbHelper.deleteSavingGoal(id);
    _loadGoals();
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target tabungan berhasil dihapus')),
      );
    }
  }

  void _showTopUpDialog(SavingGoal goal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tabung untuk: ${goal.title}',
            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sisa target: ${Formatters.formatCurrency(goal.targetAmount - goal.currentAmount, _currency)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nominal Tabungan',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixText: '$_currency ',
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
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF118EEA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final amt = double.tryParse(amountController.text);
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan nominal yang valid')),
                  );
                  return;
                }

                // Add funds to saving goal in DB
                await _dbHelper.addFundsToSavingGoal(goal.id!, amt);
                
                // Track this as an expense? The user request mentions:
                // "Penyimpanan SQLite: Data transaksi (pemasukan/pengeluaran), kategori transaksi, dan target tabungan (saving goals)."
                // Usually savings can be backed by a transaction or just directly tracked. Let's just track it directly in saving goals.
                // We could also auto-generate a transaction (e.g. Expense to Saving) if desired, but direct is fine.
                
                Navigator.pop(dialogCtx);
                _loadGoals();
                widget.onDataChanged();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Berhasil menabung ${Formatters.formatCurrency(amt, _currency)}')),
                  );
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = _totalTarget > 0 ? _totalSaved / _totalTarget : 0.0;

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
                  'Gagal memuat target tabungan',
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
                  onPressed: () => _loadGoals(),
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
      body: RefreshIndicator(
        onRefresh: _loadGoals,
              color: const Color(0xFF118EEA),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Summary Banner of Saving Goals
                    Container(
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
                            color: const Color(0xFF118EEA).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Akumulasi Target Tabungan Aktif',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _hideBalance ? '••••••' : Formatters.formatCurrency(_totalSaved, _currency),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'dari ${_hideBalance ? '••••••' : Formatters.formatCurrency(_totalTarget, _currency)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: overallProgress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: Colors.white,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(overallProgress * 100).toStringAsFixed(0)}% Tercapai',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),

                    // List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Target Tabungan',
                          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF118EEA).withOpacity(0.1),
                            foregroundColor: const Color(0xFF118EEA),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFF118EEA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SavingGoalFormPage(
                                  onSave: () {
                                    _loadGoals();
                                    widget.onDataChanged();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Buat Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_goals.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada target tabungan yang dibuat',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _goals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          final color = Color(goal.colorValue);
                          final progress = goal.progressPercentage;
                          final isDone = goal.isCompleted;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDone ? Colors.green.shade200 : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Category & Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          goal.category,
                                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (isDone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'SELESAI',
                                            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else
                                        Text(
                                          'Hingga: ${Formatters.formatDate(goal.targetDate)}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Title
                                  Text(
                                    goal.title,
                                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  // Stats text
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Terkumpul: ${Formatters.formatCurrency(goal.currentAmount, _currency)}',
                                        style: TextStyle(color: isDone ? Colors.green : Colors.grey[600], fontSize: 12),
                                      ),
                                      Text(
                                        'Target: ${Formatters.formatCurrency(goal.targetAmount, _currency)}',
                                        style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.shade200,
                                      color: isDone ? Colors.green : color,
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${(progress * 100).toStringAsFixed(0)}% Tercapai',
                                      style: TextStyle(color: isDone ? Colors.green : Colors.grey[600], fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey.shade200),
                                  // Actions row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogCtx) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text('Hapus Target', style: TextStyle(color: Colors.black87)),
                                              content: Text(
                                                'Apakah Anda yakin ingin menghapus target tabungan ini?',
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
                                                    _deleteGoal(goal.id!);
                                                  },
                                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF118EEA), size: 22),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SavingGoalFormPage(
                                                goal: goal,
                                                onSave: () {
                                                  _loadGoals();
                                                  widget.onDataChanged();
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isDone)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF118EEA),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _showTopUpDialog(goal),
                                          icon: const Icon(Icons.savings, size: 16),
                                          label: const Text('Tabung', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
