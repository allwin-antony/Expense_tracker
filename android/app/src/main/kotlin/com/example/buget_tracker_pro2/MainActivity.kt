package com.finance.expense_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val SMS_EVENT_CHANNEL = "com.finance.expense_tracker/sms_stream"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
