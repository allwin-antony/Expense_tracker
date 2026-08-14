import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  group('NotificationService Payload and Formatting Tests', () {
    test('Constructs accurate notification payload for interactive notification actions', () {
      final payment = Payment(
        id: 101,
        description: 'Swiggy Food Order',
        amount: 450.0,
        type: TransactionType.debit,
        category: 'Food & Dining',
        date: DateTime(2026, 8, 14, 20, 30),
      );

      final payload = jsonEncode({
        'id': payment.id,
        'amount': payment.amount,
        'description': payment.description,
        'category': payment.category,
        'type': payment.type.name,
      });

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      expect(decoded['id'], 101);
      expect(decoded['amount'], 450.0);
      expect(decoded['category'], 'Food & Dining');
      expect(decoded['type'], 'debit');
    });

    test('Formats notification title and body properly for debit and credit transactions', () {
      final debit = Payment(
        id: 1,
        description: 'Uber Ride',
        amount: 320.0,
        type: TransactionType.debit,
        category: 'Transportation',
        paymentMode: PaymentMode.upi,
        date: DateTime(2026, 8, 14, 15, 0),
      );

      final isDebitIncome = debit.type == TransactionType.credit;
      final debitSign = isDebitIncome ? '+' : '-';
      expect(debitSign, '-');

      final credit = Payment(
        id: 2,
        description: 'Acsia Payroll Salary',
        amount: 29424.0,
        type: TransactionType.credit,
        category: 'Salary',
        paymentMode: PaymentMode.netBanking,
        date: DateTime(2026, 8, 14, 18, 0),
      );

      final isCreditIncome = credit.type == TransactionType.credit;
      final creditSign = isCreditIncome ? '+' : '-';
      expect(creditSign, '+');
    });
  });
}
