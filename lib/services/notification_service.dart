import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/payment.dart';
import 'database_service.dart';

/// Top-level background entry point required by flutter_local_notifications for action buttons
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();

  final actionId = notificationResponse.actionId;
  final payload = notificationResponse.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final int? paymentId = data['id'] as int?;
    final String description = data['description'] as String? ?? 'Transaction';
    final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    if (paymentId == null) return;

    final plugin = FlutterLocalNotificationsPlugin();

    if (actionId == 'action_exclude') {
      await DatabaseService.instance.toggleExcludePayment(paymentId, true);
      debugPrint('[NotificationService Background] Excluded payment #$paymentId');

      // Show brief confirmation notification
      await plugin.show(
        paymentId + 900000,
        '🔕 Excluded from Budget',
        '$description (₹${NumberFormat('#,##,###.00').format(amount)}) will not be counted in monthly calculations.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expense_alerts_channel',
            'Transaction Alerts',
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: true,
            timeoutAfter: 4000,
          ),
        ),
      );
    } else if (actionId == 'action_delete') {
      await DatabaseService.instance.deletePayment(paymentId);
      debugPrint('[NotificationService Background] Deleted payment #$paymentId');

      // Show brief confirmation notification
      await plugin.show(
        paymentId + 900000,
        '🗑️ Transaction Deleted',
        '$description (₹${NumberFormat('#,##,###.00').format(amount)}) was removed from your records.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expense_alerts_channel',
            'Transaction Alerts',
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: true,
            timeoutAfter: 4000,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('[NotificationService Background] Error handling action $actionId: $e');
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'expense_alerts_channel';
  static const String _channelName = 'Transaction Alerts';
  static const String _channelDescription =
      'Real-time alerts and interactive actions when transactions are auto-captured from bank SMS.';

  /// Initialize notification plugin, channel, and callbacks
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high-importance Android channel for heads-up alerts
    final androidChannel = const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  /// Request runtime notification permission (Android 13+ / iOS)
  Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Handles foreground notification action taps
  void _onForegroundNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final int? paymentId = data['id'] as int?;
      final String description = data['description'] as String? ?? 'Transaction';
      final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      if (paymentId == null) return;

      if (actionId == 'action_exclude') {
        await DatabaseService.instance.toggleExcludePayment(paymentId, true);
        await _notificationsPlugin.cancel(paymentId);
        debugPrint('[NotificationService Foreground] Excluded payment #$paymentId');

        await _notificationsPlugin.show(
          paymentId + 900000,
          '🔕 Excluded from Budget',
          '$description (₹${NumberFormat('#,##,###.00').format(amount)}) will not be counted in monthly calculations.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.low,
              priority: Priority.low,
              autoCancel: true,
              timeoutAfter: 4000,
            ),
          ),
        );
      } else if (actionId == 'action_delete') {
        await DatabaseService.instance.deletePayment(paymentId);
        await _notificationsPlugin.cancel(paymentId);
        debugPrint('[NotificationService Foreground] Deleted payment #$paymentId');

        await _notificationsPlugin.show(
          paymentId + 900000,
          '🗑️ Transaction Deleted',
          '$description (₹${NumberFormat('#,##,###.00').format(amount)}) was removed from your records.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.low,
              priority: Priority.low,
              autoCancel: true,
              timeoutAfter: 4000,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService Foreground] Error handling action: $e');
    }
  }

  /// Displays an interactive heads-up notification with Exclude & Delete action buttons
  Future<void> showTransactionCapturedNotification(Payment payment) async {
    if (!_isInitialized) await initialize();

    final isIncome = payment.type == TransactionType.credit;
    final formattedAmount = NumberFormat('#,##,###.00').format(payment.amount);
    final sign = isIncome ? '+' : '-';
    final actionType = isIncome ? 'Income' : 'Expense';

    final title = '⚡ $sign ₹$formattedAmount Auto-Captured';
    final body = '${payment.description} • $actionType • ${payment.category} via ${payment.paymentMode.displayName}';

    final payload = jsonEncode({
      'id': payment.id,
      'amount': payment.amount,
      'description': payment.description,
      'category': payment.category,
      'type': payment.type.name,
    });

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      icon: '@mipmap/ic_launcher',
      color: isIncome ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Expense Tracker',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_exclude',
          '🔕 Exclude',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_delete',
          '🗑️ Delete',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final notificationId = payment.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
