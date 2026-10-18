package com.todocat.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class QuickAddActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_add)

        val input = findViewById<EditText>(R.id.quick_add_input)
        val btnCancel = findViewById<TextView>(R.id.quick_add_btn_cancel)
        val btnSubmit = findViewById<TextView>(R.id.quick_add_btn_submit)

        btnCancel.setOnClickListener {
            finish()
        }

        btnSubmit.setOnClickListener {
            submitTask(input.text.toString().trim())
        }

        input.setOnEditorActionListener { _, _, _ ->
            submitTask(input.text.toString().trim())
            true
        }

        // Auto focus input and show keyboard
        input.requestFocus()
        input.postDelayed({
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
        }, 150)
    }

    private fun submitTask(title: String) {
        if (title.isEmpty()) {
            Toast.makeText(this, "Please enter a task", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val homePrefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val rawJson = homePrefs.getString("tasks_json", null)
                ?: flutterPrefs.getString("flutter.tasks_json", null)
                ?: flutterPrefs.getString("tasks_json", null)

            val jsonArray = if (!rawJson.isNullOrEmpty()) {
                JSONArray(rawJson)
            } else {
                JSONArray()
            }

            // Create new Task JSON
            val newTask = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("title", title)
                put("completed", false)
                put("priority", "medium")
                put("created_at", System.currentTimeMillis())
            }

            // Put new task at the top (index 0)
            val updatedArray = JSONArray()
            updatedArray.put(newTask)
            for (i in 0 until jsonArray.length()) {
                updatedArray.put(jsonArray.get(i))
            }

            val updatedJsonString = updatedArray.toString()
            val totalCount = updatedArray.length()
            var pendingCount = 0
            for (i in 0 until updatedArray.length()) {
                val item = updatedArray.getJSONObject(i)
                if (!item.optBoolean("completed", false)) {
                    pendingCount++
                }
            }

            val speedPercent = if (pendingCount == 0) 0 else ((pendingCount / 5.0) * 100).toInt().coerceIn(0, 100)

            // Save to HomeWidgetPreferences
            homePrefs.edit().apply {
                putString("tasks_json", updatedJsonString)
                putInt("pending_count", pendingCount)
                putInt("total_count", totalCount)
                putInt("speed_percent", speedPercent)
                apply()
            }

            // Save to FlutterSharedPreferences so Flutter loads it on launch
            flutterPrefs.edit().apply {
                putString("flutter.tasks_json", updatedJsonString)
                putString("tasks_json", updatedJsonString)
                putInt("flutter.pending_count", pendingCount)
                putInt("flutter.total_count", totalCount)
                apply()
            }

            // Trigger Widget Updates
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

            // 1. Update Tasks List Widgets
            val listWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(applicationContext, TodoCatListWidgetProvider::class.java)
            )
            listWidgetIds.forEach { id ->
                TodoCatListWidgetProvider.updateListWidget(applicationContext, appWidgetManager, id, pendingCount, totalCount - pendingCount)
            }

            // 2. Update Running Cat Widgets
            val catWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(applicationContext, TodoCatWidgetProvider::class.java)
            )
            catWidgetIds.forEach { id ->
                TodoCatWidgetProvider.updateCatWidget(applicationContext, appWidgetManager, id, pendingCount, totalCount - pendingCount, speedPercent)
            }

            // Notify ListView to refresh
            listWidgetIds.forEach { id ->
                appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_list_view)
            }

            // Real-time notification to running app
            MainActivity.notifyTasksUpdated(updatedJsonString)

            Toast.makeText(this, "Task added!", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        finish()
    }
}
