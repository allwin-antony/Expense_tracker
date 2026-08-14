import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment.dart';

class FilteredSummaryMetrics {
  final double totalExpense;
  final double totalIncome;
  final int totalCount;

  FilteredSummaryMetrics({
    required this.totalExpense,
    required this.totalIncome,
    required this.totalCount,
  });
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _database;

  /// Global notifier for reactive cross-screen synchronization
  final ValueNotifier<int> dataChangeNotifier = ValueNotifier<int>(0);

  DatabaseService._constructor();

  void notifyDataChanged() {
    dataChangeNotifier.value++;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, 'budget_tracker.db');

    return await openDatabase(
      databasePath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE payments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL DEFAULT 'debit',
            category TEXT NOT NULL,
            paymentMode TEXT NOT NULL DEFAULT 'upi',
            source TEXT NOT NULL DEFAULT 'manual',
            accountReference TEXT,
            rawMessage TEXT,
            confidence REAL,
            date TEXT NOT NULL,
            notes TEXT,
            isExcluded INTEGER NOT NULL DEFAULT 0,
            budgetMonth TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN type TEXT NOT NULL DEFAULT 'debit'");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN paymentMode TEXT NOT NULL DEFAULT 'upi'");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN source TEXT NOT NULL DEFAULT 'manual'");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN accountReference TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN rawMessage TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN confidence REAL");
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN isExcluded INTEGER NOT NULL DEFAULT 0");
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute("ALTER TABLE payments ADD COLUMN budgetMonth TEXT");
          } catch (_) {}
        }
      },
    );
  }

  Future<int> addPayment(Payment payment) async {
    final db = await database;
    final id = await db.insert('payments', payment.toMap());
    notifyDataChanged();
    return id;
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final data = await db.query('payments', orderBy: 'date DESC');
    return data.map((e) => Payment.fromMap(e)).toList();
  }

  /// Paginated query — loads a page of records ordered by date descending
  Future<List<Payment>> getPaymentsPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final data = await db.query(
      'payments',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return data.map((e) => Payment.fromMap(e)).toList();
  }

  /// Advanced paginated query with SQL-level filtering for ultra-fast history loading
  Future<List<Payment>> getFilteredPaymentsPaginated({
    int limit = 25,
    int offset = 0,
    String? searchQuery,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(description LIKE ? OR accountReference LIKE ? OR notes LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    if (category != null && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final String? where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final data = await db.query(
      'payments',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return data.map((e) => Payment.fromMap(e)).toList();
  }

  /// Calculates total expense, total income, and count directly at the SQLite C-engine level
  Future<FilteredSummaryMetrics> getFilteredSummaryMetrics({
    String? searchQuery,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(description LIKE ? OR accountReference LIKE ? OR notes LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    if (category != null && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final String whereClause = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'debit' AND isExcluded = 0 THEN amount ELSE 0 END), 0) as totalExpense,
        COALESCE(SUM(CASE WHEN type = 'credit' AND isExcluded = 0 THEN amount ELSE 0 END), 0) as totalIncome,
        COUNT(*) as totalCount
      FROM payments
      $whereClause
    ''', whereArgs);

    if (result.isNotEmpty) {
      final row = result.first;
      return FilteredSummaryMetrics(
        totalExpense: (row['totalExpense'] as num?)?.toDouble() ?? 0.0,
        totalIncome: (row['totalIncome'] as num?)?.toDouble() ?? 0.0,
        totalCount: (row['totalCount'] as num?)?.toInt() ?? 0,
      );
    }

    return FilteredSummaryMetrics(totalExpense: 0, totalIncome: 0, totalCount: 0);
  }

  /// Get total count of payments in database
  Future<int> getPaymentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Fetches payments counted in the specified budget month (using budgetMonth if set, otherwise date)
  Future<List<Payment>> getPaymentsByMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final data = await db.query(
      'payments',
      where: '(budgetMonth IS NOT NULL AND budgetMonth BETWEEN ? AND ?) OR (budgetMonth IS NULL AND date BETWEEN ? AND ?)',
      whereArgs: [
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    return data.map((e) => Payment.fromMap(e)).toList();
  }

  Future<void> updatePayment(Payment payment) async {
    final db = await database;
    await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
    notifyDataChanged();
  }

  /// Assign a transaction to count in a different budget month
  Future<void> setBudgetMonth(int id, DateTime? budgetMonth) async {
    final db = await database;
    await db.update(
      'payments',
      {'budgetMonth': budgetMonth?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDataChanged();
  }

  /// Quick toggle for excluding/including a transaction from budget calculations
  Future<void> toggleExcludePayment(int id, bool isExcluded) async {
    final db = await database;
    await db.update(
      'payments',
      {'isExcluded': isExcluded ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDataChanged();
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDataChanged();
  }

  /// Total expense for month, ignoring excluded/silent transactions
  Future<double> getTotalExpenseForMonth(DateTime month) async {
    final payments = await getPaymentsByMonth(month);
    return payments
        .where((p) => p.type == TransactionType.debit && !p.isExcludedFromBudget)
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }

  /// Total income for month, ignoring excluded/silent transactions
  Future<double> getTotalIncomeForMonth(DateTime month) async {
    final payments = await getPaymentsByMonth(month);
    return payments
        .where((p) => p.type == TransactionType.credit && !p.isExcludedFromBudget)
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<double> getNetBalanceForMonth(DateTime month) async {
    final income = await getTotalIncomeForMonth(month);
    final expense = await getTotalExpenseForMonth(month);
    return income - expense;
  }

  /// Category totals for month, ignoring excluded/silent transactions
  Future<Map<String, double>> getCategoryTotals(
    DateTime month, {
    TransactionType type = TransactionType.debit,
  }) async {
    final payments = await getPaymentsByMonth(month);
    final Map<String, double> categoryTotals = {};

    for (final payment in payments.where((p) => p.type == type && !p.isExcludedFromBudget)) {
      categoryTotals[payment.category] =
          (categoryTotals[payment.category] ?? 0) + payment.amount;
    }

    return categoryTotals;
  }
}