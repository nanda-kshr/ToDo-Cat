package com.todocat.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
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
        val speedPercent = widgetData.getInt("speed_percent", 0)
        val speedMessage = widgetData.getString("speed_message", "Cat is sleeping") ?: "Cat is sleeping"
        val pendingCount = widgetData.getInt("pending_count", 0)
        val totalCount = widgetData.getInt("total_count", 0)

        val taskCountText = if (totalCount == 0) {
            "No tasks yet"
        } else if (pendingCount == 0) {
            "All $totalCount tasks completed!"
        } else {
            "$pendingCount tasks pending"
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.todocat_widget).apply {
                // Clicking opens MainActivity
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                if (speedPercent <= 0) {
                    // Show sleeping cat (cat_0)
                    setViewVisibility(R.id.widget_cat_flipper, View.GONE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.VISIBLE)
                } else {
                    // Show animated running cat via ViewFlipper
                    setViewVisibility(R.id.widget_cat_flipper, View.VISIBLE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.GONE)

                    // Adjust flip interval based on speed: 45ms at 100% speed, 150ms at low speed
                    val clampedSpeed = speedPercent.coerceIn(1, 100)
                    val intervalMs = (150 - (clampedSpeed * 1.05).toInt()).coerceIn(45, 150)
                    setInt(R.id.widget_cat_flipper, "setFlipInterval", intervalMs)
                }

                // Status and task counter
                setTextViewText(R.id.widget_cat_status, speedMessage)
                setTextViewText(R.id.widget_task_count, taskCountText)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
