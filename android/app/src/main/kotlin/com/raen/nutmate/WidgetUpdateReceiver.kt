package com.raen.nutmate

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (Intent.ACTION_BOOT_COMPLETED == action) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val interval = prefs.getInt("flutter.widgetUpdateIntervalMinutes", 5)
            WidgetScheduler.scheduleUpdates(context, interval)
        }

        WidgetHelper.updateAllWidgets(context)

        // Native background auto-backup check
        tryAutoBackup(context)
    }

    private fun tryAutoBackup(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val intervalHours = prefs.getInt("flutter.autoBackupIntervalHours", 0)
            if (intervalHours <= 0) return

            val lastBackup = prefs.getLong("flutter.lastAutoBackupTimestamp", 0L)
            val now = System.currentTimeMillis()
            val intervalMs = intervalHours * 3600 * 1000L

            if (now - lastBackup >= intervalMs) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()) {
                    return
                }
                val dbFile = context.getDatabasePath("nutmate.db")
                if (!dbFile.exists()) return

                val backupDir = File(Environment.getExternalStorageDirectory(), "NutMate/Backups")
                if (!backupDir.exists()) backupDir.mkdirs()

                val latestFile = File(backupDir, "nutmate_backup_latest.db")
                dbFile.copyTo(latestFile, overwrite = true)

                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                val timestampFile = File(backupDir, "nutmate_backup_$timestamp.db")
                dbFile.copyTo(timestampFile, overwrite = true)

                // Retain at most 10 timestamped backups
                cleanOldBackups(backupDir)

                prefs.edit().putLong("flutter.lastAutoBackupTimestamp", now).apply()
            }
        } catch (_: Exception) {
            // Non-fatal background backup failure
        }
    }

    private fun cleanOldBackups(backupDir: File) {
        try {
            val dbBackups = backupDir.listFiles { _, name ->
                name.startsWith("nutmate_backup_20") && name.endsWith(".db")
            }?.sortedByDescending { it.lastModified() } ?: return

            if (dbBackups.size > 10) {
                for (i in 10 until dbBackups.size) {
                    dbBackups[i].delete()
                }
            }
        } catch (_: Exception) {}
    }
}
