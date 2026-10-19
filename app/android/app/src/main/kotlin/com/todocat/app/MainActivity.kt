package com.todocat.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.todocat.app/floating_cat"

    companion object {
        private var methodChannel: MethodChannel? = null

        fun notifyTasksUpdated(tasksJson: String) {
            methodChannel?.let { ch ->
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    ch.invokeMethod("onTasksUpdated", mapOf("tasksJson" to tasksJson))
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> {
                    val hasPerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPerm)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "startFloatingCat" -> {
                    val intent = buildFloatingCatIntent(FloatingCatService.ACTION_START, call)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "updateFloatingCat" -> {
                    startService(buildFloatingCatIntent(FloatingCatService.ACTION_UPDATE, call))
                    result.success(true)
                }
                "stopFloatingCat" -> {
                    val intent = Intent(this, FloatingCatService::class.java).apply {
                        action = FloatingCatService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "isFloatingCatRunning" -> {
                    result.success(FloatingCatService.isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun buildFloatingCatIntent(action: String, call: io.flutter.plugin.common.MethodCall): Intent {
        return Intent(this, FloatingCatService::class.java).apply {
            this.action = action
            putExtra(FloatingCatService.EXTRA_SPEED_PERCENT, call.argument<Int>("speedPercent") ?: 0)
            putExtra(FloatingCatService.EXTRA_SPEED_MESSAGE, call.argument<String>("speedMessage") ?: "TodoCat is running")
            call.argument<Boolean>("isCatWhite")?.let { putExtra(FloatingCatService.EXTRA_IS_WHITE, it) }
            call.argument<Boolean>("isDark")?.let { putExtra(FloatingCatService.EXTRA_IS_DARK, it) }
            call.argument<String>("tasksJson")?.let { putExtra(FloatingCatService.EXTRA_TASKS_JSON, it) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
