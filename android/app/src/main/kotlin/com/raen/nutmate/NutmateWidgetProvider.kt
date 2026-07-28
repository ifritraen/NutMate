package com.raen.nutmate

import android.appwidget.AppWidgetManager
import com.raen.nutmate.R
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NutmateWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nutmate_widget_layout)

            val streak = widgetData.getString("streak_text", "0d 0h 0m") ?: "0d 0h 0m"
            val edgeCount = widgetData.getInt("edge_count", 0)

            views.setTextViewText(R.id.streak_text, streak)
            views.setTextViewText(R.id.edge_count, "Edged: $edgeCount Times")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
