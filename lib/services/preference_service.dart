import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static SharedPreferences? _prefs;

  // Singleton pattern
  static final PreferenceService _instance = PreferenceService._internal();
  factory PreferenceService() => _instance;
  PreferenceService._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Helper method to ensure initialization
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception("PreferenceService not initialized. Call init() first.");
    }
    return _prefs!;
  }

  // 1. Currency Symbol (Simbol mata uang, misal: Rp atau $)
  String get currencySymbol => prefs.getString('currency_symbol') ?? 'Rp';
  Future<void> setCurrencySymbol(String value) async {
    await prefs.setString('currency_symbol', value);
  }

  // 2. Hide Balance (Boolean untuk menyembunyikan nominal saldo di dashboard)
  bool get hideBalance => prefs.getBool('hide_balance') ?? false;
  Future<void> setHideBalance(bool value) async {
    await prefs.setBool('hide_balance', value);
  }

  // 3. Monthly Budget Limit (Batas maksimal belanja bulanan)
  double get monthlyBudgetLimit => prefs.getDouble('monthly_budget_limit') ?? 5000000.0;
  Future<void> setMonthlyBudgetLimit(double value) async {
    await prefs.setDouble('monthly_budget_limit', value);
  }

  // 4. Is PIN Set (Apakah user mengaktifkan PIN aplikasi)
  bool get isPinSet => prefs.getBool('is_pin_set') ?? false;
  Future<void> setIsPinSet(bool value) async {
    await prefs.setBool('is_pin_set', value);
  }

  // 5. Saved PIN (Menyimpan string PIN terenkripsi/plain untuk demo)
  String get savedPin => prefs.getString('saved_pin') ?? '';
  Future<void> setSavedPin(String value) async {
    await prefs.setString('saved_pin', value);
  }

  // 6. Sync To Cloud (Status auto-sync)
  bool get syncToCloud => prefs.getBool('sync_to_cloud') ?? false;
  Future<void> setSyncToCloud(bool value) async {
    await prefs.setBool('sync_to_cloud', value);
  }

  // 7. Financial Tips Seen (Agar popup tips tidak muncul terus-menerus)
  bool get financialTipsSeen => prefs.getBool('financial_tips_seen') ?? false;
  Future<void> setFinancialTipsSeen(bool value) async {
    await prefs.setBool('financial_tips_seen', value);
  }

  // 8. Default Account View (Halaman awal default saat dibuka: Dompet Utama atau Kartu Kredit)
  String get defaultAccountView => prefs.getString('default_account_view') ?? 'Dompet Utama';
  Future<void> setDefaultAccountView(String value) async {
    await prefs.setString('default_account_view', value);
  }
}
