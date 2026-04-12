package com.example.simplify

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File

class TaskAlarmRingService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var activeTaskId: Int = -1

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                actionDismiss -> {
                    val taskId = intent.getIntExtra(TaskAlarmScheduler.extraTaskId, -1)
                    if (taskId != -1) {
                        stopAlarm(taskId)
                    } else {
                        stopSelf()
                    }
                }
                else -> {
                    val taskId = intent?.getIntExtra(TaskAlarmScheduler.extraTaskId, -1) ?: -1
                    if (taskId == -1) {
                        stopSelf()
                        return START_NOT_STICKY
                    }

                    activeTaskId = taskId
                    val title = intent?.getStringExtra(TaskAlarmScheduler.extraTitle).orEmpty()
                    val description = intent?.getStringExtra(TaskAlarmScheduler.extraDescription).orEmpty()
                    val sound = intent?.getStringExtra(TaskAlarmScheduler.extraSound) ?: "device_default"
                    startAlarm(taskId, title, description, sound)
                }
            }
        } catch (_: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releasePlayer()
        vibrator?.cancel()
        super.onDestroy()
    }

    private fun startAlarm(taskId: Int, title: String, description: String, sound: String) {
        try {
            createAlarmChannel()
            startForeground(notificationId(taskId), buildNotification(taskId, title, description))
            playAlarmSound(sound)
            vibrate()
        } catch (_: Exception) {
            stopAlarm(taskId)
        }
    }

    private fun stopAlarm(taskId: Int) {
        releasePlayer()
        vibrator?.cancel()
        runCatching {
            stopForeground(STOP_FOREGROUND_REMOVE)
        }
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(notificationId(taskId))
        stopSelf()
    }

    private fun buildNotification(taskId: Int, title: String, description: String) =
        NotificationCompat.Builder(this, activeAlarmChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(description)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(alarmActivityPendingIntent(taskId, title, description), true)
            .addAction(
                0,
                "Dismiss",
                dismissPendingIntent(taskId),
            )
            .build()

    private fun dismissPendingIntent(taskId: Int): PendingIntent {
        val intent = Intent(this, TaskAlarmRingService::class.java).apply {
            action = actionDismiss
            putExtra(TaskAlarmScheduler.extraTaskId, taskId)
        }

        return PendingIntent.getService(
            this,
            taskId + 90000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun alarmActivityPendingIntent(
        taskId: Int,
        title: String,
        description: String,
    ): PendingIntent {
        val intent = Intent(this, TaskAlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(TaskAlarmScheduler.extraTaskId, taskId)
            putExtra(TaskAlarmScheduler.extraTitle, title)
            putExtra(TaskAlarmScheduler.extraDescription, description)
        }

        return PendingIntent.getActivity(
            this,
            taskId + 95000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun playAlarmSound(sound: String) {
        releasePlayer()

        val preferredUri =
            when {
                sound == "device_default" -> null
                sound.startsWith("content://") || sound.startsWith("file://") -> Uri.parse(sound)
                sound.startsWith("/") -> Uri.fromFile(File(sound))
                else -> Uri.parse("android.resource://$packageName/raw/$sound")
            }
        val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        mediaPlayer = createPlayer(preferredUri) ?: createPlayer(fallbackUri)
    }

    private fun vibrate() {
        val pattern = longArrayOf(0, 600, 450)
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return
            val channel = NotificationChannel(
                activeAlarmChannelId,
                "Simplify Active Alarm",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Full-screen alarm UI for follow-up alarms."
                setSound(null, null)
                enableVibration(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createPlayer(soundUri: Uri?): MediaPlayer? {
        if (soundUri == null) {
            return null
        }

        return try {
            MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@TaskAlarmRingService, soundUri)
                isLooping = true
                prepare()
                start()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun releasePlayer() {
        runCatching {
            mediaPlayer?.stop()
        }
        mediaPlayer?.release()
        mediaPlayer = null
    }

    companion object {
        private const val activeAlarmChannelId = "simplify_active_alarm"
        private const val actionStart = "com.example.simplify.action.START_ALARM"
        private const val actionDismiss = "com.example.simplify.action.DISMISS_ALARM"

        fun startAlarm(
            context: Context,
            taskId: Int,
            title: String,
            description: String,
            sound: String,
        ) {
            val intent = Intent(context, TaskAlarmRingService::class.java).apply {
                action = actionStart
                putExtra(TaskAlarmScheduler.extraTaskId, taskId)
                putExtra(TaskAlarmScheduler.extraTitle, title)
                putExtra(TaskAlarmScheduler.extraDescription, description)
                putExtra(TaskAlarmScheduler.extraSound, sound)
            }
            runCatching {
                ContextCompat.startForegroundService(context, intent)
            }
        }

        fun dismissAlarm(context: Context, taskId: Int) {
            val intent = Intent(context, TaskAlarmRingService::class.java).apply {
                action = actionDismiss
                putExtra(TaskAlarmScheduler.extraTaskId, taskId)
            }
            runCatching {
                context.startService(intent)
            }
        }

        fun forceStopAlarm(context: Context, taskId: Int) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(notificationId(taskId))

            val intent = Intent(context, TaskAlarmRingService::class.java).apply {
                action = actionDismiss
                putExtra(TaskAlarmScheduler.extraTaskId, taskId)
            }

            runCatching {
                context.stopService(intent)
            }
        }

        fun notificationId(taskId: Int): Int = (taskId * 10) + 902
    }
}
