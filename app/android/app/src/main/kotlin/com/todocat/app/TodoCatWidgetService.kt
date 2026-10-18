package com.todocat.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.text.SpannableString
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class TodoCatWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoCatListRemoteViewsFactory(applicationContext)
    }
}

class TodoCatListRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private data class WidgetTask(
        val id: String,
        val title: String,
        val completed: Boolean,
        val priority: String
    )

    private val tasks = mutableListOf<WidgetTask>()

    override fun onCreate() {
        loadTasks()
    }

    override fun onDataSetChanged() {
        loadTasks()
    }

    private fun loadTasks() {
        tasks.clear()
        try {
            val homePrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val jsonString = homePrefs.getString("tasks_json", null)
                ?: flutterPrefs.getString("flutter.tasks_json", null)
                ?: flutterPrefs.getString("tasks_json", null)

            if (!jsonString.isNullOrEmpty()) {
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val item = array.getJSONObject(i)
                    tasks.add(
                        WidgetTask(
                            id = item.optString("id", ""),
                            title = item.optString("title", "Untitled Task"),
                            completed = item.optBoolean("completed", false),
                            priority = item.optString("priority", "medium")
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        tasks.clear()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= tasks.size) return null
        val task = tasks[position]

        val views = RemoteViews(context.packageName, R.layout.item_widget_task)

        // Title with optional strikethrough
        if (task.completed) {
            val span = SpannableString(task.title)
            span.setSpan(StrikethroughSpan(), 0, span.length, 0)
            views.setTextViewText(R.id.widget_item_title, span)
            views.setTextColor(R.id.widget_item_title, Color.parseColor("#737373"))
            views.setInt(R.id.widget_item_check, "setBackgroundResource", R.drawable.widget_checkbox_checked_bg)
        } else {
            views.setTextViewText(R.id.widget_item_title, task.title)
            views.setTextColor(R.id.widget_item_title, Color.WHITE)
            views.setInt(R.id.widget_item_check, "setBackgroundResource", R.drawable.widget_checkbox_bg)
        }



        // Click Fill-In Intent
        val fillInIntent = Intent().apply {
            putExtra("task_id", task.id)
            putExtra("task_title", task.title)
        }
        views.setOnClickFillInIntent(R.id.widget_task_item_container, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
