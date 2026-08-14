import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  group('Batch Date Operations Model Tests', () {
    test('Batch excluding payments toggles isExcludedFromBudget flag correctly', () {
      final payments = [
        Payment(id: 1, description: 'Morning Coffee', amount: 150.0, category: 'Food & Dining', date: DateTime(2026, 7, 31, 9)),
        Payment(id: 2, description: 'Uber to Office', amount: 350.0, category: 'Transportation', date: DateTime(2026, 7, 31, 10)),
        Payment(id: 3, description: 'Client Lunch', amount: 1200.0, category: 'Food & Dining', date: DateTime(2026, 7, 31, 13)),
      ];

      final batchIds = [1, 2, 3];
      final excluded = payments.map((p) {
        if (batchIds.contains(p.id)) {
          return p.copyWith(isExcludedFromBudget: true);
        }
        return p;
      }).toList();

      expect(excluded.every((p) => p.isExcludedFromBudget), isTrue);
      expect(excluded.length, 3);
    });

    test('Batch shifting payments to next budget month updates effectiveMonth for all items', () {
      final payments = [
        Payment(id: 1, description: 'Salary', amount: 29424.0, type: TransactionType.credit, category: 'Salary', date: DateTime(2026, 7, 31, 18)),
        Payment(id: 2, description: 'Bonus', amount: 5000.0, type: TransactionType.credit, category: 'Salary', date: DateTime(2026, 7, 31, 19)),
      ];

      final augustMonth = DateTime(2026, 8, 1);
      final batchIds = [1, 2];

      final shifted = payments.map((p) {
        if (batchIds.contains(p.id)) {
          return p.copyWith(budgetMonth: augustMonth);
        }
        return p;
      }).toList();

      for (final p in shifted) {
        expect(p.budgetMonth, augustMonth);
        expect(p.effectiveMonth, augustMonth);
        expect(p.hasShiftedBudgetMonth, isTrue);
        expect(p.date.month, 7); // SMS date is preserved
      }
    });
  });
}
