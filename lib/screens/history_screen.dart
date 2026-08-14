import 'package:flutter/material.dart';
import '../models/category.dart';
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
  String _selectedFilterType = 'All'; // 'All', 'Expense', 'Income'
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
        _filterPayments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        // Search query
        final q = _searchQuery.toLowerCase();
        final matchesSearch = payment.description.toLowerCase().contains(q) ||
            (payment.accountReference?.toLowerCase().contains(q) ?? false) ||
            (payment.notes?.toLowerCase().contains(q) ?? false);

        // Category filter
        final matchesCategory =
            _selectedCategory == 'All' || payment.category == _selectedCategory;

        // Type filter (All / Expense / Income)
        bool matchesType = true;
        if (_selectedFilterType == 'Expense') {
          matchesType = payment.type == TransactionType.debit;
        } else if (_selectedFilterType == 'Income') {
          matchesType = payment.type == TransactionType.credit;
        }

        return matchesSearch && matchesCategory && matchesType;
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
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${payment.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && payment.id != null) {
      await DatabaseService.instance.deletePayment(payment.id!);
      _loadPayments();
    }
  }

  void _showEditDialog(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPaymentDialog(
        payment: payment,
        onPaymentUpdated: (updatedPayment) async {
          await DatabaseService.instance.updatePayment(updatedPayment);
          _loadPayments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: Column(
                children: [
                  // Search & Filter Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    color: theme.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by merchant, account or notes...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20),
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
                            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                        const SizedBox(height: 10),

                        // Filter Chips Row
                        Row(
                          children: [
                            // Segmented Filter
                            Expanded(
                              flex: 3,
                              child: SegmentedButton<String>(
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                segments: const [
                                  ButtonSegment(value: 'All', label: Text('All', style: TextStyle(fontSize: 12))),
                                  ButtonSegment(value: 'Expense', label: Text('Expense', style: TextStyle(fontSize: 12))),
                                  ButtonSegment(value: 'Income', label: Text('Income', style: TextStyle(fontSize: 12))),
                                ],
                                selected: {_selectedFilterType},
                                onSelectionChanged: (set) {
                                  setState(() {
                                    _selectedFilterType = set.first;
                                    _filterPayments();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Category Dropdown
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All Categories'),
                                      ),
                                      ...Category.allCategories.map(
                                        (cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text('${Category.getIcon(cat)} $cat', overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: _onCategoryChanged,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Results Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredPayments.length} transaction${_filteredPayments.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // List of Transactions
                  Expanded(
                    child: _filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _payments.isEmpty
                                      ? 'No transactions yet'
                                      : 'No matching transactions found',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _payments.isEmpty
                                      ? 'Add transactions to see them here'
                                      : 'Try clearing your search or filters',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredPayments.length,
                            itemBuilder: (context, index) {
                              final payment = _filteredPayments[index];
                              return PaymentCard(
                                payment: payment,
                                onTap: () => _showEditDialog(payment),
                                onEdit: () => _showEditDialog(payment),
                                onDelete: () => _deletePayment(payment),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
