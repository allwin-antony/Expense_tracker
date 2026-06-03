import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/upi_applications.dart';
import '../services/upi_apps_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment.dart';
import '../models/category.dart';

class UpiPaymentDialog extends StatefulWidget {
  final Function(Payment) onPaymentInitiated;

  const UpiPaymentDialog({super.key, required this.onPaymentInitiated});

  @override
  State<UpiPaymentDialog> createState() => _UpiPaymentDialogState();
}

class _UpiPaymentDialogState extends State<UpiPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _payeeNameController = TextEditingController();

  String _selectedCategory = Category.defaultCategories[0];
  late Future<List<UpiApplication>> _upiApps;
  bool _isLoadingApps = false;
  bool _isDirectPayment = true;
  List<Map<String, String>> _recentPayees = [];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _upiIdController.dispose();
    _payeeNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUpiApps();
    _loadRecentPayees();
  }

  Future<void> _loadRecentPayees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payeesJson = prefs.getStringList('recent_payees') ?? [];
      setState(() {
        _recentPayees = payeesJson.map((jsonStr) {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          return {
            'upiId': map['upiId']?.toString() ?? '',
            'name': map['name']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading recent payees: $e');
    }
  }

  Future<void> _saveRecentPayee(String upiId, String name) async {
    if (upiId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payeesJson = prefs.getStringList('recent_payees') ?? [];

      // Remove duplicate if exists
      payeesJson.removeWhere((jsonStr) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return map['upiId'] == upiId;
      });

      // Add to beginning of list
      payeesJson.insert(0, json.encode({'upiId': upiId, 'name': name}));

      // Cap size at 10 items
      if (payeesJson.length > 10) {
        payeesJson.removeLast();
      }

      await prefs.setStringList('recent_payees', payeesJson);
      await _loadRecentPayees();
    } catch (e) {
      print('Error saving recent payee: $e');
    }
  }

  Future<void> _loadUpiApps() async {
    setState(() => _isLoadingApps = true);
    try {
      final apps = UPIAppsService.getInstalledUpiApps();
      setState(() {
        _upiApps = apps;
        _isLoadingApps = false;
      });
    } catch (e) {
      setState(() => _isLoadingApps = false);
    }
  }

  void _initiatePayment() {
    if (_formKey.currentState!.validate()) {
      if (!_isDirectPayment) {
        // Copy amount to clipboard for clipboard copy mode
        Clipboard.setData(ClipboardData(text: _amountController.text));
      }

      // Show UPI apps selection
      _showUpiAppsDialog();
    }
  }

  void _showUpiAppsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isDirectPayment
                      ? 'Ready to initiate direct payment!'
                      : 'Amount copied to clipboard!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose UPI App',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UpiApplication>>(
                future: _upiApps,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading UPI apps');
                  }
                  final apps = snapshot.data ?? [];
                  if (apps.isEmpty) {
                    return const Text(
                      'No UPI apps found. Please install a UPI app first.',
                    );
                  }
                  return ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        leading:
                            (app.iconBase64 != null &&
                                app.iconBase64!.isNotEmpty)
                            ? Image.memory(
                                base64Decode(app.iconBase64!),
                                width: 32,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.payment),
                              )
                            : const Icon(Icons.payment),
                        title: Text(app.appName),
                        onTap: () async {
                          Navigator.pop(context);
                          
                          if (_isDirectPayment) {
                            final upiId = _upiIdController.text.trim();
                            final name = _payeeNameController.text.trim();
                            final amount = _amountController.text;
                            final note = _descriptionController.text.trim().isNotEmpty
                                ? _descriptionController.text.trim()
                                : 'Expense';
                            
                            final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(name)}&am=$amount&cu=INR&tn=${Uri.encodeComponent(note)}';
                            
                            // Save to recent payees list
                            await _saveRecentPayee(upiId, name);
                            
                            // Launch custom deep link
                            await UPIAppsService.launchUpiUrl(app, upiUrl);
                          } else {
                            await UPIAppsService.launchUpiApp(app);
                          }

                          _showManualConfirmation();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmPayment();
                },
                child: const Text('Mark as Paid (Manual)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Status'),
        content: const Text('Did you complete the payment successfully?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmPayment();
            },
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() {
    final payment = Payment(
      description: _descriptionController.text.trim().isEmpty
          ? (_isDirectPayment && _payeeNameController.text.trim().isNotEmpty
              ? _payeeNameController.text.trim()
              : 'Payment')
          : _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? (_isDirectPayment ? 'To UPI ID: ${_upiIdController.text.trim()}' : null)
          : _notesController.text.trim(),
      isInitiated: true,
    );

    widget.onPaymentInitiated(payment);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of ₹${_amountController.text} initiated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Initiate UPI Payment',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Toggle Segmented Control
                        Center(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.bolt),
                                label: Text('Direct Pay'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.content_copy),
                                label: Text('Copy Amount'),
                              ),
                            ],
                            selected: {_isDirectPayment},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _isDirectPayment = newSelection.first;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (_isDirectPayment) ...[
                          TextFormField(
                            controller: _upiIdController,
                            decoration: const InputDecoration(
                              labelText: 'Recipient UPI ID',
                              hintText: 'e.g. name@bank',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) {
                              if (_isDirectPayment) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a UPI ID';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid UPI ID (e.g. user@bank)';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _payeeNameController,
                            decoration: const InputDecoration(
                              labelText: 'Recipient Name (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_recentPayees.isNotEmpty) ...[
                            Text(
                              'Recent Payees',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentPayees.length,
                                itemBuilder: (context, index) {
                                  final payee = _recentPayees[index];
                                  final displayName = payee['name']!.isNotEmpty
                                      ? payee['name']!
                                      : payee['upiId']!;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ActionChip(
                                      avatar: CircleAvatar(
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      label: Text(displayName),
                                      onPressed: () {
                                        setState(() {
                                          _upiIdController.text = payee['upiId']!;
                                          _payeeNameController.text = payee['name']!;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: Category.defaultCategories.map((category) {
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
                            setState(() => _selectedCategory = value!);
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingApps ? null : _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoadingApps
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Initiate Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
