import 'package:expense_tracker/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../widgets/payment_card.dart';
import '../widgets/upi_payment_dialog.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/edit_payment_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Payment> _recentPayments = [];
  double _monthlyTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final monthlyPayments = await DatabaseService.instance.getPaymentsByMonth(
        now,
      );
      final allPayments = await DatabaseService.instance.getAllPayments();

      setState(() {
        _recentPayments = allPayments.take(5).toList();
        _monthlyTotal = monthlyPayments.fold(
          0.0,
          (sum, payment) => sum + payment.amount,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showUpiPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UpiPaymentDialog(
        onPaymentInitiated: (payment) async {
          await DatabaseService.instance.addPayment(payment);
          _loadData();
        },
      ),
    );
  }

  void _showAddPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddPaymentDialog(
        onPaymentAdded: (payment) async {
          await DatabaseService.instance.addPayment(payment);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracker'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Summary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Month ($currentMonth)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${NumberFormat('#,##,###.00').format(_monthlyTotal)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Spent',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showUpiPaymentDialog,
                            icon: const Icon(Icons.payment),
                            label: const Text('Pay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showAddPaymentDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Record'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_recentPayments.length >= 5)
                          TextButton(
                            onPressed: () {
                              // Navigate to history screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => HistoryScreen(),
                                ),
                              );
                              DefaultTabController.of(context).animateTo(1);
                            },
                            child: const Text('View All'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_recentPayments.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by recording a payment or making a UPI transaction',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _recentPayments
                            .map(
                              (payment) => PaymentCard(
                                payment: payment,
                                onTap: () {
                                  _showEditPaymentDialog(payment);
                                },
                                onEdit: () => _showEditPaymentDialog(payment),
                                onDelete: () => _deletePayment(payment),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showEditPaymentDialog(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditPaymentDialog(
        payment: payment,
        onPaymentUpdated: (updatedPayment) async {
          await DatabaseService.instance.updatePayment(updatedPayment);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Are you sure you want to delete "${payment.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deletePayment(payment.id!);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${payment.description} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
