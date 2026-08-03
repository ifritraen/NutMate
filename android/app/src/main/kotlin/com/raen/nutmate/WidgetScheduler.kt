package com.raen.nutmate

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock

object WidgetScheduler {
    private const val ACTION_WIDGET_UPDATE_ALARM = "com.raen.nutmate.ACTION_WIDGET_UPDATE_ALARM"
    private const val REQUEST_CODE = 90123

    fun scheduleUpdates(context: Context, intervalMinutes: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
            action = ACTION_WIDGET_UPDATE_ALARM
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val intervalMs = (if (intervalMinutes > 0) intervalMinutes else 5) * 60 * 1000L

        // Cancel previous schedule
        alarmManager.cancel(pendingIntent)

        // Schedule inexact or exact repeating alarm depending on Android version
        try {
            alarmManager.setRepeating(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + intervalMs,
                intervalMs,
                pendingIntent
            )
        } catch (_: Exception) {
            // Graceful fallback
        }
    }
}
