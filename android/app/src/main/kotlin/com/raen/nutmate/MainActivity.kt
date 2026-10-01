package com.raen.nutmate

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val WIDGET_CHANNEL = "com.raen.nutmate/widget_update"
        private const val STORAGE_CHANNEL = "com.raen.nutmate/storage"
        private const val REMINDER_CHANNEL = "com.raen.nutmate/reminder"
    }

    private var reminderChannel: MethodChannel? = null
    private var pendingPostNutLogId: Int? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == "com.raen.nutmate.ACTION_EDIT_POST_NUT" || intent.getStringExtra("action") == "edit_post_nut") {
            val id = intent.getIntExtra("log_id", -1)
            if (id != -1) {
                pendingPostNutLogId = id
                reminderChannel?.invokeMethod("onNotificationClicked", mapOf("logId" to id))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Schedule default 5-min widget updates on startup
        WidgetScheduler.scheduleUpdates(this, 5)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setUpdateInterval") {
                val interval = call.argument<Int>("intervalMinutes") ?: 5
                WidgetScheduler.scheduleUpdates(this, interval)
                WidgetHelper.updateAllWidgets(this)
                result.success(true)
            } else if (call.method == "refreshWidgets") {
                WidgetHelper.updateAllWidgets(this)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAllFilesAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else {
                        result.success(true)
                    }
                }
                "requestAllFilesAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val uri = Uri.parse("package:$packageName")
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, uri)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                            startActivity(intent)
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "copyDatabaseToExternal" -> {
                    try {
                        val dbFile = getDatabasePath("nutmate.db")
                        if (!dbFile.exists()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val backupDir = File(Environment.getExternalStorageDirectory(), "NutMate/Backups")
                        if (!backupDir.exists()) {
                            backupDir.mkdirs()
                        }
                        val latestFile = File(backupDir, "nutmate_backup_latest.db")
                        dbFile.copyTo(latestFile, overwrite = true)
                        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                        val timestampFile = File(backupDir, "nutmate_backup_$timestamp.db")
                        dbFile.copyTo(timestampFile, overwrite = true)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BACKUP_ERROR", e.message, null)
                    }
                }
                "restoreDatabaseFromExternal" -> {
                    try {
                        val sourcePath = call.argument<String>("sourcePath")
                        val sourceFile = if (sourcePath != null && sourcePath.isNotEmpty()) {
                            File(sourcePath)
                        } else {
                            val backupDir = File(Environment.getExternalStorageDirectory(), "NutMate/Backups")
                            File(backupDir, "nutmate_backup_latest.db")
                        }
                        if (!sourceFile.exists()) {
                            result.error("FILE_NOT_FOUND", "Backup file does not exist: ${sourceFile.absolutePath}", null)
                            return@setMethodCallHandler
                        }
                        val dbFile = getDatabasePath("nutmate.db")
                        if (dbFile.parentFile?.exists() == false) {
                            dbFile.parentFile?.mkdirs()
                        }
                        sourceFile.copyTo(dbFile, overwrite = true)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RESTORE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val remChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REMINDER_CHANNEL)
        reminderChannel = remChannel
        remChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "schedulePostNutReminder" -> {
                    val logId = call.argument<Int>("logId") ?: 1
                    val isStealth = call.argument<Boolean>("isStealth") ?: false
                    val delayMinutes = (call.argument<Int>("delayMinutes") ?: 120).toLong()

                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    if (alarmManager != null) {
                        val reminderIntent = Intent(this, PostNutReminderReceiver::class.java).apply {
                            action = PostNutReminderReceiver.ACTION_POST_NUT_REMINDER
                            putExtra(PostNutReminderReceiver.EXTRA_LOG_ID, logId)
                            putExtra(PostNutReminderReceiver.EXTRA_IS_STEALTH, isStealth)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            logId,
                            reminderIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                        )
                        val triggerTime = System.currentTimeMillis() + (delayMinutes * 60 * 1000L)
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                            } else {
                                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback if exact alarm exception
                            try {
                                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ALARM_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(false)
                    }
                }
                "cancelPostNutReminder" -> {
                    val logId = call.argument<Int>("logId") ?: 1
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    if (alarmManager != null) {
                        val reminderIntent = Intent(this, PostNutReminderReceiver::class.java).apply {
                            action = PostNutReminderReceiver.ACTION_POST_NUT_REMINDER
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            logId,
                            reminderIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                        )
                        alarmManager.cancel(pendingIntent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "getPendingPostNutLogId" -> {
                    val id = pendingPostNutLogId
                    pendingPostNutLogId = null
                    result.success(id)
                }
                else -> result.notImplemented()
            }
        }
    }
}
