import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'monthly_report_page.dart';
import 'saving_goals_page.dart';
import 'settings_page.dart';
import '../services/preference_service.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  final PreferenceService _prefService = PreferenceService();
  int _currentIndex = 0;
  bool _isLocked = false;
  String _enteredPin = '';

  final GlobalKey<DashboardPageState> _dashboardKey = GlobalKey();
  final GlobalKey<MonthlyReportPageState> _reportKey = GlobalKey();
  final GlobalKey<SavingGoalsPageState> _goalsKey = GlobalKey();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkPinLock();
    _pages = [
      DashboardPage(key: _dashboardKey, onDataChanged: _syncState),
      MonthlyReportPage(key: _reportKey, onDataChanged: _syncState),
      SavingGoalsPage(key: _goalsKey, onDataChanged: _syncState),
      SettingsPage(onSettingsChanged: _syncState),
    ];
  }

  void _checkPinLock() {
    if (_prefService.isPinSet && _prefService.savedPin.isNotEmpty) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  void _syncState() {
    _dashboardKey.currentState?.reload();
    _reportKey.currentState?.reload();
    _goalsKey.currentState?.reload();
    setState(() {});
  }

  void _handlePinInput(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });
    }

    if (_enteredPin.length == 4) {
      if (_enteredPin == _prefService.savedPin) {
        setState(() {
          _isLocked = false;
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akses diterima. Selamat datang!'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        setState(() {
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN Salah! Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _handlePinDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF118EEA), size: 64),
              const SizedBox(height: 24),
              const Text(
                'Aplikasi Finansial Terkunci',
                style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan PIN 4 angka Anda',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 36),
              // Dots representing entered pin
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isFilled ? const Color(0xFF118EEA) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF118EEA), width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              // Numpad Keypad
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        // Empty space or clear
                        return const SizedBox();
                      }
                      if (index == 10) {
                        // Digit '0'
                        return _buildNumButton('0');
                      }
                      if (index == 11) {
                        // Delete Button
                        return InkWell(
                          onTap: _handlePinDelete,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: Center(
                              child: Icon(Icons.backspace_outlined, color: Colors.grey[700]),
                            ),
                          ),
                        );
                      }

                      // Digits 1-9
                      final digit = (index + 1).toString();
                      return _buildNumButton(digit);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pages = _pages;

    final pageTitles = [
      'Dashboard Grafik',
      'Laporan Bulanan',
      'Target Tabungan',
      'Pengaturan & Preferensi'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (_prefService.isPinSet)
            IconButton(
              icon: const Icon(Icons.lock_reset, color: Colors.white),
              tooltip: 'Kunci Aplikasi',
              onPressed: () {
                setState(() {
                  _isLocked = true;
                  _enteredPin = '';
                });
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) _dashboardKey.currentState?.reload();
            if (index == 1) _reportKey.currentState?.reload();
            if (index == 2) _goalsKey.currentState?.reload();
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF118EEA),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Grafik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined),
              activeIcon: Icon(Icons.savings),
              label: 'Target',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumButton(String text) {
    return InkWell(
      onTap: () => _handlePinInput(text),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
