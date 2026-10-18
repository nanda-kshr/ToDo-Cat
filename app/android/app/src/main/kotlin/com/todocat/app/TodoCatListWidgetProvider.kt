package com.todocat.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
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
        val isDark = widgetData.getBoolean("is_dark", homePrefs.getBoolean("is_dark", false))
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        appWidgetIds.forEach { widgetId ->
            updateListWidget(context, appWidgetManager, widgetId, pendingCount, completedCount, isDark)
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
        val isDark = homePrefs.getBoolean("is_dark", false)
        val pendingCount = homePrefs.getInt(
            "pending_count",
            flutterPrefs.getInt("flutter.pending_count", flutterPrefs.getInt("pending_count", 0))
        )
        val totalCount = homePrefs.getInt(
            "total_count",
            flutterPrefs.getInt("flutter.total_count", flutterPrefs.getInt("total_count", 0))
        )
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        updateListWidget(context, appWidgetManager, appWidgetId, pendingCount, completedCount, isDark)
    }

    companion object {
        fun updateListWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            pendingCount: Int,
            completedCount: Int,
            isDark: Boolean = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE).getBoolean("is_dark", false)
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

            val layoutId = if (isDark) R.layout.todocat_list_widget else R.layout.todocat_list_widget_light
            val views = RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_list_header, openAppPendingIntent)
                setOnClickPendingIntent(R.id.widget_list_btn_add, addTaskPendingIntent)

                val statsText = "$pendingCount pending • $completedCount completed"
                setTextViewText(R.id.widget_list_count, statsText)

                if (isDark) {
                    setInt(R.id.widget_list_root, "setBackgroundResource", R.drawable.widget_background)
                    setTextColor(R.id.widget_list_title, Color.parseColor("#FFFFFF"))
                    setTextColor(R.id.widget_list_count, Color.parseColor("#888888"))
                    setImageViewResource(R.id.widget_list_divider, R.drawable.widget_divider)
                    setInt(R.id.widget_list_btn_add, "setBackgroundResource", R.drawable.widget_add_btn_bg)
                    setImageViewResource(R.id.widget_list_btn_add, R.drawable.ic_widget_add)
                    setTextColor(R.id.widget_list_empty, Color.parseColor("#737373"))
                } else {
                    setInt(R.id.widget_list_root, "setBackgroundResource", R.drawable.widget_background_light)
                    setTextColor(R.id.widget_list_title, Color.parseColor("#4B5563"))
                    setTextColor(R.id.widget_list_count, Color.parseColor("#9CA3AF"))
                    setImageViewResource(R.id.widget_list_divider, R.drawable.widget_divider_light)
                    setInt(R.id.widget_list_btn_add, "setBackgroundResource", R.drawable.widget_add_btn_bg_light)
                    setImageViewResource(R.id.widget_list_btn_add, R.drawable.ic_widget_add_grey)
                    setTextColor(R.id.widget_list_empty, Color.parseColor("#9CA3AF"))
                }

                val serviceIntent = Intent(context, TodoCatWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    putExtra("is_dark", isDark)
                    data = Uri.parse("todocat://widget_service/$widgetId/$isDark")
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
