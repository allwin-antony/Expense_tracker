import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/payment.dart';

class AddPaymentDialog extends StatefulWidget {
  final Function(Payment) onPaymentAdded;

  const AddPaymentDialog({
    super.key,
    required this.onPaymentAdded,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _accountRefController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.debit;
  String _selectedCategory = 'Food & Dining';
  PaymentMode _selectedPaymentMode = PaymentMode.upi;
  DateTime _selectedDate = DateTime.now();
  bool _isExcludedFromBudget = false;
  DateTime? _selectedBudgetMonth;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _accountRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    }
  }

  String _getBudgetMonthDisplay() {
    if (_selectedBudgetMonth == null ||
        (_selectedBudgetMonth!.year == _selectedDate.year &&
            _selectedBudgetMonth!.month == _selectedDate.month)) {
      return 'Actual Month (${DateFormat('MMM yyyy').format(_selectedDate)})';
    }
    return '${DateFormat('MMMM yyyy').format(_selectedBudgetMonth!)} (Shifted)';
  }

  void _pickBudgetMonth() async {
    final original = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final next = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    final prev = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);

    final choice = await showModalBottomSheet<DateTime?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Count In Budget Month',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select which monthly budget and calculations will include this transaction.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB)),
                title: Text('Actual Month (${DateFormat('MMMM yyyy').format(original)})'),
                subtitle: const Text('Default for this payment date', style: TextStyle(fontSize: 11)),
                trailing: (_selectedBudgetMonth == null ||
                        (_selectedBudgetMonth!.year == original.year &&
                            _selectedBudgetMonth!.month == original.month))
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
                onTap: () => Navigator.pop(ctx, original),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C3AED)),
                title: Text('Next Month (${DateFormat('MMMM yyyy').format(next)})'),
                subtitle: const Text('e.g. Month-end salary for next month', style: TextStyle(fontSize: 11)),
                trailing: (_selectedBudgetMonth?.year == next.year && _selectedBudgetMonth?.month == next.month)
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
                onTap: () => Navigator.pop(ctx, next),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0284C7)),
                title: Text('Previous Month (${DateFormat('MMMM yyyy').format(prev)})'),
                subtitle: const Text('e.g. Delayed reimbursement', style: TextStyle(fontSize: 11)),
                trailing: (_selectedBudgetMonth?.year == prev.year && _selectedBudgetMonth?.month == prev.month)
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
                onTap: () => Navigator.pop(ctx, prev),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFFEA580C)),
                title: const Text('Custom Month...'),
                subtitle: const Text('Select another year and month', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final custom = await showDatePicker(
                    context: context,
                    initialDate: _selectedBudgetMonth ?? _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (custom != null) {
                    setState(() {
                      _selectedBudgetMonth = DateTime(custom.year, custom.month, 1);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (choice != null) {
      setState(() {
        if (choice.year == _selectedDate.year && choice.month == _selectedDate.month) {
          _selectedBudgetMonth = null;
        } else {
          _selectedBudgetMonth = DateTime(choice.year, choice.month, 1);
        }
      });
    }
  }

  void _savePayment() {
    if (_formKey.currentState!.validate()) {
      final payment = Payment(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _selectedType,
        category: _selectedCategory,
        paymentMode: _selectedPaymentMode,
        source: PaymentSource.manual,
        accountReference: _accountRefController.text.trim().isNotEmpty
            ? _accountRefController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        date: _selectedDate,
        isExcludedFromBudget: _isExcludedFromBudget,
        budgetMonth: _selectedBudgetMonth,
      );

      widget.onPaymentAdded(payment);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = _selectedType == TransactionType.credit;
    final availableCategories = isIncome
        ? Category.incomeCategories
        : Category.expenseCategories;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Add Transaction',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Expense / Income Segmented Toggle
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.debit,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward, size: 16),
                    ),
                    ButtonSegment(
                      value: TransactionType.credit,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward, size: 16),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedType = set.first;
                      _selectedCategory = _selectedType == TransactionType.credit
                          ? 'Salary'
                          : 'Food & Dining';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : theme.colorScheme.primary,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description / Merchant *',
                  hintText: 'e.g. Swiggy, Uber, Rent, Salary',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(Category.getIcon(category)),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 12),

              // Payment Mode & Date Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PaymentMode>(
                      initialValue: _selectedPaymentMode,
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: PaymentMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(mode.displayName, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPaymentMode = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Budget Month Selector Tile
              InkWell(
                onTap: _pickBudgetMonth,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Count In Budget Month',
                    helperText: 'Controls which month\'s budget & calculations include this transaction',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF7C3AED)),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  child: Text(
                    _getBudgetMonthDisplay(),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: _selectedBudgetMonth != null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedBudgetMonth != null ? const Color(0xFF7C3AED) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Account Reference Field
              TextFormField(
                controller: _accountRefController,
                decoration: InputDecoration(
                  labelText: 'Account / Card (Optional)',
                  hintText: 'e.g. HDFC A/c XX4021',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Exclude from Budget Toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Exclude from Calculations',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Saved in history, but ignored in monthly balance and analytics.',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  secondary: const Icon(Icons.do_not_disturb_on_outlined, size: 22),
                  value: _isExcludedFromBudget,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  onChanged: (val) {
                    setState(() => _isExcludedFromBudget = val);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _savePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isIncome ? Colors.green : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
