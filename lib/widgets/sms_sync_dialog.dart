import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  SmsSyncRange _selectedRange = SmsSyncRange.thisMonth;
  DateTimeRange? _customDateRange;

  bool _isSyncing = false;
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  SyncResult? _result;

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      helpText: 'Select Date Range for SMS Sync',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedRange = SmsSyncRange.customRange;
      });
    }
  }

  Future<void> _startSync() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSyncing = true;
      _progress = 0.0;
      _statusMessage = 'Reading SMS inbox...';
      _result = null;
    });

    final (start, end) = _selectedRange.getDates(customDateRange: _customDateRange);
    final maxCount = _selectedRange == SmsSyncRange.allTime ? 3000 : 1500;

    final result = await SmsSyncService.instance.syncTransactions(
      startDate: start,
      endDate: end,
      maxCount: maxCount,
      timeRangeLabel: _selectedRange == SmsSyncRange.customRange && _customDateRange != null
          ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_customDateRange!.end)}'
          : _selectedRange.label,
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
        _isSyncing = false;
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _isSyncing
                      ? theme.colorScheme.primaryContainer
                      : (_result == null
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : (_result!.isSuccess
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15))),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isSyncing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          _result == null
                              ? Icons.sync_rounded
                              : (_result!.isSuccess
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.error_outline_rounded),
                          color: _result == null
                              ? theme.colorScheme.primary
                              : (_result!.isSuccess ? Colors.green : Colors.red),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                _isSyncing
                    ? 'Syncing SMS Messages...'
                    : (_result == null
                        ? 'Auto-Sync Bank SMS'
                        : (_result!.isSuccess ? 'Sync Complete!' : 'Sync Failed')),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // State 1: Range Selection (Before Syncing)
              if (!_isSyncing && _result == null) ...[
                Text(
                  'Choose the time period of SMS messages you want to scan and import.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Range Selector Options
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: SmsSyncRange.values.map((range) {
                      final isSelected = _selectedRange == range;
                      final isCustom = range == SmsSyncRange.customRange;

                      String subtitleText = range.subtitle;
                      if (isCustom && _customDateRange != null) {
                        subtitleText =
                            '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_customDateRange!.end)}';
                      }

                      return InkWell(
                        onTap: () async {
                          if (isCustom) {
                            await _selectCustomRange();
                          } else {
                            setState(() => _selectedRange = range);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      range.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Text(
                                      subtitleText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCustom)
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _startSync,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ]

              // State 2: Syncing in Progress
              else if (_isSyncing) ...[
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Running in a background isolate to keep your device smooth.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ]

              // State 3: Sync Result Success
              else if (_result != null && _result!.isSuccess) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Period: ${_result!.timeRangeLabel ?? _selectedRange.label}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('Messages Scanned', '${_result!.totalSmsRead}', Icons.mail_outline),
                      const Divider(height: 14),
                      _buildStatRow('Financial SMS Detected', '${_result!.financialSmsFound}', Icons.receipt_long_outlined),
                      const Divider(height: 14),
                      _buildStatRow(
                        'New Transactions Added',
                        '+${_result!.newTransactionsAdded}',
                        Icons.add_circle_outline,
                        valueColor: Colors.green,
                        isBold: true,
                      ),
                      if (_result!.duplicatesSkipped > 0) ...[
                        const Divider(height: 14),
                        _buildStatRow(
                          'Duplicates Skipped',
                          '${_result!.duplicatesSkipped}',
                          Icons.content_copy_outlined,
                          valueColor: Colors.grey.shade500,
                        ),
                      ],
                      if (_result!.totalExpenseAdded > 0 || _result!.totalIncomeAdded > 0) ...[
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Imported Expenses:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###.00').format(_result!.totalExpenseAdded)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _result = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sync Another'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ]

              // State 4: Error State
              else ...[
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
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
