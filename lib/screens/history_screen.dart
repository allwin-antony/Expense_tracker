import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../widgets/payment_card.dart';
import '../widgets/edit_payment_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final payments = await DatabaseService.instance.getAllPayments();
      setState(() {
        _payments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        final matchesSearch = payment.description.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesCategory =
            _selectedCategory == 'All' || payment.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterPayments();
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category ?? 'All');
    _filterPayments();
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
      _loadPayments();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ..._payments.map((p) => p.category).toSet()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _onCategoryChanged(category),
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: theme.colorScheme.primaryContainer,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty || _selectedCategory != 'All'
                              ? Icons.search_off
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != 'All'
                              ? 'No matching payments found'
                              : 'No payments recorded yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredPayments.length,
                      itemBuilder: (context, index) {
                        final payment = _filteredPayments[index];
                        return PaymentCard(
                          payment: payment,
                          onTap: () {
                            _showEditPaymentDialog(payment);
                          },
                          onEdit: () => _showEditPaymentDialog(payment),
                          onDelete: () => _deletePayment(payment),
                        );
                      },
                    ),
                  ),
          ),
        ],
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
          _loadPayments();
        },
      ),
    );
  }
}
