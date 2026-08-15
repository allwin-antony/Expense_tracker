import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../utils/date_group_helper.dart';
import '../widgets/payment_card.dart';
import '../widgets/edit_payment_dialog.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/category_picker_sheet.dart';

enum TimeFilterPreset {
  allTime,
  thisMonth,
  lastMonth,
  last30Days,
  thisYear,
  specificMonth,
  customRange;

  String get displayName {
    switch (this) {
      case TimeFilterPreset.allTime:
        return 'All Time';
      case TimeFilterPreset.thisMonth:
        return 'This Month';
      case TimeFilterPreset.lastMonth:
        return 'Last Month';
      case TimeFilterPreset.last30Days:
        return 'Last 30 Days';
      case TimeFilterPreset.thisYear:
        return 'This Year';
      case TimeFilterPreset.specificMonth:
        return 'Selected Month';
      case TimeFilterPreset.customRange:
        return 'Custom Range';
    }
  }
}

class HistoryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialFilterType; // 'All', 'Expense', 'Income'
  final DateTime? initialMonth; // e.g. when navigated from Analytics

  const HistoryScreen({
    super.key,
    this.initialCategory,
    this.initialFilterType,
    this.initialMonth,
  });

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  static const int _pageSize = 25;

  List<Payment> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  int _totalCount = 0;
  double _filteredTotalExpense = 0.0;
  double _filteredTotalIncome = 0.0;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedFilterType = 'All'; // 'All', 'Expense', 'Income'

  TimeFilterPreset _selectedTimePreset = TimeFilterPreset.allTime;
  DateTime? _filterMonth; // When a specific month is chosen (e.g. from Analytics)
  DateTimeRange? _customDateRange;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  /// Scrolls back to top smoothly and reloads history data
  Future<void> scrollToTopAndRefresh() async {
    HapticFeedback.mediumImpact();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    await _loadFilteredData();
  }

  @override
  void initState() {
    super.initState();
    _applyInitialFilters();
    _scrollController.addListener(_onScroll);
    _loadFilteredData();
    DatabaseService.instance.dataChangeNotifier.addListener(_onDataChanged);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.initialFilterType != oldWidget.initialFilterType ||
        widget.initialMonth != oldWidget.initialMonth) {
      _applyInitialFilters();
      _loadFilteredData();
    }
  }

  void _applyInitialFilters() {
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialFilterType != null) {
      _selectedFilterType = widget.initialFilterType!;
    }
    if (widget.initialMonth != null) {
      _filterMonth = widget.initialMonth;
      _selectedTimePreset = TimeFilterPreset.specificMonth;
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    DatabaseService.instance.dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMorePayments();
    }
  }

  void _onDataChanged() {
    if (mounted) {
      _loadFilteredData(silent: true);
    }
  }

  (DateTime? start, DateTime? end) _getDatesForCurrentPreset() {
    final now = DateTime.now();
    switch (_selectedTimePreset) {
      case TimeFilterPreset.allTime:
        return (null, null);

      case TimeFilterPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);

      case TimeFilterPreset.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start, end);

      case TimeFilterPreset.last30Days:
        final start = now.subtract(const Duration(days: 30));
        final end = now;
        return (start, end);

      case TimeFilterPreset.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);

      case TimeFilterPreset.specificMonth:
        if (_filterMonth != null) {
          final start = DateTime(_filterMonth!.year, _filterMonth!.month, 1);
          final end = DateTime(_filterMonth!.year, _filterMonth!.month + 1, 0, 23, 59, 59);
          return (start, end);
        }
        return (null, null);

      case TimeFilterPreset.customRange:
        if (_customDateRange != null) {
          final start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          final end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
          return (start, end);
        }
        return (null, null);
    }
  }

  TransactionType? get _currentTransactionType {
    if (_selectedFilterType == 'Expense') return TransactionType.debit;
    if (_selectedFilterType == 'Income') return TransactionType.credit;
    return null;
  }

  /// Initial load / Filter changed query
  Future<void> _loadFilteredData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final (startDate, endDate) = _getDatesForCurrentPreset();

      // 1. Fetch SQL-level aggregated metrics
      final metrics = await DatabaseService.instance.getFilteredSummaryMetrics(
        searchQuery: _searchQuery,
        category: _selectedCategory,
        type: _currentTransactionType,
        startDate: startDate,
        endDate: endDate,
      );

      // Determine current loaded count to prevent list truncation on silent reloads
      final int currentLoadedCount = _payments.length;
      final int fetchLimit = silent 
          ? (currentLoadedCount > _pageSize ? currentLoadedCount : _pageSize) 
          : _pageSize;

      // 2. Fetch paginated records
      final pageData = await DatabaseService.instance.getFilteredPaymentsPaginated(
        limit: fetchLimit,
        offset: 0,
        searchQuery: _searchQuery,
        category: _selectedCategory,
        type: _currentTransactionType,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _payments = pageData;
          _totalCount = metrics.totalCount;
          _filteredTotalExpense = metrics.totalExpense;
          _filteredTotalIncome = metrics.totalIncome;
          _hasMore = _payments.length < metrics.totalCount;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  /// Loads next page of records when user scrolls down
  Future<void> _loadMorePayments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final (startDate, endDate) = _getDatesForCurrentPreset();

      final nextPage = await DatabaseService.instance.getFilteredPaymentsPaginated(
        limit: _pageSize,
        offset: _payments.length,
        searchQuery: _searchQuery,
        category: _selectedCategory,
        type: _currentTransactionType,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _payments.addAll(nextPage);
          _hasMore = _payments.length < _totalCount;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadFilteredData();
      }
    });
  }

  void _onCategoryChanged(String? category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category ?? 'All');
    _loadFilteredData();
  }

  void _onTypeChanged(String type) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFilterType = type);
    _loadFilteredData();
  }

  void _onTimePresetChanged(TimeFilterPreset preset) async {
    HapticFeedback.selectionClick();
    if (preset == TimeFilterPreset.customRange) {
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: _customDateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      );

      if (pickedRange != null) {
        setState(() {
          _customDateRange = pickedRange;
          _selectedTimePreset = TimeFilterPreset.customRange;
        });
        _loadFilteredData();
      }
    } else if (preset == TimeFilterPreset.specificMonth) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _filterMonth ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: 'SELECT MONTH TO FILTER',
      );
      if (picked != null) {
        setState(() {
          _filterMonth = DateTime(picked.year, picked.month, 1);
          _selectedTimePreset = TimeFilterPreset.specificMonth;
        });
        _loadFilteredData();
      }
    } else {
      setState(() {
        _selectedTimePreset = preset;
        _filterMonth = null;
      });
      _loadFilteredData();
    }
  }

  void _resetAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedFilterType = 'All';
      _selectedTimePreset = TimeFilterPreset.allTime;
      _filterMonth = null;
      _customDateRange = null;
    });
    _loadFilteredData();
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedFilterType != 'All' ||
        _selectedTimePreset != TimeFilterPreset.allTime;
  }

  String get _timeFilterLabel {
    switch (_selectedTimePreset) {
      case TimeFilterPreset.allTime:
        return 'All Time';
      case TimeFilterPreset.thisMonth:
        return 'This Month';
      case TimeFilterPreset.lastMonth:
        return 'Last Month';
      case TimeFilterPreset.last30Days:
        return 'Last 30 Days';
      case TimeFilterPreset.thisYear:
        return 'This Year';
      case TimeFilterPreset.specificMonth:
        return _filterMonth != null ? DateFormat('MMM yyyy').format(_filterMonth!) : 'Month';
      case TimeFilterPreset.customRange:
        if (_customDateRange != null) {
          return '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}';
        }
        return 'Custom';
    }
  }

  IconData _getPresetIcon(TimeFilterPreset preset) {
    switch (preset) {
      case TimeFilterPreset.allTime:
        return Icons.all_inclusive_rounded;
      case TimeFilterPreset.thisMonth:
        return Icons.calendar_month_rounded;
      case TimeFilterPreset.lastMonth:
        return Icons.history_rounded;
      case TimeFilterPreset.last30Days:
        return Icons.update_rounded;
      case TimeFilterPreset.thisYear:
        return Icons.date_range_rounded;
      case TimeFilterPreset.specificMonth:
        return Icons.event_rounded;
      case TimeFilterPreset.customRange:
        return Icons.edit_calendar_rounded;
    }
  }

  void _showTimeFilterPickerSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Time Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: TimeFilterPreset.values.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final preset = TimeFilterPreset.values[index];
                    final isSelected = _selectedTimePreset == preset;
                    String label = preset.displayName;
                    if (preset == TimeFilterPreset.specificMonth && _filterMonth != null) {
                      label = 'Month: ${DateFormat('MMM yyyy').format(_filterMonth!)}';
                    } else if (preset == TimeFilterPreset.customRange && _customDateRange != null) {
                      label = 'Range: ${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}';
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _onTimePresetChanged(preset);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getPresetIcon(preset),
                                size: 18,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${payment.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && payment.id != null) {
      final deletedPayment = payment;
      await DatabaseService.instance.deletePayment(payment.id!);
      if (mounted) {
        setState(() {
          _payments.removeWhere((p) => p.id == payment.id);
          _totalCount = (_totalCount - 1).clamp(0, 999999);
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${deletedPayment.description}"'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF60A5FA),
              onPressed: () async {
                await DatabaseService.instance.addPayment(deletedPayment);
                if (mounted) {
                  _loadFilteredData();
                }
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showEditDialog(Payment payment) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPaymentDialog(
        payment: payment,
        onPaymentUpdated: (updatedPayment) async {
          await DatabaseService.instance.updatePayment(updatedPayment);
          if (mounted) {
            final index = _payments.indexWhere((p) => p.id == updatedPayment.id);
            if (index != -1) {
              setState(() {
                _payments[index] = updatedPayment;
              });
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleExcludePayment(Payment payment, bool isExcluded) async {
    if (payment.id == null) return;
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.toggleExcludePayment(payment.id!, isExcluded);

    if (mounted) {
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        setState(() {
          _payments[index] = payment.copyWith(isExcludedFromBudget: isExcluded);
        });
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExcluded
                ? 'Excluded from budget'
                : 'Included in budget',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFF60A5FA),
            onPressed: () async {
              await DatabaseService.instance.toggleExcludePayment(payment.id!, !isExcluded);
              if (mounted) {
                final idx = _payments.indexWhere((p) => p.id == payment.id);
                if (idx != -1) {
                  setState(() {
                    _payments[idx] = payment.copyWith(isExcludedFromBudget: !isExcluded);
                  });
                }
              }
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _assignBudgetMonth(Payment payment, DateTime? budgetMonth) async {
    if (payment.id == null) return;
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.setBudgetMonth(payment.id!, budgetMonth);

    if (mounted) {
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        setState(() {
          _payments[index] = payment.copyWith(
            budgetMonth: budgetMonth,
            clearBudgetMonth: budgetMonth == null,
          );
        });
      }

      final monthStr = budgetMonth != null
          ? DateFormat('MMMM yyyy').format(budgetMonth)
          : DateFormat('MMMM yyyy').format(payment.date);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFF60A5FA), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Counted in $monthStr budget',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateGroups = DateGroupHelper.groupByDate(_payments);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => _loadFilteredData(),
          ),
        ],
      ),
      body: _isLoading
          ? Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ShimmerTransactionSkeleton(),
                        ShimmerTransactionSkeleton(),
                        ShimmerTransactionSkeleton(),
                        ShimmerTransactionSkeleton(),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: () => _loadFilteredData(silent: true),
              child: Column(
                children: [
                  // Filter Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search description, account, notes...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13.5),
                          onChanged: _onSearchChanged,
                        ),
                        const SizedBox(height: 10),

                        // Row 1: Type Segmented Button
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'All',
                                label: Text('All', style: TextStyle(fontSize: 12)),
                              ),
                              ButtonSegment(
                                value: 'Expense',
                                label: Text('Expenses', style: TextStyle(fontSize: 12)),
                              ),
                              ButtonSegment(
                                value: 'Income',
                                label: Text('Income', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                            selected: {_selectedFilterType},
                            onSelectionChanged: (set) {
                              _onTypeChanged(set.first);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Category & Time Preset Filter
                        Row(
                          children: [
                            // Category Filter Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => CategoryPickerSheet.show(
                                    context,
                                    selectedCategory: _selectedCategory,
                                    type: _currentTransactionType ?? TransactionType.debit,
                                    includeAllOption: true,
                                    onSelected: (cat) => _onCategoryChanged(cat),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory != 'All'
                                          ? Category.getColor(_selectedCategory).withValues(alpha: isDark ? 0.22 : 0.12)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedCategory != 'All'
                                            ? Category.getColor(_selectedCategory).withValues(alpha: isDark ? 0.5 : 0.35)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : const Color(0xFFE2E8F0)),
                                        width: _selectedCategory != 'All' ? 1.2 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: _selectedCategory == 'All'
                                                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                                : Category.getColor(_selectedCategory).withValues(alpha: isDark ? 0.3 : 0.2),
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Icon(
                                            _selectedCategory == 'All'
                                                ? Icons.grid_view_rounded
                                                : Category.getMaterialIcon(_selectedCategory),
                                            size: 14,
                                            color: _selectedCategory == 'All'
                                                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))
                                                : Category.getColor(_selectedCategory),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _selectedCategory == 'All' ? 'All Categories' : _selectedCategory,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _selectedCategory != 'All'
                                                  ? (isDark ? Colors.white : Category.getColor(_selectedCategory))
                                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                             // Time Filter Picker Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showTimeFilterPickerSheet(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedTimePreset != TimeFilterPreset.allTime
                                          ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedTimePreset != TimeFilterPreset.allTime
                                            ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.5 : 0.35)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : const Color(0xFFE2E8F0)),
                                        width: _selectedTimePreset != TimeFilterPreset.allTime ? 1.2 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: _selectedTimePreset == TimeFilterPreset.allTime
                                                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                                : const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.2),
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Icon(
                                            _getPresetIcon(_selectedTimePreset),
                                            size: 14,
                                            color: _selectedTimePreset == TimeFilterPreset.allTime
                                                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))
                                                : const Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _timeFilterLabel,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _selectedTimePreset != TimeFilterPreset.allTime
                                                  ? (isDark ? Colors.white : const Color(0xFF2563EB))
                                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Active Filter Pills
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_searchQuery.isNotEmpty)
                                  _buildFilterChip(
                                    '"$_searchQuery"',
                                    onDeleted: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                if (_selectedCategory != 'All')
                                  _buildFilterChip(
                                    '${Category.getIcon(_selectedCategory)} $_selectedCategory',
                                    onDeleted: () => _onCategoryChanged('All'),
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                if (_selectedFilterType != 'All')
                                  _buildFilterChip(
                                    _selectedFilterType,
                                    onDeleted: () => _onTypeChanged('All'),
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                if (_selectedTimePreset != TimeFilterPreset.allTime)
                                  _buildFilterChip(
                                    _timeFilterLabel,
                                    onDeleted: () => _onTimePresetChanged(TimeFilterPreset.allTime),
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                TextButton(
                                  onPressed: _resetAllFilters,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Reset All', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Results Summary Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_totalCount transaction${_totalCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            if (_filteredTotalIncome > 0 && _selectedFilterType != 'Expense')
                              Text(
                                '+₹${NumberFormat('#,##,###').format(_filteredTotalIncome)}  ',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            if (_filteredTotalExpense > 0 && _selectedFilterType != 'Income')
                              Text(
                                '-₹${NumberFormat('#,##,###').format(_filteredTotalExpense)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Shifted Transactions Info Banner
                  if (_payments.any((p) => p.hasShiftedBudgetMonth)) ...[
                    Builder(
                      builder: (context) {
                        final shiftedList = _payments.where((p) => p.hasShiftedBudgetMonth).toList();
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF4C1D95).withValues(alpha: 0.25)
                                : const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                                  : const Color(0xFFDDD6FE),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 15,
                                color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Includes ${shiftedList.length} transaction${shiftedList.length == 1 ? '' : 's'} assigned to this budget from other dates.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF5B21B6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // List of Transactions with Date Groups & Infinite Scroll
                  Expanded(
                    child: _payments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_off_rounded,
                                      size: 40,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _hasActiveFilters
                                        ? 'No transactions match filters'
                                        : 'No transactions yet',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _hasActiveFilters
                                        ? 'Try clearing active filters or adjusting the time range'
                                        : 'Transactions will appear here once added or synced',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 14),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: const Text('Reset All Filters'),
                                      onPressed: _resetAllFilters,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _calculateTotalCount(dateGroups) + 1,
                            itemBuilder: (context, index) {
                              // Check if this is the pagination footer item
                              final totalSliverCount = _calculateTotalCount(dateGroups);
                              if (index == totalSliverCount) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Loading more transactions...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          )
                                        : (!_hasMore && _payments.isNotEmpty)
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline_rounded,
                                                    size: 15,
                                                    color: isDark
                                                        ? const Color(0xFF64748B)
                                                        : const Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'All $_totalCount transactions loaded',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark
                                                          ? const Color(0xFF64748B)
                                                          : const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                  ),
                                );
                              }

                              int count = 0;
                              for (final group in dateGroups) {
                                if (index == count) {
                                  return _buildGroupHeader(group, isDark);
                                }
                                count++;

                                if (index < count + group.payments.length) {
                                  final payment = group.payments[index - count];
                                  return PaymentCard(
                                    payment: payment,
                                    onTap: () => _showEditDialog(payment),
                                    onEdit: () => _showEditDialog(payment),
                                    onDelete: () => _deletePayment(payment),
                                    onToggleExcluded: (val) => _toggleExcludePayment(payment, val),
                                    onAssignBudgetMonth: (bMonth) => _assignBudgetMonth(payment, bMonth),
                                  );
                                }
                                count += group.payments.length;
                              }
                              return null;
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required VoidCallback onDeleted,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.only(left: 8, right: 2, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalCount(List<DateGroup> groups) {
    return groups.fold<int>(0, (sum, g) => sum + 1 + g.payments.length);
  }

  void _handleDateGroupAction(DateGroup group, String action) async {
    final validIds = group.payments.where((p) => p.id != null).map((p) => p.id!).toList();
    if (validIds.isEmpty) return;

    if (action == 'exclude_day' || action == 'include_day') {
      final isExcluded = action == 'exclude_day';
      HapticFeedback.mediumImpact();
      await DatabaseService.instance.toggleExcludePaymentsForBatch(validIds, isExcluded);

      if (mounted) {
        setState(() {
          for (int i = 0; i < _payments.length; i++) {
            if (validIds.contains(_payments[i].id)) {
              _payments[i] = _payments[i].copyWith(isExcludedFromBudget: isExcluded);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isExcluded ? Icons.do_not_disturb_on_outlined : Icons.notifications_active_outlined,
                  color: isExcluded ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExcluded
                        ? 'Excluded ${validIds.length} transactions on ${group.displayTitle} from budget'
                        : 'Included ${validIds.length} transactions on ${group.displayTitle} in budget',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (action == 'shift_day_budget_month') {
      _showBatchBudgetMonthPicker(group, validIds);
    }
  }

  void _showBatchBudgetMonthPicker(DateGroup group, List<int> validIds) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDate = group.payments.first.date;
    final originalMonth = DateTime(firstDate.year, firstDate.month, 1);
    final nextMonth = DateTime(firstDate.year, firstDate.month + 1, 1);
    final prevMonth = DateTime(firstDate.year, firstDate.month - 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shift ${group.displayTitle} (${validIds.length} Transactions)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assign all transactions on this date to count in a specific budget month.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB)),
                  title: Text(
                    'Actual Month (${DateFormat('MMMM yyyy').format(originalMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Reset all to default payment date month', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyBatchBudgetMonth(group, validIds, null);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C3AED)),
                  title: Text(
                    'Next Month (${DateFormat('MMMM yyyy').format(nextMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('e.g. Month-end transactions budgeted for next month', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyBatchBudgetMonth(group, validIds, nextMonth);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0284C7)),
                  title: Text(
                    'Previous Month (${DateFormat('MMMM yyyy').format(prevMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('e.g. Delayed transactions for previous month', style: TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyBatchBudgetMonth(group, validIds, prevMonth);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFFEA580C)),
                  title: const Text(
                    'Custom Month...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Select another year and month', style: TextStyle(fontSize: 11.5)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final custom = await showDatePicker(
                      context: context,
                      initialDate: originalMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (custom != null) {
                      _applyBatchBudgetMonth(group, validIds, DateTime(custom.year, custom.month, 1));
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyBatchBudgetMonth(DateGroup group, List<int> validIds, DateTime? budgetMonth) async {
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.setBudgetMonthForBatch(validIds, budgetMonth);

    if (mounted) {
      setState(() {
        for (int i = 0; i < _payments.length; i++) {
          if (validIds.contains(_payments[i].id)) {
            _payments[i] = _payments[i].copyWith(
              budgetMonth: budgetMonth,
              clearBudgetMonth: budgetMonth == null,
            );
          }
        }
      });

      final monthStr = budgetMonth != null
          ? DateFormat('MMMM yyyy').format(budgetMonth)
          : DateFormat('MMMM yyyy').format(group.payments.first.date);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFF60A5FA), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Shifted ${validIds.length} transactions on ${group.displayTitle} to $monthStr budget',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildGroupHeader(DateGroup group, bool isDark) {
    final allExcluded = group.payments.every((p) => p.isExcludedFromBudget);

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 12, top: 14, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                group.displayTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${group.payments.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (group.hasShiftedTransactions) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4C1D95).withValues(alpha: 0.5)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7C3AED) : const Color(0xFFC4B5FD),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 10,
                        color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
                      ),
                      const SizedBox(width: 2.5),
                      Text(
                        'Shifted',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              if (group.totalIncome > 0 && _selectedFilterType != 'Expense')
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+₹${NumberFormat('#,##,###').format(group.totalIncome)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              if (group.totalExpense > 0 && _selectedFilterType != 'Income')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-₹${NumberFormat('#,##,###').format(group.totalExpense)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Day actions',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'shift_day_budget_month',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 17, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 10),
                        Text('Shift Day (${group.payments.length}) to Month...', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: allExcluded ? 'include_day' : 'exclude_day',
                    child: Row(
                      children: [
                        Icon(
                          allExcluded ? Icons.notifications_active_outlined : Icons.do_not_disturb_on_outlined,
                          size: 17,
                          color: allExcluded ? const Color(0xFF2563EB) : const Color(0xFFEAB308),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          allExcluded ? 'Include Day in Budget' : 'Exclude Day from Budget',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) => _handleDateGroupAction(group, val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
