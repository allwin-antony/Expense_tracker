import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  group('Payment Budget Month (Count In Another Month) Tests', () {
    test('Correctly defaults effectiveMonth to transaction date month when budgetMonth is null', () {
      final payment = Payment(
        description: 'Groceries',
        amount: 500.0,
        category: 'Groceries',
        date: DateTime(2026, 7, 15, 10, 30),
      );

      expect(payment.effectiveMonth, DateTime(2026, 7, 1));
      expect(payment.hasShiftedBudgetMonth, isFalse);
      expect(payment.budgetMonth, isNull);
    });

    test('Correctly shifts effectiveMonth when budgetMonth is set to next month', () {
      // Early salary received on July 31st, counted in August budget
      final payment = Payment(
        description: 'Acsia Salary July 31',
        amount: 29424.0,
        type: TransactionType.credit,
        category: 'Salary',
        date: DateTime(2026, 7, 31, 18, 45),
        budgetMonth: DateTime(2026, 8, 1),
      );

      expect(payment.effectiveMonth, DateTime(2026, 8, 1));
      expect(payment.hasShiftedBudgetMonth, isTrue);
      expect(payment.date.month, 7);
      expect(payment.budgetMonth!.month, 8);
    });

    test('Serializes and deserializes budgetMonth properly in toMap() and fromMap()', () {
      final payment = Payment(
        id: 42,
        description: 'Advance Rent',
        amount: 15000.0,
        type: TransactionType.debit,
        category: 'Bills & Utilities',
        date: DateTime(2026, 8, 31, 21, 0),
        budgetMonth: DateTime(2026, 9, 1),
      );

      final map = payment.toMap();
      expect(map['budgetMonth'], DateTime(2026, 9, 1).toIso8601String());

      final recreated = Payment.fromMap(map);
      expect(recreated.budgetMonth, DateTime(2026, 9, 1));
      expect(recreated.effectiveMonth, DateTime(2026, 9, 1));
      expect(recreated.hasShiftedBudgetMonth, isTrue);
    });

    test('copyWith handles setting and clearing budgetMonth', () {
      final payment = Payment(
        description: 'Test Payment',
        amount: 100.0,
        category: 'Other',
        date: DateTime(2026, 7, 31),
        budgetMonth: DateTime(2026, 8, 1),
      );

      expect(payment.hasShiftedBudgetMonth, isTrue);

      // Clear budget month back to default
      final cleared = payment.copyWith(clearBudgetMonth: true);
      expect(cleared.budgetMonth, isNull);
      expect(cleared.effectiveMonth, DateTime(2026, 7, 1));
      expect(cleared.hasShiftedBudgetMonth, isFalse);
    });
  });
}
