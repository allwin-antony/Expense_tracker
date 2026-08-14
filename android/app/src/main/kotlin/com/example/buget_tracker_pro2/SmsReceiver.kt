package com.finance.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        var smsListener: ((Map<String, Any?>) -> Unit)? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
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

                    val smsData = mapOf(
                        "sender" to sender,
                        "body" to fullBody.toString(),
                        "timestamp" to timestamp
                    )

                    Log.d(TAG, "SMS received from $sender")
                    smsListener?.invoke(smsData)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing incoming SMS", e)
            }
        }
    }
}
