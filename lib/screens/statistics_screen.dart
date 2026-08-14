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
  Map<String, double> _expenseCategoryTotals = {};
  Map<String, double> _incomeCategoryTotals = {};
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  bool _isLoading = true;
  TransactionType _chartType = TransactionType.debit;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);

    try {
      final payments = await DatabaseService.instance.getPaymentsByMonth(_selectedMonth);
      final expenseTotals = await DatabaseService.instance.getCategoryTotals(
        _selectedMonth,
        type: TransactionType.debit,
      );
      final incomeTotals = await DatabaseService.instance.getCategoryTotals(
        _selectedMonth,
        type: TransactionType.credit,
      );
      final expense = await DatabaseService.instance.getTotalExpenseForMonth(_selectedMonth);
      final income = await DatabaseService.instance.getTotalIncomeForMonth(_selectedMonth);

      setState(() {
        _monthPayments = payments;
        _expenseCategoryTotals = expenseTotals;
        _incomeCategoryTotals = incomeTotals;
        _totalExpense = expense;
        _totalIncome = income;
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

  double get dailyAverageExpense {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    return _totalExpense / daysInMonth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final isCurrentMonth = _selectedMonth.month == DateTime.now().month &&
        _selectedMonth.year == DateTime.now().year;

    final activeTotals = _chartType == TransactionType.debit
        ? _expenseCategoryTotals
        : _incomeCategoryTotals;
    final activeTotalAmount = _chartType == TransactionType.debit
        ? _totalExpense
        : _totalIncome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMonthData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Navigator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous month',
                          ),
                          Text(
                            monthName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Next month',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top KPI Stats Cards
                    Row(
                      children: [
                        // Total Income
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Income', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(_totalIncome)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Total Expense
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Expenses', style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(_totalExpense)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Net Savings & Daily Average Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('Net Savings', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(_totalIncome - _totalExpense)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: (_totalIncome - _totalExpense) >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                          Column(
                            children: [
                              Text('Daily Avg Expense', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(dailyAverageExpense)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                          Column(
                            children: [
                              Text('Total Txns', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(
                                '${_monthPayments.length}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown Header + Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SegmentedButton<TransactionType>(
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: const [
                            ButtonSegment(value: TransactionType.debit, label: Text('Expense', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: TransactionType.credit, label: Text('Income', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_chartType},
                          onSelectionChanged: (set) {
                            setState(() {
                              _chartType = set.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Pie Chart & List
                    if (activeTotals.isNotEmpty && activeTotalAmount > 0) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: activeTotals.entries.map((entry) {
                                  final percentage = (entry.value / activeTotalAmount) * 100;
                                  final color = Category.getColor(entry.key);

                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
                                    radius: 70,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 3,
                                centerSpaceRadius: 35,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Details List
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: activeTotals.entries.map((entry) {
                            final percentage = (entry.value / activeTotalAmount) * 100;
                            final color = Category.getColor(entry.key);

                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(Category.getIcon(entry.key), style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${percentage.toStringAsFixed(1)}% of total'),
                              trailing: Text(
                                '₹${NumberFormat('#,##,###.00').format(entry.value)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_chartType == TransactionType.debit ? 'expense' : 'income'} data for this month',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
