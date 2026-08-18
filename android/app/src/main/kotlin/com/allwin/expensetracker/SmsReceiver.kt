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
                if (smsListener != null) {
                    smsListener?.invoke(smsData)
                } else {
                    // 2. Only trigger background notification if app is closed/backgrounded AND it's a genuine transaction
                    if (isFinancialSms(bodyText)) {
                        showNotification(context, sender, bodyText)
                    }
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
        val trimmed = body.trim()
        if (trimmed.length < 10) return false

        // 1. Filter out OTPs, verification codes, and security messages
        val otpRegex = Regex("""\b(?:otp|one\s*time\s*password|verification\s*code|secret\s*code|do\s*not\s*share|security\s*code|login\s*code|auth\s*code)\b""", RegexOption.IGNORE_CASE)
        if (otpRegex.containsMatchIn(trimmed)) return false

        // 2. Filter out failed or pending transactions (unless it is an explicit completed reversal)
        val isExplicitReversal = Regex("""\b(?:has been reversed|is reversed|reversed to|refund credited|reversal of)\b""", RegexOption.IGNORE_CASE).containsMatchIn(trimmed)
        val failedOrPendingRegex = Regex("""\b(?:failed|declined|unsuccessful|transaction\s*failed|payment\s*failed|is\s*pending|payment\s*is\s*pending|payment\s*pending|txn\s*failed)\b""", RegexOption.IGNORE_CASE)
        if (failedOrPendingRegex.containsMatchIn(trimmed) && !isExplicitReversal) return false

        // 3. Filter out scam baits, phishing links, and fake lotteries
        val scamRegex = Regex("""\b(?:kyc\s*verification|update\s*kyc|yono\s*(?:account)?|account\s*(?:will\s*be\s*)?blocked|account\s*(?:will\s*be\s*)?suspended|confirm\s*bank\s*details|verify\s*your\s*bank\s*account|card\s*is\s*blocked\b.*\bcall|call\s*customer\s*care|lottery\b|scratch\s*card\s*cashback|won\s*(?:rs|₹|\$|£|€)|claim\s*your\s*(?:prize|reward|amount)|registration\s*fee|processing\s*fee|tax\s*fee|activation\s*fee|clearance\s*fee|to\s*release\s*funds|to\s*receive\s*money|approve\s*the\s*transfer|enter\s*(?:your\s*)?upi\s*pin|upi\s*pin\s*to|work\s*from\s*home|work\s*part[- ]time|earn\s*(?:rs|₹|\$|£|€)\s*\d+.*\b(?:daily|day|month)|download\s*(?:the\s*)?attached\s*apk|statement\.pdf\.exe|statement\.apk|whatsapp\s*support\b|whatsapp\s*to\s*start)\b""", RegexOption.IGNORE_CASE)
        if (scamRegex.containsMatchIn(trimmed)) return false

        // 4. Filter out promotional, loan marketing, and cashback spam ads
        val promotionalRegex = Regex("""\b(?:pre[\s\-]?approved|pre[\s\-]?qualified|instant\s*loan|loan\s*on\s*(?:card|credit\s*card)|(?:apply|avail|get|instant|eligible\s*for)\s*(?:a\s*)?(?:personal|home|business|gold)\s*loan|loan\s*(?:of|upto|up\s*to)|apply\s*(?:now|for)|avail\s*now|claim\s*now|click\s*(?:here|link|to\s*avail)|check\s*emis?|lowest\s*interest\s*rates?|congratulations|good\s*news|hurry|limited\s*(?:period\s*)?offer|offer\s*valid|win\s*(?:upto|up\s*to)|chance\s*to\s*win|lucky\s*draw|coupon\s*code|voucher|flat\s*(?:off|discount|rs)|upto\s*(?:rs\.?|inr|₹)|\bup\s*to\s*(?:rs\.?|inr|₹)|credit\s*card\s*offer|limit\s*increase|enhanced\s*limit|approved\s*limit|eligible\s*for|when\s*you\s*avail|when\s*you\s*apply|when\s*you\s*order|on\s*your\s*next\s*order|cashback\s*(?:upto|up\s*to|of\s*up\s*to|worth)|reward\s*points\s*worth|is\s*due\s*on|due\s*date\s*is|payment\s*is\s*due|minimum\s*(?:amount\s*)?due|pay\s*before|get\s*(?:rs\.?|inr|₹)\s*[\d,]+\s*off|save\s*(?:rs\.?|inr|₹))\b""", RegexOption.IGNORE_CASE)
        if (promotionalRegex.containsMatchIn(trimmed)) return false

        // 5. Must contain explicit debit or credit transaction intent
        val debitRegex = Regex("""\b(?:debited|debit|spent|paid|withdrawn|withdrawal|transferred|sent|purchase|charged|deducted|emi|was\s*used\s*for|using\s*your|used\s*at|processed\s*from|sip|installment|made\s*from|payment\s*of|transaction\s*of)\b""", RegexOption.IGNORE_CASE)
        val creditRegex = Regex("""\b(?:credited|deposited|deposit|received|refunded|refund|reversed|salary|contribution|interest|dividend|disbursed|posted)\b""", RegexOption.IGNORE_CASE)
        if (!debitRegex.containsMatchIn(trimmed) && !creditRegex.containsMatchIn(trimmed)) return false

        // 6. Must contain an explicit currency/amount indicator (Rs., INR, ₹, $, £, €)
        val amountRegex = Regex("""(?:INR|Rs\.?|₹|USD|GBP|EUR|\$|£|€)\s*([\d,]+(?:\.\d{1,2})?)""", RegexOption.IGNORE_CASE)
        val amountSuffixRegex = Regex("""([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹|USD|GBP|EUR|\$|£|€)""", RegexOption.IGNORE_CASE)
        if (!amountRegex.containsMatchIn(trimmed) && !amountSuffixRegex.containsMatchIn(trimmed)) return false

        // 7. Rejects promotional URLs if message lacks any account/bank/ref reference
        val lower = trimmed.lowercase()
        val hasUrl = lower.contains("http://") || lower.contains("https://")
        val accountRegex = Regex("""(?:(?:a/c|acct|account|card|vpa)\s*(?:no\.?|ending(?:\s*with)?)?\s*[:\-]?\s*([xX*]+[\d]{3,4}|[a-zA-Z0-9.\-_]+@(?:upi|[a-zA-Z0-9]+)|[\d]{4}))""", RegexOption.IGNORE_CASE)
        val bankNameRegex = Regex("""\b(HDFC|SBI|STATE\s*BANK\s*OF\s*INDIA|ICICI|AXIS|KOTAK|PNB|BOB|BANK\s*OF\s*BARODA|CANARA|UNION\s*BANK|BANK\s*OF\s*INDIA|INDIAN\s*BANK|CENTRAL\s*BANK|IOB|UCO\s*BANK|INDUSIND|YES\s*BANK|IDFC\s*FIRST|FEDERAL\s*BANK|RBL|BANDHAN|KARUR\s*VYSYA|CITY\s*UNION|SOUTH\s*INDIAN|J&K\s*BANK|AU\s*SMALL\s*FINANCE|EQUITAS|UJJIVAN|JANA|UTKARSH|PAYTM\s*BANK|AIRTEL\s*BANK|IPPB|CRED|ONECARD|AMEX|CITI|HSBC|STANDARD\s*CHARTERED)\b""", RegexOption.IGNORE_CASE)
        val refIdRegex = Regex("""(?:(?:UPI\s*Ref(?:\s*no)?|UTR|Txn\s*ID|Ref\s*no|Reference\s*No)\s*[:\-]?\s*([0-9a-zA-Z]{6,16}))""", RegexOption.IGNORE_CASE)

        if (hasUrl && !accountRegex.containsMatchIn(trimmed) && !bankNameRegex.containsMatchIn(trimmed) && !refIdRegex.containsMatchIn(trimmed)) {
            return false
        }

        return true
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

