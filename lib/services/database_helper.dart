import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_category.dart';
import '../models/transaction.dart';
import '../models/saving_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('financial_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Reset database to remove mock data
    await deleteDatabase(path);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );

    // Validate table existence
    await _checkAndRecreateTables(db);

    return db;
  }

  Future<void> _checkAndRecreateTables(Database db) async {
    final tables = ['categories', 'transactions', 'saving_goals'];
    bool needsRecreate = false;
    for (var table in tables) {
      try {
        final res = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (res.isEmpty) {
          needsRecreate = true;
          break;
        }
      } catch (e) {
        needsRecreate = true;
        break;
      }
    }

    if (needsRecreate) {
      debugPrint("Database Helper: Tables missing. Recreating database...");
      await db.execute("DROP TABLE IF EXISTS transactions");
      await db.execute("DROP TABLE IF EXISTS categories");
      await db.execute("DROP TABLE IF EXISTS saving_goals");
      await _createDB(db, 1);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // 2. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        category_icon_code INTEGER NOT NULL,
        category_color_value INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Saving Goals Table
    await db.execute('''
      CREATE TABLE saving_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        target_date TEXT NOT NULL,
        category TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
    // Seed mock data
    // await _seedMockData(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final List<TransactionCategory> defaultCats = [
      // Incomes
      TransactionCategory(name: 'Gaji', iconCode: Icons.work.codePoint, colorValue: Colors.blue.value, type: 'income'),
      TransactionCategory(name: 'Investasi', iconCode: Icons.trending_up.codePoint, colorValue: Colors.green.value, type: 'income'),
      TransactionCategory(name: 'Hadiah', iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.pink.value, type: 'income'),
      TransactionCategory(name: 'Lain-lain (Masuk)', iconCode: Icons.more_horiz.codePoint, colorValue: Colors.grey.value, type: 'income'),
      
      // Expenses
      TransactionCategory(name: 'Makanan', iconCode: Icons.restaurant.codePoint, colorValue: Colors.orange.value, type: 'expense'),
      TransactionCategory(name: 'Belanja', iconCode: Icons.shopping_bag.codePoint, colorValue: Colors.red.value, type: 'expense'),
      TransactionCategory(name: 'Transportasi', iconCode: Icons.directions_car.codePoint, colorValue: Colors.teal.value, type: 'expense'),
      TransactionCategory(name: 'Tagihan', iconCode: Icons.power.codePoint, colorValue: Colors.amber.value, type: 'expense'),
      TransactionCategory(name: 'Hiburan', iconCode: Icons.movie.codePoint, colorValue: Colors.purple.value, type: 'expense'),
      TransactionCategory(name: 'Kesehatan', iconCode: Icons.medical_services.codePoint, colorValue: Colors.lightGreen.value, type: 'expense'),
      TransactionCategory(name: 'Lain-lain (Keluar)', iconCode: Icons.more_horiz.codePoint, colorValue: Colors.blueGrey.value, type: 'expense'),
    ];

    for (var cat in defaultCats) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future<void> _seedMockData(Database db) async {
    final now = DateTime.now();

    // Query categories to get their IDs
    final List<Map<String, dynamic>> maps = await db.query('categories');
    final categories = maps.map((m) => TransactionCategory.fromMap(m)).toList();

    final gajiCat = categories.firstWhere((c) => c.name == 'Gaji');
    final investasiCat = categories.firstWhere((c) => c.name == 'Investasi');
    final makananCat = categories.firstWhere((c) => c.name == 'Makanan');
    final belanjaCat = categories.firstWhere((c) => c.name == 'Belanja');
    final tagihanCat = categories.firstWhere((c) => c.name == 'Tagihan');
    final hiburanCat = categories.firstWhere((c) => c.name == 'Hiburan');
    final transportCat = categories.firstWhere((c) => c.name == 'Transportasi');

    // Seed Transactions
    final List<TransactionModel> mockTransactions = [
      // Current Month
      TransactionModel(
        title: 'Gaji Bulanan',
        amount: 12500000.0,
        type: 'income',
        categoryId: gajiCat.id!,
        categoryName: gajiCat.name,
        categoryIconCode: gajiCat.iconCode,
        categoryColorValue: gajiCat.colorValue,
        date: DateTime(now.year, now.month, 1),
        notes: 'Gaji pokok bulanan',
      ),
      TransactionModel(
        title: 'Dividen Reksa Dana',
        amount: 850000.0,
        type: 'income',
        categoryId: investasiCat.id!,
        categoryName: investasiCat.name,
        categoryIconCode: investasiCat.iconCode,
        categoryColorValue: investasiCat.colorValue,
        date: DateTime(now.year, now.month, 10),
        notes: 'Investasi Bibit',
      ),
      TransactionModel(
        title: 'Makan Siang Steak',
        amount: 250000.0,
        type: 'expense',
        categoryId: makananCat.id!,
        categoryName: makananCat.name,
        categoryIconCode: makananCat.iconCode,
        categoryColorValue: makananCat.colorValue,
        date: DateTime(now.year, now.month, 2),
        notes: 'Bareng temen kantor',
      ),
      TransactionModel(
        title: 'Belanja Bulanan',
        amount: 1200000.0,
        type: 'expense',
        categoryId: belanjaCat.id!,
        categoryName: belanjaCat.name,
        categoryIconCode: belanjaCat.iconCode,
        categoryColorValue: belanjaCat.colorValue,
        date: DateTime(now.year, now.month, 3),
        notes: 'Beli di Supermarket',
      ),
      TransactionModel(
        title: 'Bayar Listrik & Wifi',
        amount: 650000.0,
        type: 'expense',
        categoryId: tagihanCat.id!,
        categoryName: tagihanCat.name,
        categoryIconCode: tagihanCat.iconCode,
        categoryColorValue: tagihanCat.colorValue,
        date: DateTime(now.year, now.month, 5),
        notes: 'Tagihan PLN & Indihome',
      ),
      TransactionModel(
        title: 'Beli Tiket Bioskop',
        amount: 120000.0,
        type: 'expense',
        categoryId: hiburanCat.id!,
        categoryName: hiburanCat.name,
        categoryIconCode: hiburanCat.iconCode,
        categoryColorValue: hiburanCat.colorValue,
        date: DateTime(now.year, now.month, 8),
        notes: 'Nonton film terbaru',
      ),
      TransactionModel(
        title: 'Bensin & Tol',
        amount: 350000.0,
        type: 'expense',
        categoryId: transportCat.id!,
        categoryName: transportCat.name,
        categoryIconCode: transportCat.iconCode,
        categoryColorValue: transportCat.colorValue,
        date: DateTime(now.year, now.month, 7),
        notes: 'Bensin mingguan',
      ),
      TransactionModel(
        title: 'GoFood Kopi',
        amount: 75000.0,
        type: 'expense',
        categoryId: makananCat.id!,
        categoryName: makananCat.name,
        categoryIconCode: makananCat.iconCode,
        categoryColorValue: makananCat.colorValue,
        date: DateTime(now.year, now.month, 12),
        notes: 'Kopi sore',
      ),

      // Previous Month (for comparisons & reports)
      TransactionModel(
        title: 'Gaji Bulanan Lalu',
        amount: 12500000.0,
        type: 'income',
        categoryId: gajiCat.id!,
        categoryName: gajiCat.name,
        categoryIconCode: gajiCat.iconCode,
        categoryColorValue: gajiCat.colorValue,
        date: DateTime(now.year, now.month - 1, 1),
      ),
      TransactionModel(
        title: 'Belanja Baju',
        amount: 950000.0,
        type: 'expense',
        categoryId: belanjaCat.id!,
        categoryName: belanjaCat.name,
        categoryIconCode: belanjaCat.iconCode,
        categoryColorValue: belanjaCat.colorValue,
        date: DateTime(now.year, now.month - 1, 15),
      ),
      TransactionModel(
        title: 'Makan Malam Restaurant',
        amount: 450000.0,
        type: 'expense',
        categoryId: makananCat.id!,
        categoryName: makananCat.name,
        categoryIconCode: makananCat.iconCode,
        categoryColorValue: makananCat.colorValue,
        date: DateTime(now.year, now.month - 1, 20),
      ),
    ];

    for (var tx in mockTransactions) {
      await db.insert('transactions', tx.toMap());
    }

    // Seed Saving Goals
    final List<SavingGoal> mockGoals = [
      SavingGoal(
        title: 'Beli Macbook Pro M3',
        targetAmount: 28000000.0,
        currentAmount: 14500000.0,
        targetDate: DateTime(now.year + 1, 1, 1),
        category: 'Gadget',
        colorValue: Colors.blue.value,
      ),
      SavingGoal(
        title: 'Liburan ke Jepang',
        targetAmount: 20000000.0,
        currentAmount: 8000000.0,
        targetDate: DateTime(now.year, now.month + 6, 15),
        category: 'Travel',
        colorValue: Colors.purple.value,
      ),
      SavingGoal(
        title: 'Dana Darurat 6 Bulan',
        targetAmount: 30000000.0,
        currentAmount: 18000000.0,
        targetDate: DateTime(now.year, now.month + 10, 1),
        category: 'Lainnya',
        colorValue: Colors.teal.value,
      ),
      SavingGoal(
        title: 'Investasi Emas',
        targetAmount: 5000000.0,
        currentAmount: 5000000.0, // Completed goal
        targetDate: DateTime(now.year, now.month - 1, 25),
        category: 'Investasi',
        colorValue: Colors.amber.value,
        status: 'completed',
      ),
    ];

    for (var goal in mockGoals) {
      await db.insert('saving_goals', goal.toMap());
    }
  }

  // --- CATEGORIES CRUD ---
  Future<int> insertCategory(TransactionCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<TransactionCategory>> getCategories({String? type}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = type != null
        ? await db.query('categories', where: 'type = ?', whereArgs: [type])
        : await db.query('categories');

    return maps.map((m) => TransactionCategory.fromMap(m)).toList();
  }

  Future<TransactionCategory?> getCategoryById(int id) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return TransactionCategory.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- TRANSACTIONS CRUD ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    final db = await instance.database;
    // Format dates as YYYY-MM
    final monthStr = month.toString().padLeft(2, '0');
    final queryStr = '$year-$monthStr%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: [queryStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- SAVING GOALS CRUD ---
  Future<int> insertSavingGoal(SavingGoal goal) async {
    final db = await instance.database;
    return await db.insert('saving_goals', goal.toMap());
  }

  Future<List<SavingGoal>> getAllSavingGoals() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('saving_goals', orderBy: 'status ASC, target_date ASC');
    return maps.map((m) => SavingGoal.fromMap(m)).toList();
  }

  Future<int> updateSavingGoal(SavingGoal goal) async {
    final db = await instance.database;
    return await db.update(
      'saving_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingGoal(int id) async {
    final db = await instance.database;
    return await db.delete('saving_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addFundsToSavingGoal(int id, double amount) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('saving_goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final goal = SavingGoal.fromMap(maps.first);
      final newCurrent = goal.currentAmount + amount;
      final newStatus = newCurrent >= goal.targetAmount ? 'completed' : goal.status;
      
      await db.update(
        'saving_goals',
        {
          'current_amount': newCurrent,
          'status': newStatus,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
