package com.todocat.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TodoCatListWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val pendingCount = widgetData.getInt("pending_count", homePrefs.getInt("pending_count", 0))
        val totalCount = widgetData.getInt("total_count", homePrefs.getInt("total_count", 0))
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        appWidgetIds.forEach { widgetId ->
            updateListWidget(context, appWidgetManager, widgetId, pendingCount, completedCount)
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
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val pendingCount = homePrefs.getInt(
            "pending_count",
            flutterPrefs.getInt("flutter.pending_count", flutterPrefs.getInt("pending_count", 0))
        )
        val totalCount = homePrefs.getInt(
            "total_count",
            flutterPrefs.getInt("flutter.total_count", flutterPrefs.getInt("total_count", 0))
        )
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        updateListWidget(context, appWidgetManager, appWidgetId, pendingCount, completedCount)
    }

    companion object {
        fun updateListWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            pendingCount: Int,
            completedCount: Int
        ) {
            val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )

            val addTaskIntent = Intent(context, QuickAddActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addTaskPendingIntent = PendingIntent.getActivity(
                context,
                widgetId + 500,
                addTaskIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.todocat_list_widget).apply {
                setOnClickPendingIntent(R.id.widget_list_header, openAppPendingIntent)
                setOnClickPendingIntent(R.id.widget_list_btn_add, addTaskPendingIntent)

                val statsText = "$pendingCount pending • $completedCount completed"
                setTextViewText(R.id.widget_list_count, statsText)

                val serviceIntent = Intent(context, TodoCatWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse("todocat://widget_service/$widgetId")
                }
                setRemoteAdapter(R.id.widget_list_view, serviceIntent)
                setEmptyView(R.id.widget_list_view, R.id.widget_list_empty)
                setPendingIntentTemplate(R.id.widget_list_view, openAppPendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list_view)
        }
    }
}
