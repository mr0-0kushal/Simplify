package com.example.simplify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.Calendar

class TaskAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val taskId = intent.getIntExtra(TaskAlarmScheduler.extraTaskId, -1)
            if (taskId == -1) {
                return
            }

            val title = intent.getStringExtra(TaskAlarmScheduler.extraTitle).orEmpty()
            val description = intent.getStringExtra(TaskAlarmScheduler.extraDescription).orEmpty()
            val triggerAtMillis = intent.getLongExtra(TaskAlarmScheduler.extraTriggerAtMillis, 0L)
            val repeat = intent.getStringExtra(TaskAlarmScheduler.extraRepeat) ?: "none"
            val sound = intent.getStringExtra(TaskAlarmScheduler.extraSound) ?: "device_default"

            TaskAlarmRingService.startAlarm(
                context = context,
                taskId = taskId,
                title = title,
                description = description,
                sound = sound,
            )

            val nextTrigger = nextTrigger(triggerAtMillis, repeat)
            if (nextTrigger != null) {
                TaskAlarmScheduler.scheduleAlarm(
                    context = context,
                    taskId = taskId,
                    title = title,
                    description = description,
                    triggerAtMillis = nextTrigger,
                    repeat = repeat,
                    sound = sound,
                )
            }
        } catch (_: Exception) {
            // Ignore receiver failures so an alarm edge case never crashes the app process.
        }
    }

    private fun nextTrigger(currentTriggerAtMillis: Long, repeat: String): Long? {
        if (currentTriggerAtMillis <= 0L) {
            return null
        }

        val calendar = Calendar.getInstance().apply {
            timeInMillis = currentTriggerAtMillis
        }

        when (repeat) {
            "daily" -> calendar.add(Calendar.DAY_OF_YEAR, 1)
            "weekly" -> calendar.add(Calendar.DAY_OF_YEAR, 7)
            else -> return null
        }

        return calendar.timeInMillis
    }
}
