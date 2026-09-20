package com.allwin.expensetracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import org.json.JSONArray

class MainActivity : FlutterFragmentActivity() {
    private val SMS_EVENT_CHANNEL = "com.allwin.expensetracker/sms_stream"
    private val SMS_METHOD_CHANNEL = "com.allwin.expensetracker/sms_queue"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Method Channel for queued SMS
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndClearPendingSms") {
                val prefs = getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)
                val queueString = prefs.getString("pending_sms_queue", "[]")
                
                // Clear the queue immediately after reading
                prefs.edit().putString("pending_sms_queue", "[]").apply()
                
                result.success(queueString)
            } else {
                result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    SmsReceiver.smsListener = { smsData ->
                        runOnUiThread {
                            eventSink?.success(smsData)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    SmsReceiver.smsListener = null
                }
            })
    }
}
