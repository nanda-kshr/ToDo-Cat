package com.todocat.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TodoCatWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val pendingCount = widgetData.getInt("pending_count", homePrefs.getInt("pending_count", 0))
        val totalCount = widgetData.getInt("total_count", homePrefs.getInt("total_count", 0))
        val speedPercent = widgetData.getInt("speed_percent", homePrefs.getInt("speed_percent", 0))
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        appWidgetIds.forEach { widgetId ->
            updateCatWidget(context, appWidgetManager, widgetId, pendingCount, completedCount, speedPercent)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val pendingCount = homePrefs.getInt("pending_count", 0)
        val totalCount = homePrefs.getInt("total_count", 0)
        val speedPercent = homePrefs.getInt("speed_percent", 0)
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        updateCatWidget(context, appWidgetManager, appWidgetId, pendingCount, completedCount, speedPercent)
    }

    companion object {
        fun updateCatWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            pendingCount: Int,
            completedCount: Int,
            speedPercent: Int
        ) {
            val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )

            val views = RemoteViews(context.packageName, R.layout.todocat_cat_widget).apply {
                setOnClickPendingIntent(R.id.widget_cat_root, openAppPendingIntent)

                // Colored count texts
                setTextViewText(R.id.widget_cat_pending_count, "$pendingCount pending")
                setTextViewText(R.id.widget_cat_completed_count, "$completedCount done")

                if (pendingCount <= 0) {
                    // Show relaxed / sleeping cat
                    setViewVisibility(R.id.widget_cat_flipper, View.GONE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_cat_flipper, View.VISIBLE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.GONE)

                    // Flip interval based on speed: 40ms sprint at 100%, 280ms relaxed at 20%
                    val clampedSpeed = speedPercent.coerceIn(1, 100)
                    val intervalMs = (320 - (clampedSpeed * 2.8).toInt()).coerceIn(40, 320)
                    setInt(R.id.widget_cat_flipper, "setFlipInterval", intervalMs)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
