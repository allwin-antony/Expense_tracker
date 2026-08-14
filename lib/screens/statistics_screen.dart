import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/payment.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/shimmer_loading.dart';

class StatisticsScreen extends StatefulWidget {
  final void Function(String category, TransactionType type, DateTime month)? onCategorySelected;

  const StatisticsScreen({super.key, this.onCategorySelected});

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
    DatabaseService.instance.dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    DatabaseService.instance.dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadMonthData(silent: true);
    }
  }

  Future<void> _loadMonthData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

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

      if (mounted) {
        setState(() {
          _monthPayments = payments;
          _expenseCategoryTotals = expenseTotals;
          _incomeCategoryTotals = incomeTotals;
          _totalExpense = expense;
          _totalIncome = income;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int monthOffset) {
    HapticFeedback.selectionClick();
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
    return daysInMonth > 0 ? _totalExpense / daysInMonth : 0.0;
  }

  void _drillDownCategory(String category) {
    HapticFeedback.mediumImpact();
    widget.onCategorySelected?.call(category, _chartType, _selectedMonth);
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
        title: const Text(
          'Financial Analytics',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ShimmerHeroCardSkeleton(),
                  SizedBox(height: 16),
                  ShimmerTransactionSkeleton(),
                  ShimmerTransactionSkeleton(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await _loadMonthData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Navigator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                            tooltip: 'Previous month',
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                monthName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                            tooltip: 'Next month',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top KPI Stats Cards
                    Row(
                      children: [
                        // Total Income Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(_totalIncome)}',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Total Expense Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Expenses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(_totalExpense)}',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
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
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Net Savings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(_totalIncome - _totalExpense)}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: (_totalIncome - _totalExpense) >= 0
                                      ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                      : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          Column(
                            children: [
                              Text(
                                'Daily Avg Expense',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,###.00').format(dailyAverageExpense)}',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          Column(
                            children: [
                              Text(
                                'Total Txns',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_monthPayments.length}',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Tap category to view in History',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SegmentedButton<TransactionType>(
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: WidgetStatePropertyAll(
                              BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.debit,
                              label: Text('Expense', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            ButtonSegment(
                              value: TransactionType.credit,
                              label: Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          selected: {_chartType},
                          onSelectionChanged: (set) {
                            HapticFeedback.selectionClick();
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
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    if (event is FlTapUpEvent &&
                                        pieTouchResponse != null &&
                                        pieTouchResponse.touchedSection != null) {
                                      final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      if (index >= 0 && index < activeTotals.length) {
                                        final category = activeTotals.keys.elementAt(index);
                                        _drillDownCategory(category);
                                      }
                                    }
                                  },
                                ),
                                sections: activeTotals.entries.map((entry) {
                                  final percentage = (entry.value / activeTotalAmount) * 100;
                                  final color = Category.getColor(entry.key);

                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
                                    radius: 65,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Details List with Progress Bar & Tap to Drill Down
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeTotals.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final entry = activeTotals.entries.elementAt(index);
                            final percentage = (entry.value / activeTotalAmount) * 100;
                            final color = Category.getColor(entry.key);

                            return InkWell(
                              onTap: () => _drillDownCategory(entry.key),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: color.withValues(alpha: isDark ? 0.45 : 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Category.getMaterialIcon(entry.key),
                                          size: 18,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              Text(
                                                '₹${NumberFormat('#,##,###.00').format(entry.value)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: percentage / 100,
                                                    backgroundColor: isDark
                                                        ? const Color(0xFF334155)
                                                        : const Color(0xFFE2E8F0),
                                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                                    minHeight: 5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(36),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 48,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_chartType == TransactionType.debit ? 'expense' : 'income'} data for this month',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
