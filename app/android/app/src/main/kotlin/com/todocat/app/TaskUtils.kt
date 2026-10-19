package com.todocat.app

import android.util.Log
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object TaskUtils {

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    fun nowIso(): String = isoDateFormat.format(Date())

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
