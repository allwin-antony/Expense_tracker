import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/sms_sync_service.dart';
import '../utils/date_group_helper.dart';
import '../widgets/payment_card.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/edit_payment_dialog.dart';
import '../widgets/sms_sync_dialog.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;

  const HomeScreen({super.key, this.onNavigateToHistory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Payment> _payments = [];
  double _monthlyExpense = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyBalance = 0.0;
  int _totalCount = 0;

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    _initLiveSmsListener();
    DatabaseService.instance.dataChangeNotifier.addListener(_onExternalDataChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    DatabaseService.instance.dataChangeNotifier.removeListener(_onExternalDataChanged);
    super.dispose();
  }

  void _onExternalDataChanged() {
    if (mounted) {
      _updateMonthlyMetrics();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoadingInitial) {
      _loadMorePayments();
    }
  }

  void _initLiveSmsListener() {
    SmsSyncService.instance.startLiveSmsListener(
      onPaymentCaptured: (payment) {
        if (mounted) {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-captured: ${payment.description} (₹${payment.amount.toStringAsFixed(2)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
    });

    try {
      final now = DateTime.now();
      final expense = await DatabaseService.instance.getTotalExpenseForMonth(now);
      final income = await DatabaseService.instance.getTotalIncomeForMonth(now);
      final balance = income - expense;
      final total = await DatabaseService.instance.getPaymentCount();

      final firstPage = await DatabaseService.instance.getPaymentsPaginated(
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _payments = firstPage;
          _monthlyExpense = expense;
          _monthlyIncome = income;
          _monthlyBalance = balance;
          _totalCount = total;
          _hasMore = firstPage.length < total;
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadMorePayments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = await DatabaseService.instance.getPaymentsPaginated(
        limit: _pageSize,
        offset: _payments.length,
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

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadInitialData();
  }

  void _showSmsSyncDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmsSyncDialog(
        onSyncCompleted: () {
          _refreshData();
        },
      ),
    );
  }

  Future<void> _updateMonthlyMetrics() async {
    try {
      final now = DateTime.now();
      final expense = await DatabaseService.instance.getTotalExpenseForMonth(now);
      final income = await DatabaseService.instance.getTotalIncomeForMonth(now);
      final balance = income - expense;
      if (mounted) {
        setState(() {
          _monthlyExpense = expense;
          _monthlyIncome = income;
          _monthlyBalance = balance;
        });
      }
    } catch (_) {}
  }

  void _showAddPaymentDialog() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentDialog(
        onPaymentAdded: (payment) async {
          await DatabaseService.instance.addPayment(payment);
          _refreshData();
        },
      ),
    );
  }

  void _showEditPaymentDialog(Payment payment) {
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
            _updateMonthlyMetrics();
          }
        },
      ),
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
      await DatabaseService.instance.deletePayment(payment.id!);
      if (mounted) {
        setState(() {
          _payments.removeWhere((p) => p.id == payment.id);
          _totalCount = (_totalCount - 1).clamp(0, 999999);
        });
        _updateMonthlyMetrics();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleExcludePayment(Payment payment, bool isExcluded) async {
    if (payment.id == null) return;
    HapticFeedback.mediumImpact();
    await DatabaseService.instance.toggleExcludePayment(payment.id!, isExcluded);

    // In-place list & balance update to preserve scroll position
    if (mounted) {
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        setState(() {
          _payments[index] = payment.copyWith(isExcludedFromBudget: isExcluded);
        });
      }
      _updateMonthlyMetrics();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isExcluded ? Icons.do_not_disturb_on_outlined : Icons.notifications_active_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isExcluded
                      ? 'Excluded from budget calculations'
                      : 'Included in budget calculations',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      _updateMonthlyMetrics();

      final monthStr = budgetMonth != null
          ? DateFormat('MMMM yyyy').format(budgetMonth)
          : DateFormat('MMMM yyyy').format(payment.date);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Counted in $monthStr budget'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

    // Date grouping of currently loaded payments
    final dateGroups = DateGroupHelper.groupByDate(_payments);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Budget Tracker',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              currentMonthName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoadingInitial
          ? RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 8),
                  ShimmerHeroCardSkeleton(),
                  SizedBox(height: 16),
                  ShimmerTransactionSkeleton(),
                  ShimmerTransactionSkeleton(),
                  ShimmerTransactionSkeleton(),
                  ShimmerTransactionSkeleton(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Hero Balance Card & Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Glassmorphism / Gradient Hero Balance Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFF1E40AF), const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Colors.black : const Color(0xFF2563EB))
                                      .withValues(alpha: isDark ? 0.4 : 0.28),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Monthly Balance',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 11,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM yyyy').format(DateTime.now()),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${NumberFormat('#,##,###.00').format(_monthlyBalance)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 14),

                                // Income & Expense Split
                                Row(
                                  children: [
                                    // Income
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_downward_rounded,
                                              color: Color(0xFF6EE7B7),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Income',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.75),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${NumberFormat('#,##,###').format(_monthlyIncome)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                    const SizedBox(width: 12),

                                    // Expense
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Color(0xFFFCA5A5),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Expense',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.75),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${NumberFormat('#,##,###').format(_monthlyExpense)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Hero Action: Auto-Sync Month's SMS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: InkWell(
                              onTap: _showSmsSyncDialog,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.auto_mode_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Auto-Sync Bank SMS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Scan & import SMS (This Month, Last Month, etc.)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Quick Action: Add Transaction
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text(
                                'Add Transaction Manually',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                                ),
                              ),
                              onPressed: _showAddPaymentDialog,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Recent Transactions Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Transactions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (_payments.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_payments.length} of $_totalCount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transactions List (Date Grouped)
                  if (_payments.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No transactions recorded yet',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "Auto-Sync Month\'s SMS" above to import your transactions from your bank messages.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Flatten date groups into header + cards
                          int count = 0;
                          for (final group in dateGroups) {
                            // Header index
                            if (index == count) {
                              return _buildDateGroupHeader(group, isDark);
                            }
                            count++;

                            // Card items in this group
                            if (index < count + group.payments.length) {
                              final payment = group.payments[index - count];
                              return PaymentCard(
                                payment: payment,
                                onTap: () => _showEditPaymentDialog(payment),
                                onEdit: () => _showEditPaymentDialog(payment),
                                onDelete: () => _deletePayment(payment),
                                onToggleExcluded: (val) => _toggleExcludePayment(payment, val),
                                onAssignBudgetMonth: (bMonth) => _assignBudgetMonth(payment, bMonth),
                              );
                            }
                            count += group.payments.length;
                          }

                          return null;
                        },
                        childCount: _calculateTotalSliverCount(dateGroups),
                      ),
                    ),

                  // Loading More Spinner / All Caught Up Footer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: _isLoadingMore
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
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
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              )
                            : (_payments.isNotEmpty && !_hasMore)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'All $_totalCount transactions loaded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Bottom padding for scroll clearance
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
    );
  }

  int _calculateTotalSliverCount(List<DateGroup> groups) {
    int total = 0;
    for (final group in groups) {
      total += 1 + group.payments.length; // 1 header + items
    }
    return total;
  }

  Widget _buildDateGroupHeader(DateGroup group, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
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
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  letterSpacing: -0.1,
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
            ],
          ),
          if (group.totalExpense > 0 || group.totalIncome > 0)
            Text(
              group.totalExpense > 0
                  ? '-₹${NumberFormat('#,##,###.00').format(group.totalExpense)}'
                  : '+₹${NumberFormat('#,##,###.00').format(group.totalIncome)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: group.totalExpense > 0
                    ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                    : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
              ),
            ),
        ],
      ),
    );
  }
}
