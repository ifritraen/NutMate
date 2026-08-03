package com.raen.nutmate

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent

object WidgetHelper {
    fun getFormattedStreak(widgetData: SharedPreferences): String {
        val isFrozen = widgetData.getBoolean("streak_frozen", false)
        if (isFrozen) {
            val frozenMs = widgetData.getLong("frozen_streak_millis", 0L)
            val days = frozenMs / (1000 * 60 * 60 * 24)
            val hours = (frozenMs / (1000 * 60 * 60)) % 24
            val minutes = (frozenMs / (1000 * 60)) % 60
            return "${days}d ${hours}h ${minutes}m"
        }

        val lastResetMs = widgetData.getLong("last_reset_millis", 0L)
        if (lastResetMs <= 0L) {
            val savedText = widgetData.getString("streak_text", null)
            return savedText ?: "0d 0h 0m"
        }

        val diffMs = System.currentTimeMillis() - lastResetMs
        if (diffMs < 0L) return "0d 0h 0m"

        val days = diffMs / (1000 * 60 * 60 * 24)
        val hours = (diffMs / (1000 * 60 * 60)) % 24
        val minutes = (diffMs / (1000 * 60)) % 60

        return "${days}d ${hours}h ${minutes}m"
    }

    fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val providers = arrayOf(
            NutmateWidgetProvider::class.java,
            NutmateMasterWidgetProvider::class.java,
            NutmateCompactWidgetProvider::class.java,
            NutmateMinimalWidgetProvider::class.java
        )

        for (providerClass in providers) {
            val intent = Intent(context, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, providerClass))
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
