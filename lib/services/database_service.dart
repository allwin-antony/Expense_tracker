import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _database;

  DatabaseService._constructor();

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE payments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            isInitiated INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> addPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final data = await db.query('payments', orderBy: 'date DESC');
    return data.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Payment>> getPaymentsByMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final data = await db.query(
      'payments',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
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
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getCategoryTotals(DateTime month) async {
    final payments = await getPaymentsByMonth(month);
    final Map<String, double> categoryTotals = {};
    
    for (final payment in payments) {
      categoryTotals[payment.category] = 
          (categoryTotals[payment.category] ?? 0) + payment.amount;
    }
    
    return categoryTotals;
  }

  Future<double> getTotalForMonth(DateTime month) async {
    final payments = await getPaymentsByMonth(month);
    return payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }
}