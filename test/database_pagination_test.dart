import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/database_service.dart';

void main() {
  group('FilteredSummaryMetrics Tests', () {
    test('Constructs FilteredSummaryMetrics correctly', () {
      final metrics = FilteredSummaryMetrics(
        totalExpense: 1540.50,
        totalIncome: 75000.0,
        totalCount: 14,
      );

      expect(metrics.totalExpense, 1540.50);
      expect(metrics.totalIncome, 75000.0);
      expect(metrics.totalCount, 14);
    });
  });
}
