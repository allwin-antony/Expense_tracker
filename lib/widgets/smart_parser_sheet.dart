import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/payment.dart';
import '../parser/message_parser_pipeline.dart';

class SmartParserSheet extends StatefulWidget {
  final Function(Payment) onPaymentParsedAndSaved;

  const SmartParserSheet({
    super.key,
    required this.onPaymentParsedAndSaved,
  });

  @override
  State<SmartParserSheet> createState() => _SmartParserSheetState();
}

class _SmartParserSheetState extends State<SmartParserSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _accountRefController = TextEditingController();

  ParsedTransactionResult? _parsedResult;
  TransactionType _selectedType = TransactionType.debit;
  String _selectedCategory = 'Food & Dining';
  PaymentMode _selectedPaymentMode = PaymentMode.upi;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _accountRefController.dispose();
    super.dispose();
  }

  void _onTextUpdated(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedResult = null;
      });
      return;
    }

    final result = MessageParserPipeline.instance.parse(
      text,
      source: PaymentSource.clipboard,
    );

    setState(() {
      _parsedResult = result;
      if (result.isSuccess && result.payment != null) {
        final p = result.payment!;
        _selectedType = p.type;
        _amountController.text = p.amount.toStringAsFixed(2);
        _merchantController.text = p.description;
        _selectedCategory = p.category;
        _selectedPaymentMode = p.paymentMode;
        _accountRefController.text = p.accountReference ?? '';
        _selectedDate = p.date;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _textController.text = data.text!;
      _onTextUpdated(data.text!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
    }
  }

  void _loadSample(String sampleText) {
    _textController.text = sampleText;
    _onTextUpdated(sampleText);
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text) ?? _parsedResult?.payment?.amount ?? 0.0;
    final merchant = _merchantController.text.trim().isNotEmpty
        ? _merchantController.text.trim()
        : (_parsedResult?.payment?.description ?? 'Transaction');

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final payment = Payment(
      description: merchant,
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      paymentMode: _selectedPaymentMode,
      source: PaymentSource.clipboard,
      accountReference: _accountRefController.text.trim().isNotEmpty
          ? _accountRefController.text.trim()
          : null,
      rawMessage: _textController.text.trim(),
      confidence: _parsedResult?.confidence ?? 1.0,
      date: _selectedDate,
    );

    widget.onPaymentParsedAndSaved(payment);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart SMS & Alert Parser',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Auto-extract amounts, merchants & categories',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Input Box
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Paste SMS, UPI notification, or bank message text here...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: _pasteFromClipboard,
                ),
              ),
              onChanged: _onTextUpdated,
            ),
            const SizedBox(height: 8),

            // Quick Samples Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('💡 Swiggy UPI', style: TextStyle(fontSize: 11)),
                  onPressed: () => _loadSample(
                    'Rs.450.00 debited from HDFC Bank A/c XX4021 to SWIGGY on 14-Aug via UPI Ref 422891829102.',
                  ),
                ),
                ActionChip(
                  label: const Text('🛒 Amazon Card', style: TextStyle(fontSize: 11)),
                  onPressed: () => _loadSample(
                    'INR 1,899.00 spent on ICICI Bank Card ending 4402 at AMAZON INDIA.',
                  ),
                ),
                ActionChip(
                  label: const Text('💼 Salary Credit', style: TextStyle(fontSize: 11)),
                  onPressed: () => _loadSample(
                    'Your SBI A/c XX1234 is credited with Rs 75,000.00 by Salary Payroll.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parsed Result Card
            if (_parsedResult != null && _parsedResult!.isSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedType == TransactionType.credit
                        ? Colors.green.shade400
                        : theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence and Type Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Type Segmented Toggle
                        SegmentedButton<TransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.debit,
                              label: Text('Expense', style: TextStyle(fontSize: 12)),
                              icon: Icon(Icons.arrow_upward, size: 14),
                            ),
                            ButtonSegment(
                              value: TransactionType.credit,
                              label: Text('Income', style: TextStyle(fontSize: 12)),
                              icon: Icon(Icons.arrow_downward, size: 14),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (set) {
                            setState(() {
                              _selectedType = set.first;
                              if (_selectedType == TransactionType.credit &&
                                  !Category.incomeCategories.contains(_selectedCategory)) {
                                _selectedCategory = 'Other Income';
                              } else if (_selectedType == TransactionType.debit &&
                                  !Category.expenseCategories.contains(_selectedCategory)) {
                                _selectedCategory = 'Food & Dining';
                              }
                            });
                          },
                        ),
                        // AI Authenticity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade300.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_outlined, color: Colors.teal, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'AI Verified • ${((_parsedResult?.confidence ?? 0.9) * 100).toInt()}% Match',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount & Merchant fields
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == TransactionType.credit
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount (₹)',
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _merchantController,
                            decoration: InputDecoration(
                              labelText: 'Merchant / Title',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    DropdownButtonFormField<String>(
                      initialValue: Category.allCategories.contains(_selectedCategory)
                          ? _selectedCategory
                          : (_selectedType == TransactionType.credit ? 'Other Income' : 'Other Expense'),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: (_selectedType == TransactionType.credit
                              ? Category.incomeCategories
                              : Category.expenseCategories)
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Text(Category.getIcon(category), style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(category, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Payment Mode & Account Ref Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentMode>(
                            initialValue: _selectedPaymentMode,
                            decoration: InputDecoration(
                              labelText: 'Mode',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: PaymentMode.values.map((mode) {
                              return DropdownMenuItem(
                                value: mode,
                                child: Text(mode.displayName, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (mode) {
                              if (mode != null) setState(() => _selectedPaymentMode = mode);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _accountRefController,
                            decoration: InputDecoration(
                              labelText: 'Account / Card',
                              hintText: 'e.g. HDFC XX1234',
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1-Tap Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == TransactionType.credit
                              ? Colors.green
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveTransaction,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_textController.text.isNotEmpty) ...[
              // Error notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _parsedResult?.errorMessage ?? 'Could not detect financial data. Please check the text.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
