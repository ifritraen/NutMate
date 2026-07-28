package com.raen.nutmate

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.raen.nutmate.R
import es.antonborri.home_widget.HomeWidgetProvider

class NutmateCompactWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nutmate_widget_compact)

            val streak = widgetData.getString("streak_text", "0d 0h 0m") ?: "0d 0h 0m"
            views.setTextViewText(R.id.streak_text, streak)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
