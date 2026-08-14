import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/payment.dart';
import 'package:expense_tracker/utils/date_group_helper.dart';

void main() {
  group('Exclude from Budget / Calculations Tests', () {
    test('Payment model correctly serializes and deserializes isExcludedFromBudget', () {
      final payment = Payment(
        id: 1,
        description: 'Self Account Transfer to SBI',
        amount: 5000.0,
        type: TransactionType.debit,
        category: 'Transfer',
        date: DateTime(2026, 8, 14),
        isExcludedFromBudget: true,
      );

      final map = payment.toMap();
      expect(map['isExcluded'], 1);

      final fromMap = Payment.fromMap(map);
      expect(fromMap.isExcludedFromBudget, isTrue);
      expect(fromMap.amount, 5000.0);
    });

    test('DateGroupHelper ignores excluded transactions in daily subtotal sums', () {
      final activeExpense = Payment(
        description: 'Swiggy Dinner',
        amount: 450.0,
        type: TransactionType.debit,
        category: 'Food & Dining',
        date: DateTime(2026, 8, 14, 20, 0),
        isExcludedFromBudget: false,
      );

      final excludedExpense = Payment(
        description: 'Self transfer to savings',
        amount: 10000.0,
        type: TransactionType.debit,
        category: 'Transfer',
        date: DateTime(2026, 8, 14, 10, 0),
        isExcludedFromBudget: true,
      );

      final activeIncome = Payment(
        description: 'Salary',
        amount: 75000.0,
        type: TransactionType.credit,
        category: 'Salary',
        date: DateTime(2026, 8, 14, 9, 0),
        isExcludedFromBudget: false,
      );

      final excludedIncome = Payment(
        description: 'Deposit Refund Hold',
        amount: 2000.0,
        type: TransactionType.credit,
        category: 'Other Income',
        date: DateTime(2026, 8, 14, 12, 0),
        isExcludedFromBudget: true,
      );

      final groups = DateGroupHelper.groupByDate([
        activeExpense,
        excludedExpense,
        activeIncome,
        excludedIncome,
      ]);

      expect(groups.length, 1);
      final todayGroup = groups.first;

      // Group payments count includes all 4 for complete history
      expect(todayGroup.payments.length, 4);

      // But expense subtotal only includes the active 450, NOT the 10,000 excluded transfer
      expect(todayGroup.totalExpense, 450.0);

      // And income subtotal only includes the active 75,000, NOT the 2,000 excluded refund
      expect(todayGroup.totalIncome, 75000.0);
    });
  });
}
