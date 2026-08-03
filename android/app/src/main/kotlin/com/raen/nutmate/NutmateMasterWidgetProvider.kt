package com.raen.nutmate

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.raen.nutmate.R
import es.antonborri.home_widget.HomeWidgetProvider

class NutmateMasterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nutmate_widget_master)

            val streak = WidgetHelper.getFormattedStreak(widgetData)
            val edgeCount = widgetData.getInt("edge_count", 0)

            views.setTextViewText(R.id.streak_text, streak)
            views.setTextViewText(R.id.edge_count, "⚡ Edged: $edgeCount")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

