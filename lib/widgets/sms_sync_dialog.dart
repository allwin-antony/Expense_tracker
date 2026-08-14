import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sms_sync_service.dart';

class SmsSyncDialog extends StatefulWidget {
  final VoidCallback onSyncCompleted;

  const SmsSyncDialog({
    super.key,
    required this.onSyncCompleted,
  });

  @override
  State<SmsSyncDialog> createState() => _SmsSyncDialogState();
}

class _SmsSyncDialogState extends State<SmsSyncDialog> {
  bool _isLoading = true;
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  SyncResult? _result;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Reading SMS inbox...';
      _result = null;
    });

    final result = await SmsSyncService.instance.syncMonthTransactions(
      targetMonth: DateTime.now(),
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statusMessage = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = result;
      });
      if (result.isSuccess && result.newTransactionsAdded > 0) {
        widget.onSyncCompleted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isLoading
                    ? theme.colorScheme.primaryContainer
                    : (_result?.isSuccess == true
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(
                        _result?.isSuccess == true
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _result?.isSuccess == true ? Colors.green : Colors.red,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _isLoading
                  ? 'Auto-Syncing Month\'s SMS'
                  : (_result?.isSuccess == true ? 'Sync Complete!' : 'Sync Failed'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Status message / Progress
            if (_isLoading) ...[
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 6,
                ),
              ),
            ] else if (_result != null && _result!.isSuccess) ...[
              Text(
                'Scanned current month\'s messages without freezing your device.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Messages Scanned', '${_result!.totalSmsRead}', Icons.mail_outline),
                    const Divider(height: 16),
                    _buildStatRow('Financial SMS Detected', '${_result!.financialSmsFound}', Icons.receipt_long_outlined),
                    const Divider(height: 16),
                    _buildStatRow(
                      'New Transactions Added',
                      '+${_result!.newTransactionsAdded}',
                      Icons.add_circle_outline,
                      valueColor: Colors.green,
                      isBold: true,
                    ),
                    if (_result!.duplicatesSkipped > 0) ...[
                      const Divider(height: 16),
                      _buildStatRow(
                        'Duplicates Skipped',
                        '${_result!.duplicatesSkipped}',
                        Icons.content_copy_outlined,
                        valueColor: Colors.grey.shade600,
                      ),
                    ],
                    if (_result!.totalExpenseAdded > 0 || _result!.totalIncomeAdded > 0) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('New Expenses:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(
                            '₹${NumberFormat('#,##,###.00').format(_result!.totalExpenseAdded)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Transactions'),
                ),
              ),
            ] else ...[
              // Error / Permission state
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      _result?.errorMessage ?? 'SMS permission is required to automatically detect bank messages.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Open App Permissions in Settings'),
                      onPressed: () async {
                        await SmsSyncService.instance.openSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startSync,
                      child: const Text('Retry Sync'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
