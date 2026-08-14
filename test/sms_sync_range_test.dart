import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/sms_sync_service.dart';

void main() {
  group('SmsSyncRange Tests', () {
    test('Calculates This Month date range correctly', () {
      final now = DateTime.now();
      final (start, end) = SmsSyncRange.thisMonth.getDates();

      expect(start, isNotNull);
      expect(end, isNotNull);
      expect(start!.year, now.year);
      expect(start.month, now.month);
      expect(start.day, 1);
    });

    test('Calculates Last Month date range correctly', () {
      final now = DateTime.now();
      final (start, end) = SmsSyncRange.lastMonth.getDates();

      expect(start, isNotNull);
      expect(end, isNotNull);
      expect(start!.isBefore(now), isTrue);
      expect(end!.isBefore(DateTime(now.year, now.month, 1)), isTrue);
    });

    test('Calculates Last 30 Days and Last 90 Days ranges', () {
      final (start30, end30) = SmsSyncRange.last30Days.getDates();
      final (start90, end90) = SmsSyncRange.last90Days.getDates();

      expect(start30, isNotNull);
      expect(end30, isNotNull);
      expect(start90, isNotNull);
      expect(end90, isNotNull);
      expect(start90!.isBefore(start30!), isTrue);
    });

    test('Calculates Custom Date Range accurately', () {
      final custom = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      );

      final (start, end) = SmsSyncRange.customRange.getDates(customDateRange: custom);

      expect(start, DateTime(2026, 6, 1));
      expect(end, DateTime(2026, 6, 30, 23, 59, 59));
    });
  });
}
