import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/upi_applications.dart';
import '../services/upi_apps_service.dart';
import '../screens/qr_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment.dart';
import '../models/category.dart';

/// Payment mode for the UPI dialog.
enum PaymentMode { scanQr, directPay, copyAmount }

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
  PaymentMode _paymentMode = PaymentMode.scanQr;
  List<Map<String, String>> _recentPayees = [];

  // QR scan state
  bool _isQrScanned = false;
  bool _isAmountFromQr = false;
  String? _rawQrUri; // The original URI from the QR code

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

  /// Launch the QR scanner and handle the result.
  Future<void> _launchQrScanner() async {
    final result = await Navigator.of(context).push<UpiQrData?>(
      MaterialPageRoute(builder: (context) => const QrScanScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _isQrScanned = true;
        _rawQrUri = result.rawUri;
        _upiIdController.text = result.payeeAddress;
        _payeeNameController.text = result.payeeName;

        if (result.amount != null && result.amount!.isNotEmpty) {
          _amountController.text = result.amount!;
          _isAmountFromQr = true;
        } else {
          _isAmountFromQr = false;
        }

        if (result.transactionNote != null && result.transactionNote!.isNotEmpty) {
          _descriptionController.text = result.transactionNote!;
        }
      });
    }
  }

  void _clearQrScan() {
    setState(() {
      _isQrScanned = false;
      _isAmountFromQr = false;
      _rawQrUri = null;
      _upiIdController.clear();
      _payeeNameController.clear();
      _amountController.clear();
      _descriptionController.clear();
    });
  }

  /// Build the UPI URL for a payment.
  /// For QR scans: pass through the original URI, optionally adding/overriding amount.
  /// For Direct Pay: construct a new URI with proper formatting.
  String _buildUpiUrl() {
    if (_isQrScanned && _rawQrUri != null) {
      // Parse the original QR URI and optionally add/override amount
      final originalUri = Uri.parse(_rawQrUri!);
      final params = Map<String, String>.from(originalUri.queryParameters);

      // If the QR didn't have an amount, add the user-entered one
      if (!_isAmountFromQr && _amountController.text.isNotEmpty) {
        params['am'] = double.parse(_amountController.text).toStringAsFixed(2);
      }

      // Ensure a transaction reference exists
      if (!params.containsKey('tr') || params['tr']!.isEmpty) {
        params['tr'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final uri = Uri(
        scheme: originalUri.scheme,
        host: originalUri.host,
        path: originalUri.path,
        queryParameters: params,
      );
      return uri.toString();
    } else {
      // Direct Pay: construct URI from scratch
      final upiId = _upiIdController.text.trim();
      final name = _payeeNameController.text.trim();
      final amount = _amountController.text;
      final note = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Expense';

      final uri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': upiId,
          'pn': name.isNotEmpty ? name : 'Payee',
          'am': double.parse(amount).toStringAsFixed(2),
          'cu': 'INR',
          'tn': note,
          'tr': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return uri.toString();
    }
  }

  void _initiatePayment() {
    if (_formKey.currentState!.validate()) {
      if (_paymentMode == PaymentMode.copyAmount) {
        // Copy amount to clipboard for clipboard copy mode
        Clipboard.setData(ClipboardData(text: _amountController.text));
      }

      // Show UPI apps selection
      _showUpiAppsDialog();
    }
  }

  void _showUpiAppsDialog() {
    final isDeepLink = _paymentMode != PaymentMode.copyAmount;

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
                  isDeepLink ? Icons.check_circle : Icons.content_copy,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDeepLink
                        ? 'Ready to initiate payment!'
                        : 'Amount copied to clipboard!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                          
                          if (isDeepLink) {
                            final upiUrl = _buildUpiUrl();
                            
                            // Save to recent payees list
                            await _saveRecentPayee(
                              _upiIdController.text.trim(),
                              _payeeNameController.text.trim(),
                            );
                            
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
    final isDeepLink = _paymentMode != PaymentMode.copyAmount;

    final payment = Payment(
      description: _descriptionController.text.trim().isEmpty
          ? (isDeepLink && _payeeNameController.text.trim().isNotEmpty
              ? _payeeNameController.text.trim()
              : 'Payment')
          : _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? (isDeepLink ? 'To UPI ID: ${_upiIdController.text.trim()}' : null)
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
    final showRecipientFields = _paymentMode != PaymentMode.copyAmount;

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
                        
                        // 3-mode Segmented Control
                        Center(
                          child: SegmentedButton<PaymentMode>(
                            segments: const [
                              ButtonSegment<PaymentMode>(
                                value: PaymentMode.scanQr,
                                icon: Icon(Icons.qr_code_scanner),
                                label: Text('Scan QR'),
                              ),
                              ButtonSegment<PaymentMode>(
                                value: PaymentMode.directPay,
                                icon: Icon(Icons.bolt),
                                label: Text('Direct Pay'),
                              ),
                              ButtonSegment<PaymentMode>(
                                value: PaymentMode.copyAmount,
                                icon: Icon(Icons.content_copy),
                                label: Text('Copy'),
                              ),
                            ],
                            selected: {_paymentMode},
                            onSelectionChanged: (Set<PaymentMode> newSelection) {
                              setState(() {
                                _paymentMode = newSelection.first;
                                // Clear QR state when switching away from Scan QR
                                if (_paymentMode != PaymentMode.scanQr) {
                                  _isQrScanned = false;
                                  _isAmountFromQr = false;
                                  _rawQrUri = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Scan QR button (only in Scan QR mode)
                        if (_paymentMode == PaymentMode.scanQr) ...[
                          if (!_isQrScanned) ...[
                            // Scan button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _launchQrScanner,
                                icon: const Icon(Icons.qr_code_scanner, size: 28),
                                label: const Text(
                                  'Open Camera & Scan QR',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Scan a UPI QR code to auto-fill payment details',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            // Scanned indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Scanned from QR ✓',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _upiIdController.text,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      _clearQrScan();
                                      _launchQrScanner();
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Re-scan'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          readOnly: _isAmountFromQr,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            border: const OutlineInputBorder(),
                            suffixIcon: _isAmountFromQr
                                ? Tooltip(
                                    message: 'Amount set by merchant QR',
                                    child: Icon(
                                      Icons.lock,
                                      size: 18,
                                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                    ),
                                  )
                                : null,
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

                        // Recipient fields (Scan QR or Direct Pay modes)
                        if (showRecipientFields) ...[
                          if (_paymentMode == PaymentMode.directPay) ...[
                            TextFormField(
                              controller: _upiIdController,
                              decoration: const InputDecoration(
                                labelText: 'Recipient UPI ID',
                                hintText: 'e.g. name@bank',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (value) {
                                if (_paymentMode == PaymentMode.directPay) {
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

                          // For Scan QR mode: show validation for amount when QR is scanned
                          if (_paymentMode == PaymentMode.scanQr && _isQrScanned) ...[
                            // Show payee name if available
                            if (_payeeNameController.text.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'To: ${_payeeNameController.text}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
                      onPressed: _isLoadingApps
                          ? null
                          : (_paymentMode == PaymentMode.scanQr && !_isQrScanned)
                              ? _launchQrScanner
                              : _initiatePayment,
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
                          : Text(
                              (_paymentMode == PaymentMode.scanQr && !_isQrScanned)
                                  ? 'Scan QR Code'
                                  : 'Initiate Payment',
                              style: const TextStyle(
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
