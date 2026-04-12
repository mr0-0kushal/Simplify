package com.example.simplify

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class TaskAlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )

        setContentView(R.layout.activity_task_alarm)

        val taskId = intent.getIntExtra(TaskAlarmScheduler.extraTaskId, -1)
        val title = intent.getStringExtra(TaskAlarmScheduler.extraTitle).orEmpty()
        val description = intent.getStringExtra(TaskAlarmScheduler.extraDescription).orEmpty()

        findViewById<TextView>(R.id.alarmTitle).text = title
        findViewById<TextView>(R.id.alarmDescription).text = description
        findViewById<Button>(R.id.dismissAlarmButton).setOnClickListener {
            if (taskId != -1) {
                TaskAlarmRingService.dismissAlarm(this, taskId)
            }
            finish()
        }
    }
}
