package com.todocat.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import android.app.Activity
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class QuickAddActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_add)

        window.setLayout(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.MATCH_PARENT
        )

        val root = findViewById<android.view.View>(R.id.quick_add_root)
        val card = findViewById<android.view.View>(R.id.quick_add_card)
        val input = findViewById<EditText>(R.id.quick_add_input)
        val btnCancel = findViewById<TextView>(R.id.quick_add_btn_cancel)
        val btnSubmit = findViewById<TextView>(R.id.quick_add_btn_submit)

        root.setOnClickListener { finish() }
        card.setOnClickListener { /* Intercept touches so clicks don't dismiss the dialog */ }

        val homePrefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val isDark = intent.getBooleanExtra("is_dark", homePrefs.getBoolean("is_dark", false))
        if (!isDark) applyLightTheme()

        btnCancel.setOnClickListener { finish() }
        btnSubmit.setOnClickListener { submitTask(input.text.toString().trim()) }
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

    private fun applyLightTheme() {
        val card = findViewById<android.view.View>(R.id.quick_add_card)
        val title = findViewById<TextView>(R.id.quick_add_title)
        val subtitle = findViewById<TextView>(R.id.quick_add_subtitle)
        val input = findViewById<EditText>(R.id.quick_add_input)
        val btnCancel = findViewById<TextView>(R.id.quick_add_btn_cancel)
        val btnSubmit = findViewById<TextView>(R.id.quick_add_btn_submit)

        val density = resources.displayMetrics.density

        card.background = android.graphics.drawable.GradientDrawable().apply {
            setColor(android.graphics.Color.parseColor("#F7E9DD"))
            cornerRadius = 24 * density
            setStroke((1.2f * density).toInt(), android.graphics.Color.parseColor("#E8D9C2"))
        }

        title.setTextColor(android.graphics.Color.parseColor("#2B1D16"))
        subtitle.setTextColor(android.graphics.Color.parseColor("#8A7867"))

        input.background = android.graphics.drawable.GradientDrawable().apply {
            setColor(android.graphics.Color.parseColor("#F8EEDF"))
            cornerRadius = 14 * density
            setStroke((1 * density).toInt(), android.graphics.Color.parseColor("#E8D9C2"))
        }
        input.setTextColor(android.graphics.Color.parseColor("#2B1D16"))
        input.setHintTextColor(android.graphics.Color.parseColor("#8A7867"))

        btnCancel.setTextColor(android.graphics.Color.parseColor("#8A7867"))

        btnSubmit.background = android.graphics.drawable.GradientDrawable().apply {
            setColor(android.graphics.Color.parseColor("#F7E9DD"))
            cornerRadius = 18 * density
            setStroke((1.5f * density).toInt(), android.graphics.Color.parseColor("#E8D9C2"))
        }
        btnSubmit.setTextColor(android.graphics.Color.parseColor("#2B1D16"))
    }

    private fun submitTask(title: String) {
        if (title.isEmpty()) {
            Toast.makeText(this, "Please enter a task", Toast.LENGTH_SHORT).show()
            return
        }
        doSubmit(title)
        finish()
    }

    private fun doSubmit(title: String) {
        val homePrefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val rawJson = homePrefs.getString("tasks_json", null)
            ?: flutterPrefs.getString("flutter.tasks_json", null)
            ?: flutterPrefs.getString("tasks_json", null)

        val existingArray = if (!rawJson.isNullOrEmpty()) JSONArray(rawJson) else JSONArray()

        val nowIso = TaskUtils.nowIso()
        val newTask = JSONObject()
        newTask.put("id", UUID.randomUUID().toString())
        newTask.put("title", title)
        newTask.put("completed", false)
        newTask.put("priority", "medium")
        newTask.put("createdAt", nowIso)
        newTask.put("updatedAt", nowIso)

        val updatedArray = TaskUtils.prependTask(existingArray, newTask)
        val updatedJsonString = updatedArray.toString()

        val (pendingCount, totalCount) = TaskUtils.countTasks(updatedArray)
        val completedCount = totalCount - pendingCount
        val speedPercent = TaskUtils.calcSpeedPercent(pendingCount, totalCount)

        homePrefs.edit()
            .putString("tasks_json", updatedJsonString)
            .putInt("pending_count", pendingCount)
            .putInt("total_count", totalCount)
            .putInt("speed_percent", speedPercent)
            .apply()

        flutterPrefs.edit()
            .putString("flutter.tasks_json", updatedJsonString)
            .putString("tasks_json", updatedJsonString)
            .putInt("flutter.pending_count", pendingCount)
            .putInt("flutter.total_count", totalCount)
            .apply()

        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

        val listWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, TodoCatListWidgetProvider::class.java)
        )
        for (id in listWidgetIds) {
            TodoCatListWidgetProvider.updateListWidget(
                applicationContext, appWidgetManager, id, pendingCount, completedCount
            )
        }

        val catWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, TodoCatWidgetProvider::class.java)
        )
        for (id in catWidgetIds) {
            TodoCatWidgetProvider.updateCatWidget(
                applicationContext, appWidgetManager, id, pendingCount, completedCount, speedPercent
            )
        }

        for (id in listWidgetIds) {
            appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_list_view)
        }

        MainActivity.notifyTasksUpdated(updatedJsonString)
        Toast.makeText(this, "Task added!", Toast.LENGTH_SHORT).show()
    }
}
