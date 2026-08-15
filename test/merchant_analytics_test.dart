import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/database_service.dart';

void main() {
  group('Merchant Analytics Unit Tests', () {
    test('MerchantSummary model instantiates accurately', () {
      final summary = MerchantSummary(
        merchantName: 'Swiggy',
        totalAmount: 4500.0,
        transactionCount: 9,
        percentage: 45.0,
      );

      expect(summary.merchantName, equals('Swiggy'));
      expect(summary.totalAmount, equals(4500.0));
      expect(summary.transactionCount, equals(9));
      expect(summary.percentage, equals(45.0));
    });
  });
}
