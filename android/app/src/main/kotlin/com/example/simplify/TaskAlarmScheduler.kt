package com.example.simplify

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.AlarmManagerCompat

object TaskAlarmScheduler {
    const val extraTaskId = "task_id"
    const val extraTitle = "title"
    const val extraDescription = "description"
    const val extraTriggerAtMillis = "trigger_at_millis"
    const val extraRepeat = "repeat"
    const val extraSound = "sound"

    fun scheduleAlarm(
        context: Context,
        taskId: Int,
        title: String,
        description: String,
        triggerAtMillis: Long,
        repeat: String,
        sound: String,
    ): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return false
        val alarmIntent = alarmPendingIntent(
            context = context,
            taskId = taskId,
            title = title,
            description = description,
            triggerAtMillis = triggerAtMillis,
            repeat = repeat,
            sound = sound,
            flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return false
        val showIntent = PendingIntent.getActivity(
            context,
            taskId + 50000,
            Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return try {
            AlarmManagerCompat.setAlarmClock(
                alarmManager,
                triggerAtMillis,
                showIntent,
                alarmIntent,
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun cancelAlarm(context: Context, taskId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val pendingIntent = alarmPendingIntent(
            context = context,
            taskId = taskId,
            title = "",
            description = "",
            triggerAtMillis = 0L,
            repeat = "none",
            sound = "device_default",
            flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )

        pendingIntent?.let {
            alarmManager?.cancel(it)
            it.cancel()
        }

        TaskAlarmRingService.forceStopAlarm(context, taskId)
    }

    private fun alarmPendingIntent(
        context: Context,
        taskId: Int,
        title: String,
        description: String,
        triggerAtMillis: Long,
        repeat: String,
        sound: String,
        flags: Int,
    ): PendingIntent? {
        val intent = Intent(context, TaskAlarmReceiver::class.java).apply {
            putExtra(extraTaskId, taskId)
            putExtra(extraTitle, title)
            putExtra(extraDescription, description)
            putExtra(extraTriggerAtMillis, triggerAtMillis)
            putExtra(extraRepeat, repeat)
            putExtra(extraSound, sound)
        }

        return PendingIntent.getBroadcast(context, taskId * 10 + 2, intent, flags)
    }
}
