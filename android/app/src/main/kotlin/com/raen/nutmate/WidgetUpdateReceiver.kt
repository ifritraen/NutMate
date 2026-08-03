package com.raen.nutmate

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (Intent.ACTION_BOOT_COMPLETED == action) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val interval = prefs.getInt("flutter.widgetUpdateIntervalMinutes", 5)
            WidgetScheduler.scheduleUpdates(context, interval)
        }

        WidgetHelper.updateAllWidgets(context)
    }
}
