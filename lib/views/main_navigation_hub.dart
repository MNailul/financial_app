import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'monthly_report_page.dart';
import 'saving_goals_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'transaction_records_page.dart';
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
  final GlobalKey<TransactionRecordsPageState> _recordsKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkPinLock();
    _pages = [
      DashboardPage(key: _dashboardKey, onDataChanged: _syncState),
      MonthlyReportPage(key: _reportKey, onDataChanged: _syncState),
      SavingGoalsPage(key: _goalsKey, onDataChanged: _syncState),
      TransactionRecordsPage(key: _recordsKey, onDataChanged: _syncState),
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
    _recordsKey.currentState?.reload();
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
            content: Text('PIN salah. Silakan coba lagi.'),
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
                        return const SizedBox();
                      }

                      if (index == 10) {
                        return _buildNumButton('0');
                      }

                      if (index == 11) {
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

    final pageTitles = [
      'Dashboard Grafik',
      'Laporan Bulanan',
      'Target Tabungan',
      'Catatan Transaksi',
    ];

    return Scaffold(
      extendBody: true, // Needed for floating bottom nav
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        ),
        actions: [
          if (_prefService.isPinSet)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: IconButton(
                icon: const Icon(Icons.lock_reset, color: Color(0xFF1F2937)),
                tooltip: 'Kunci Aplikasi',
                onPressed: () {
                  setState(() {
                    _isLocked = true;
                    _enteredPin = '';
                  });
                },
              ),
            ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF2563EB), size: 40),
              ),
              accountName: const Text('Pengguna Finansial', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('user@ppbl.com'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF2563EB)),
              title: const Text('Dashboard Utama'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF2563EB)),
              title: const Text('Keamanan & Setelan'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage(onSettingsChanged: _syncState)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
              title: const Text('Profil Pengguna'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });

                if (index == 0) _dashboardKey.currentState?.reload();
                if (index == 1) _reportKey.currentState?.reload();
                if (index == 2) _goalsKey.currentState?.reload();
                if (index == 3) _recordsKey.currentState?.reload();
              },
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: const Color(0xFF9CA3AF),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined, size: 26),
                  activeIcon: Icon(Icons.analytics, size: 28),
                  label: 'Grafik',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined, size: 26),
                  activeIcon: Icon(Icons.calendar_today, size: 28),
                  label: 'Laporan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.savings_outlined, size: 26),
                  activeIcon: Icon(Icons.savings, size: 28),
                  label: 'Target',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined, size: 26),
                  activeIcon: Icon(Icons.receipt_long, size: 28),
                  label: 'Catatan',
                ),
              ],
            ),
          ),
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
            ),
          ],
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