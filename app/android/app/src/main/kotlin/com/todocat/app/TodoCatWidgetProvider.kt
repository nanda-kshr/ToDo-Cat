package com.todocat.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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
        val isDark = widgetData.getBoolean("is_dark", homePrefs.getBoolean("is_dark", false))
        val isCatWhite = widgetData.getBoolean("is_cat_white", homePrefs.getBoolean("is_cat_white", false))
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        appWidgetIds.forEach { widgetId ->
            updateCatWidget(context, appWidgetManager, widgetId, pendingCount, completedCount, speedPercent, totalCount, isDark, isCatWhite)
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
        val isDark = homePrefs.getBoolean("is_dark", false)
        val isCatWhite = homePrefs.getBoolean("is_cat_white", false)
        val completedCount = (totalCount - pendingCount).coerceAtLeast(0)

        updateCatWidget(context, appWidgetManager, appWidgetId, pendingCount, completedCount, speedPercent, totalCount, isDark, isCatWhite)
    }

    companion object {
        private fun buildWidgetViews(
            context: Context,
            layoutId: Int,
            pendingCount: Int,
            completedCount: Int,
            totalCount: Int,
            speedPercent: Int,
            hasProgress: Boolean,
            isDark: Boolean,
            isCatWhite: Boolean
        ): RemoteViews {
            val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

            return RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_cat_root, openAppPendingIntent)

                val ratioText = if (totalCount > 0) "$completedCount/$totalCount" else "0/0"
                setTextViewText(R.id.widget_cat_ratio, ratioText)
                setTextViewText(R.id.widget_cat_ratio_label, "tasks")

                if (isDark) {
                    setInt(R.id.widget_cat_root, "setBackgroundResource", R.drawable.widget_cat_background_dark)
                    setTextColor(R.id.widget_cat_time, Color.parseColor("#F5F5F5"))
                    setTextColor(R.id.widget_cat_date, Color.parseColor("#A6A6A6"))
                    setTextColor(R.id.widget_cat_ratio, Color.parseColor("#F5F5F5"))
                    setTextColor(R.id.widget_cat_ratio_label, Color.parseColor("#A6A6A6"))
                } else {
                    setInt(R.id.widget_cat_root, "setBackgroundResource", R.drawable.widget_cat_background)
                    setTextColor(R.id.widget_cat_time, Color.parseColor("#2B1D16"))
                    setTextColor(R.id.widget_cat_date, Color.parseColor("#8A7867"))
                    setTextColor(R.id.widget_cat_ratio, Color.parseColor("#2B1D16"))
                    setTextColor(R.id.widget_cat_ratio_label, Color.parseColor("#8A7867"))
                }

                // Cat animation frames: White vs Black
                if (isCatWhite) {
                    setImageViewResource(R.id.widget_cat_frame_0, R.drawable.cat_white_0)
                    setImageViewResource(R.id.widget_cat_frame_1, R.drawable.cat_white_1)
                    setImageViewResource(R.id.widget_cat_frame_2, R.drawable.cat_white_2)
                    setImageViewResource(R.id.widget_cat_frame_3, R.drawable.cat_white_3)
                    setImageViewResource(R.id.widget_cat_frame_4, R.drawable.cat_white_4)
                    setImageViewResource(R.id.widget_cat_frame_5, R.drawable.cat_white_5)
                    setImageViewResource(R.id.widget_cat_frame_6, R.drawable.cat_white_6)
                    setImageViewResource(R.id.widget_cat_sleep_0, R.drawable.cat_white_sleep_0)
                    setImageViewResource(R.id.widget_cat_sleep_1, R.drawable.cat_white_sleep_1)
                    setImageViewResource(R.id.widget_cat_sleep_2, R.drawable.cat_white_sleep_2)
                    setImageViewResource(R.id.widget_cat_sleep_3, R.drawable.cat_white_sleep_3)
                    setImageViewResource(R.id.widget_cat_sleep_4, R.drawable.cat_white_sleep_4)
                    setImageViewResource(R.id.widget_cat_sleep_5, R.drawable.cat_white_sleep_5)
                } else {
                    setImageViewResource(R.id.widget_cat_frame_0, R.drawable.cat_0)
                    setImageViewResource(R.id.widget_cat_frame_1, R.drawable.cat_1)
                    setImageViewResource(R.id.widget_cat_frame_2, R.drawable.cat_2)
                    setImageViewResource(R.id.widget_cat_frame_3, R.drawable.cat_3)
                    setImageViewResource(R.id.widget_cat_frame_4, R.drawable.cat_4)
                    setImageViewResource(R.id.widget_cat_frame_5, R.drawable.cat_5)
                    setImageViewResource(R.id.widget_cat_frame_6, R.drawable.cat_6)
                    setImageViewResource(R.id.widget_cat_sleep_0, R.drawable.cat_sleep_0)
                    setImageViewResource(R.id.widget_cat_sleep_1, R.drawable.cat_sleep_1)
                    setImageViewResource(R.id.widget_cat_sleep_2, R.drawable.cat_sleep_2)
                    setImageViewResource(R.id.widget_cat_sleep_3, R.drawable.cat_sleep_3)
                    setImageViewResource(R.id.widget_cat_sleep_4, R.drawable.cat_sleep_4)
                    setImageViewResource(R.id.widget_cat_sleep_5, R.drawable.cat_sleep_5)
                }

                if (hasProgress) {
                    val max = totalCount.coerceAtLeast(1)
                    val current = completedCount.coerceIn(0, max)
                    setProgressBar(R.id.widget_cat_progress, max, current, false)
                }

                if (pendingCount <= 0) {
                    setViewVisibility(R.id.widget_cat_flipper, View.GONE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.VISIBLE)
                    setInt(R.id.widget_cat_sleeping, "setFlipInterval", 350)
                } else {
                    setViewVisibility(R.id.widget_cat_flipper, View.VISIBLE)
                    setViewVisibility(R.id.widget_cat_sleeping, View.GONE)
                    val clampedSpeed = speedPercent.coerceIn(1, 100)
                    val intervalMs = (320 - (clampedSpeed * 2.8).toInt()).coerceIn(40, 320)
                    setInt(R.id.widget_cat_flipper, "setFlipInterval", intervalMs)
                }
            }
        }

        fun updateCatWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            pendingCount: Int,
            completedCount: Int,
            speedPercent: Int,
            totalCount: Int = pendingCount + completedCount,
            isDark: Boolean = false,
            isCatWhite: Boolean = false
        ) {
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0

            // Note: order matters — tall takes priority over wide for square-ish sizes
            val layoutId = when {
                minHeight >= 160 && minHeight > minWidth -> R.layout.todocat_cat_widget_tall
                minWidth >= 180 -> R.layout.todocat_cat_widget_wide
                else -> R.layout.todocat_cat_widget
            }

            val views = buildWidgetViews(context, layoutId, pendingCount, completedCount, totalCount, speedPercent, true, isDark, isCatWhite)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
