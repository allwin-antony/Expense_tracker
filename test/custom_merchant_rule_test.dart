import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/merchant_categorizer.dart';

void main() {
  group('Custom User Merchant Categorization Rule Tests', () {
    setUp(() {
      MerchantCategorizer.loadUserRules({});
    });

    test('Categorizes using default builtin rule when no custom rule exists', () {
      final res = MerchantCategorizer.categorize(
        rawMerchant: 'Swiggy',
        fullMessage: 'Rs.450 debited to Swiggy',
        isIncome: false,
      );
      expect(res.category, equals('Food & Dining'));
      expect(res.confidence, equals(0.95));
    });

    test('User custom merchant rule overrides builtin dictionary rules', () {
      // Suppose user overrides Swiggy to 'Personal Care'
      MerchantCategorizer.setUserRule('swiggy', 'Personal Care');

      final res = MerchantCategorizer.categorize(
        rawMerchant: 'Swiggy',
        fullMessage: 'Rs.450 debited to Swiggy',
        isIncome: false,
      );
      expect(res.category, equals('Personal Care'));
      expect(res.confidence, equals(1.0));
    });

    test('User custom merchant rule categorizes unknown local merchant automatically', () {
      // User sets custom rule for local vendor 'Sharma Sweets and Dhaba'
      MerchantCategorizer.setUserRule('sharma sweets', 'Food & Dining');

      final res = MerchantCategorizer.categorize(
        rawMerchant: 'Sharma Sweets and Dhaba',
        fullMessage: 'Rs.250 paid to Sharma Sweets and Dhaba via UPI',
        isIncome: false,
      );
      expect(res.category, equals('Food & Dining'));
      expect(res.confidence, equals(1.0));
    });

    test('Deleting custom rule restores builtin categorization logic', () {
      MerchantCategorizer.setUserRule('amazon', 'Healthcare');
      expect(
        MerchantCategorizer.categorize(
          rawMerchant: 'Amazon',
          fullMessage: 'Rs.999 spent at Amazon',
          isIncome: false,
        ).category,
        equals('Healthcare'),
      );

      MerchantCategorizer.deleteUserRule('amazon');

      final res = MerchantCategorizer.categorize(
        rawMerchant: 'Amazon',
        fullMessage: 'Rs.999 spent at Amazon',
        isIncome: false,
      );
      expect(res.category, equals('Shopping'));
      expect(res.confidence, equals(0.95));
    });
  });
}
