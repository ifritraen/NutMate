package com.raen.nutmate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class PostNutReminderReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_POST_NUT_REMINDER = "com.raen.nutmate.ACTION_POST_NUT_REMINDER"
        const val CHANNEL_ID = "post_nut_reminders"
        const val CHANNEL_NAME = "Session Recovery Reminders"
        const val EXTRA_LOG_ID = "log_id"
        const val EXTRA_IS_STEALTH = "is_stealth"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val logId = intent.getIntExtra(EXTRA_LOG_ID, -1)
        val isStealth = intent.getBooleanExtra(EXTRA_IS_STEALTH, false)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminds you to log post-session reflection and recovery items"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val title = if (isStealth) "Daily Notes" else "NutMate Recovery"
        val message = if (isStealth) {
            "Time to complete your routine reflections"
        } else {
            "2 hours have passed. Tap to update your post-nut recovery items"
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.raen.nutmate.ACTION_EDIT_POST_NUT"
            putExtra("action", "edit_post_nut")
            putExtra("log_id", logId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            if (logId != -1) logId else 9999,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify("post_nut_reminder", if (logId != -1) logId else 1, notification)
    }
}
