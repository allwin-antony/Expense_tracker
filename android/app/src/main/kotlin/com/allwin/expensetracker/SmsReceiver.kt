package com.allwin.expensetracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.util.Log
import androidx.core.app.NotificationCompat

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        private const val CHANNEL_ID = "expense_tracker_sms_channel"
        var smsListener: ((Map<String, Any?>) -> Unit)? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (!messages.isNullOrEmpty()) {
                val fullBody = StringBuilder()
                var sender = ""
                var timestamp = System.currentTimeMillis()

                for (sms in messages) {
                    sender = sms.displayOriginatingAddress ?: ""
                    fullBody.append(sms.displayMessageBody)
                    timestamp = sms.timestampMillis
                }

                val bodyText = fullBody.toString()
                val smsData = mapOf(
                    "sender" to sender,
                    "body" to bodyText,
                    "timestamp" to timestamp
                )

                Log.d(TAG, "SMS received from $sender")

                // Reject personal phone numbers - only accept official TRAI headers
                if (!isTraiHeader(sender)) {
                    Log.d(TAG, "Ignoring SMS from non-TRAI personal phone number: $sender")
                    return
                }

                // 1. If Flutter UI is active, forward to live stream listener
                smsListener?.invoke(smsData)

                // 2. If SMS is a financial/bank transaction, trigger a background system notification
                if (isFinancialSms(bodyText)) {
                    showNotification(context, sender, bodyText)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing incoming SMS in SmsReceiver", e)
        }
    }

    private fun isTraiHeader(sender: String): Boolean {
        if (sender.isBlank()) return true
        val clean = sender.trim().replace(Regex("[\\s\\-]"), "")
        if (clean.matches(Regex("^\\+?\\d{7,15}$"))) {
            return false
        }
        return clean.any { it.isLetter() }
    }

    private fun isFinancialSms(body: String): Boolean {
        val text = body.lowercase()
        return text.contains("debited") || text.contains("credited") ||
               text.contains("spent") || text.contains("transferred") ||
               text.contains("paid") || text.contains("a/c") ||
               text.contains("vpa") || text.contains("upi") ||
               text.contains("rs.") || text.contains("inr") ||
               text.contains("bank") || text.contains("avbl bal")
    }

    private fun showNotification(context: Context, sender: String, body: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Notification Channel for API 26+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Transaction Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifies when a bank SMS transaction is received in background"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Tap notification or action button to open app and trigger auto sync
        val syncIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("auto_sync", true)
        }
        val syncPendingIntent = PendingIntent.getActivity(
            context,
            0,
            syncIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val cleanSender = if (sender.length > 12) sender.take(12) else sender
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("New Transaction Detected 💳")
            .setContentText("[$cleanSender] ${body.take(70)}...")
            .setStyle(NotificationCompat.BigTextStyle().bigText("From: $sender\n\n$body"))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(syncPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_compass,
                "View & Sync Expense",
                syncPendingIntent
            )
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }
}

