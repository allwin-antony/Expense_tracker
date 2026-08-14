import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/payment.dart';
import '../parser/message_parser_pipeline.dart';
import 'database_service.dart';

class SyncResult {
  final bool isSuccess;
  final int totalSmsRead;
  final int financialSmsFound;
  final int newTransactionsAdded;
  final int duplicatesSkipped;
  final double totalExpenseAdded;
  final double totalIncomeAdded;
  final String? errorMessage;

  SyncResult({
    required this.isSuccess,
    this.totalSmsRead = 0,
    this.financialSmsFound = 0,
    this.newTransactionsAdded = 0,
    this.duplicatesSkipped = 0,
    this.totalExpenseAdded = 0.0,
    this.totalIncomeAdded = 0.0,
    this.errorMessage,
  });

  factory SyncResult.failure(String message) {
    return SyncResult(isSuccess: false, errorMessage: message);
  }
}


class SmsSyncService {
  static final SmsSyncService instance = SmsSyncService._();
  SmsSyncService._();

  static const EventChannel _smsEventChannel =
      EventChannel('com.finance.expense_tracker/sms_stream');
  StreamSubscription? _liveSmsSubscription;

  /// Request SMS read and receive permissions gracefully
  Future<bool> requestPermissions() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;

    final result = await Permission.sms.request();
    return result.isGranted;
  }

  /// Open app settings if permission is permanently denied
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Top-level function executed in a background isolate for zero UI lag
  static List<Map<String, dynamic>> _parseSmsBatch(List<Map<String, dynamic>> rawItems) {
    final List<Map<String, dynamic>> parsedResults = [];

    for (final item in rawItems) {
      final body = item['body'] as String? ?? '';
      final timestamp = item['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (body.isEmpty) continue;

      final parseResult = MessageParserPipeline.instance.parse(
        body,
        source: PaymentSource.sms,
      );

      if (parseResult.isSuccess && parseResult.payment != null) {
        final paymentWithDate = parseResult.payment!.copyWith(date: date);
        parsedResults.add(paymentWithDate.toMap());
      }
    }

    return parsedResults;
  }

  /// Syncs all SMS for the given month in a background isolate without freezing the UI
  Future<SyncResult> syncMonthTransactions({
    DateTime? targetMonth,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      final hasPerm = await requestPermissions();
      if (!hasPerm) {
        return SyncResult.failure('SMS permission is required to auto-sync transactions.');
      }

      onProgress?.call(0.1, 'Reading SMS inbox...');

      final SmsQuery query = SmsQuery();
      final List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 1500, // Read up to 1500 inbox messages
      );

      if (messages.isEmpty) {
        return SyncResult(isSuccess: true, totalSmsRead: 0);
      }

      final month = targetMonth ?? DateTime.now();
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Filter messages strictly within the target month range
      final monthSms = messages.where((msg) {
        final msgDate = msg.date;
        if (msgDate == null) return false;
        return msgDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            msgDate.isBefore(endOfMonth.add(const Duration(seconds: 1)));
      }).toList();

      onProgress?.call(0.4, 'Parsing ${monthSms.length} messages in background isolate...');

      // Prepare lightweight data map for background isolate
      final rawList = monthSms.map((msg) => {
            'body': msg.body ?? '',
            'timestamp': msg.date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            'sender': msg.address,
          }).toList();

      // Run parsing in background Dart Isolate to eliminate UI frame drops
      final List<Map<String, dynamic>> parsedMaps = await compute(
        _parseSmsBatch,
        rawList,
      );

      onProgress?.call(0.7, 'Deduplicating against saved transactions...');

      // Fetch existing payments in DB to prevent duplicates
      final existingPayments = await DatabaseService.instance.getPaymentsByMonth(month);
      final existingRawMessages = existingPayments
          .map((p) => p.rawMessage?.trim())
          .where((m) => m != null && m.isNotEmpty)
          .toSet();

      int addedCount = 0;
      int duplicatesCount = 0;
      double totalExpense = 0.0;
      double totalIncome = 0.0;

      for (final map in parsedMaps) {
        final payment = Payment.fromMap(map);
        final raw = payment.rawMessage?.trim();

        // Deduplication Check
        bool isDuplicate = false;
        if (raw != null && existingRawMessages.contains(raw)) {
          isDuplicate = true;
        } else {
          // Check timestamp + amount match within 120 seconds
          isDuplicate = existingPayments.any((existing) {
            final diff = existing.date.difference(payment.date).inSeconds.abs();
            return diff < 120 &&
                (existing.amount - payment.amount).abs() < 0.01 &&
                existing.type == payment.type;
          });
        }

        if (isDuplicate) {
          duplicatesCount++;
        } else {
          await DatabaseService.instance.addPayment(payment);
          existingPayments.add(payment);
          if (raw != null) existingRawMessages.add(raw);

          addedCount++;
          if (payment.type == TransactionType.debit) {
            totalExpense += payment.amount;
          } else {
            totalIncome += payment.amount;
          }
        }
      }

      onProgress?.call(1.0, 'Sync complete!');

      return SyncResult(
        isSuccess: true,
        totalSmsRead: monthSms.length,
        financialSmsFound: parsedMaps.length,
        newTransactionsAdded: addedCount,
        duplicatesSkipped: duplicatesCount,
        totalExpenseAdded: totalExpense,
        totalIncomeAdded: totalIncome,
      );
    } catch (e) {
      return SyncResult.failure('Error syncing SMS: $e');
    }
  }

  /// Starts listening to real-time incoming SMS via native Android EventChannel
  Future<void> startLiveSmsListener({Function(Payment)? onPaymentCaptured}) async {
    _liveSmsSubscription?.cancel();

    final isGranted = await hasPermission();
    if (!isGranted) return;

    try {
      _liveSmsSubscription = _smsEventChannel.receiveBroadcastStream().listen(
        (event) async {
          if (event is Map) {
            final body = event['body'] as String? ?? '';
            final timestamp = event['timestamp'] as num? ?? DateTime.now().millisecondsSinceEpoch;
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());

            if (body.isEmpty) return;

            final parseResult = MessageParserPipeline.instance.parse(
              body,
              source: PaymentSource.sms,
            );

            if (parseResult.isSuccess && parseResult.payment != null) {
              final payment = parseResult.payment!.copyWith(date: date);

              // Check if already in DB
              final existing = await DatabaseService.instance.getPaymentsByMonth(date);
              final isDup = existing.any((e) =>
                  e.rawMessage?.trim() == body.trim() ||
                  ((e.amount - payment.amount).abs() < 0.01 &&
                      e.date.difference(payment.date).inSeconds.abs() < 60));

              if (!isDup) {
                await DatabaseService.instance.addPayment(payment);
                onPaymentCaptured?.call(payment);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Error in live SMS stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Could not initialize SMS EventChannel: $e');
    }
  }

  void dispose() {
    _liveSmsSubscription?.cancel();
  }
}
