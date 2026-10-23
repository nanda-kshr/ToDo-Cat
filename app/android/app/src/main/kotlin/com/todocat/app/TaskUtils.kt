package com.todocat.app

import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object TaskUtils {

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    fun nowIso(): String = isoDateFormat.format(Date())

    /** Checks if given ISO timestamp matches today in local timezone. */
    fun isToday(isoString: String?): Boolean {
        if (isoString.isNullOrEmpty()) return false
        return try {
            val date: Date? = if (isoString.endsWith("Z")) {
                val cleanIso = if (isoString.length > 24 && isoString.contains(".")) {
                    val dotIdx = isoString.indexOf('.')
                    isoString.substring(0, dotIdx + 4) + "Z"
                } else isoString

                try {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                        timeZone = TimeZone.getTimeZone("UTC")
                    }.parse(cleanIso)
                } catch (_: Exception) {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
                        timeZone = TimeZone.getTimeZone("UTC")
                    }.parse(cleanIso)
                }
            } else {
                val cleanIso = if (isoString.contains(".") && isoString.length > isoString.indexOf('.') + 4) {
                    val dotIdx = isoString.indexOf('.')
                    isoString.substring(0, dotIdx + 4)
                } else isoString

                try {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).parse(cleanIso)
                } catch (_: Exception) {
                    try {
                        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(cleanIso)
                    } catch (_: Exception) {
                        SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(cleanIso)
                    }
                }
            }

            if (date == null) return false
            val cal = Calendar.getInstance().apply { time = date }
            val nowCal = Calendar.getInstance()
            cal.get(Calendar.YEAR) == nowCal.get(Calendar.YEAR) &&
                cal.get(Calendar.DAY_OF_YEAR) == nowCal.get(Calendar.DAY_OF_YEAR)
        } catch (_: Exception) {
            false
        }
    }

    /** Returns true if task is pending or completed today (matches HomeScreen logic). */
    fun isTodayTask(item: JSONObject): Boolean {
        val completed = item.optBoolean("completed", false)
        if (!completed) return true
        val updated = item.optString("updatedAt", "")
        val created = item.optString("createdAt", "")
        val dateStr = if (updated.isNotEmpty()) updated else created
        return isToday(dateStr)
    }

    /** Counts pending tasks and tasks completed today: returns Triple(pendingCount, completedTodayCount, totalTodayCount). */
    fun countTodayTasks(jsonArray: JSONArray): Triple<Int, Int, Int> {
        var pending = 0
        var completedToday = 0
        for (i in 0 until jsonArray.length()) {
            val item = jsonArray.getJSONObject(i)
            if (item.optBoolean("completed", false)) {
                val updated = item.optString("updatedAt", "")
                val created = item.optString("createdAt", "")
                val dateStr = if (updated.isNotEmpty()) updated else created
                if (isToday(dateStr)) {
                    completedToday++
                }
            } else {
                pending++
            }
        }
        return Triple(pending, completedToday, pending + completedToday)
    }

    /** Computes speed percent (0-100) from active task count. */
    fun calcSpeedPercent(activeCount: Int, totalCount: Int): Int {
        if (totalCount == 0 || activeCount == 0) return 0
        return ((activeCount / 5.0) * 100).toInt().coerceIn(0, 100)
    }

    /** Counts pending (non-completed) tasks and returns Pair(activeCount, totalCount). */
    fun countTasks(jsonArray: JSONArray): Pair<Int, Int> {
        val total = jsonArray.length()
        var active = 0
        for (i in 0 until total) {
            if (!jsonArray.getJSONObject(i).optBoolean("completed", false)) active++
        }
        return active to total
    }

    /** Prepends [newElement] to [existing] and returns new JSONArray. */
    fun prependTask(existing: JSONArray, newElement: org.json.JSONObject): JSONArray {
        val result = JSONArray()
        result.put(newElement)
        for (i in 0 until existing.length()) result.put(existing.get(i))
        return result
    }

    fun logError(tag: String, msg: String, e: Throwable) {
        Log.e(tag, msg, e)
    }
}
