import 'dart:convert';
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
  String _selectedCategory = Category.defaultCategories[0];
  late Future<List<UpiApplication>> _upiApps;
  bool _isLoadingApps = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUpiApps();
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
      // Copy amount to clipboard
      Clipboard.setData(ClipboardData(text: _amountController.text));

      // Show UPI apps selection
      _showUpiAppsDialog();
    }
  }

  // ...existing code...
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
                const Text(
                  'Amount copied to clipboard!',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
            // Make the list take available space and scroll
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
                        onTap: () {
                          Navigator.pop(context);
                          UPIAppsService.launchUpiApp(app);
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

  // Future<void> _launchUpiApp(ApplicationMeta app) async {
  //   try {
  //     // Simply open the UPI app without initiating any transaction
  //     await app.toString();

  //     // After opening the app, show confirmation dialog
  //     _showManualConfirmation();
  //   } catch (e) {
  //     // If opening fails, show manual confirmation
  //     _showManualConfirmation();
  //   }
  // }

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
          ? 'Payment'
          : _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isInitiated: true,
    );

    widget.onPaymentInitiated(payment);
    Navigator.of(context).pop();

    // Show confirmation snackbar
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Initiate UPI Payment',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

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

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
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

                  const Spacer(),

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
