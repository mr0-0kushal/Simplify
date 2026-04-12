package com.example.simplify

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "simplify/device_alarm"
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "scheduleDeviceAlarm" -> {
                        val taskId = call.argument<Int>("taskId")
                        val title = call.argument<String>("title")
                        val description = call.argument<String>("description")
                        val triggerAtMillis = call.argument<Number>("triggerAtMillis")
                        val repeat = call.argument<String>("repeat") ?: "none"
                        val sound = call.argument<String>("sound") ?: "device_default"

                        if (taskId == null || title == null || description == null || triggerAtMillis == null) {
                            result.error("invalid_args", "Missing alarm scheduling arguments.", null)
                            return@setMethodCallHandler
                        }

                        val scheduled = TaskAlarmScheduler.scheduleAlarm(
                            context = applicationContext,
                            taskId = taskId,
                            title = title,
                            description = description,
                            triggerAtMillis = triggerAtMillis.toLong(),
                            repeat = repeat,
                            sound = sound,
                        )
                        if (scheduled) {
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "cancelDeviceAlarm" -> {
                        val taskId = call.argument<Int>("taskId")
                        if (taskId == null) {
                            result.error("invalid_args", "Missing task id for alarm cancellation.", null)
                            return@setMethodCallHandler
                        }

                        TaskAlarmScheduler.cancelAlarm(applicationContext, taskId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (exception: Exception) {
                result.error(
                    "alarm_error",
                    exception.message ?: "Unknown alarm scheduling failure.",
                    null,
                )
            }
        }
    }
}
