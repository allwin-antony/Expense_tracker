import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/payment.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Payment> _monthPayments = [];
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);

    try {
      final payments = await DatabaseService.instance.getPaymentsByMonth(
        _selectedMonth,
      );
      final categoryTotals = await DatabaseService.instance.getCategoryTotals(
        _selectedMonth,
      );

      setState(() {
        _monthPayments = payments;
        _categoryTotals = categoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthOffset,
        1,
      );
    });
    _loadMonthData();
  }

  double get totalSpent =>
      _monthPayments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get dailyAverage {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    return totalSpent / daysInMonth;
  }

  List<Color> get chartColors => [
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFFF44336),
    const Color(0xFF00BCD4),
    const Color(0xFFFFEB3B),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
    const Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final isCurrentMonth =
        _selectedMonth.month == DateTime.now().month &&
        _selectedMonth.year == DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            monthName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: isCurrentMonth
                                ? null
                                : () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Overview
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Spent',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###.00').format(totalSpent)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transactions',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_monthPayments.length}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Average',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${NumberFormat('#,##,###.00').format(dailyAverage)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_categoryTotals.isNotEmpty) ...[
                    const SizedBox(height: 32),

                    // Category Breakdown Title
                    Text(
                      'Category Breakdown',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pie Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: _categoryTotals.entries.map((entry) {
                                final index = _categoryTotals.keys
                                    .toList()
                                    .indexOf(entry.key);
                                final percentage =
                                    (entry.value / totalSpent) * 100;

                                return PieChartSectionData(
                                  color:
                                      chartColors[index % chartColors.length],
                                  value: entry.value,
                                  title: '${percentage.toStringAsFixed(1)}%',
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category List
                    Card(
                      child: Column(
                        children: _categoryTotals.entries.map((entry) {
                          final index = _categoryTotals.keys.toList().indexOf(
                            entry.key,
                          );
                          final percentage = (entry.value / totalSpent) * 100;

                          return ListTile(
                            leading: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: chartColors[index % chartColors.length],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(Category.getIcon(entry.key)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(entry.key)),
                              ],
                            ),
                            subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                            trailing: Text(
                              '₹${NumberFormat('#,##,###.00').format(entry.value)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No data for this month',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
