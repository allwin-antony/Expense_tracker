import 'package:intl/intl.dart';
import '../models/payment.dart';

class DateGroup {
  final String dateKey; // e.g. "2026-08-14"
  final String displayTitle; // "Today", "Yesterday", "Wed, Aug 12"
  final DateTime date;
  final List<Payment> payments;
  final double totalExpense;
  final double totalIncome;

  DateGroup({
    required this.dateKey,
    required this.displayTitle,
    required this.date,
    required this.payments,
    required this.totalExpense,
    required this.totalIncome,
  });
}

class DateGroupHelper {
  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayNameFormat = DateFormat('EEE, MMM d');
  static final DateFormat _fullDateFormat = DateFormat('EEE, MMM d, yyyy');

  /// Groups a list of payments (assumed sorted date desc) into date sections
  static List<DateGroup> groupByDate(List<Payment> payments) {
    if (payments.isEmpty) return [];

    final now = DateTime.now();
    final todayKey = _keyFormat.format(now);
    final yesterdayKey = _keyFormat.format(now.subtract(const Duration(days: 1)));

    final Map<String, List<Payment>> map = {};
    final Map<String, DateTime> sampleDates = {};

    for (final p in payments) {
      final key = _keyFormat.format(p.date);
      map.putIfAbsent(key, () => []).add(p);
      sampleDates.putIfAbsent(key, () => p.date);
    }

    final List<DateGroup> groups = [];

    for (final entry in map.entries) {
      final key = entry.key;
      final groupPayments = entry.value;
      final date = sampleDates[key]!;

      String title;
      if (key == todayKey) {
        title = 'Today • ${DateFormat('d MMM').format(date)}';
      } else if (key == yesterdayKey) {
        title = 'Yesterday • ${DateFormat('d MMM').format(date)}';
      } else if (date.year == now.year) {
        title = _dayNameFormat.format(date);
      } else {
        title = _fullDateFormat.format(date);
      }

      double expense = 0.0;
      double income = 0.0;

      for (final p in groupPayments) {
        if (!p.isExcludedFromBudget) {
          if (p.isExpense) {
            expense += p.amount;
          } else {
            income += p.amount;
          }
        }
      }

      groups.add(DateGroup(
        dateKey: key,
        displayTitle: title,
        date: date,
        payments: groupPayments,
        totalExpense: expense,
        totalIncome: income,
      ));
    }

    return groups;
  }
}
