package com.zaifears.locreminder

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

/**
 * Full-screen alarm UI. Shows over the lock screen and keeps the display on,
 * the same way a real alarm clock app does. Deliberately a plain [Activity]
 * (not a Flutter route) so it renders even if the Flutter engine isn't
 * running when the alarm fires.
 */
class AlarmActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupWindowFlags()
        setContentView(R.layout.activity_alarm)

        val label = intent.getStringExtra(AlarmForegroundService.EXTRA_LABEL) ?: "your destination"
        findViewById<TextView>(R.id.alarmLabel).text = getString(R.string.alarm_arrived_message, label)

        findViewById<Button>(R.id.stopButton).setOnClickListener {
            startService(
                Intent(this, AlarmForegroundService::class.java).apply {
                    action = AlarmForegroundService.ACTION_STOP
                },
            )
            finish()
        }
    }

    private fun setupWindowFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    // The alarm must be dismissed deliberately via the Stop button, not by
    // swiping/back-pressing away — same behavior as stock alarm clock apps.
    @Suppress("OVERRIDE_DEPRECATION", "DEPRECATION")
    override fun onBackPressed() {
        // No-op.
    }
}
