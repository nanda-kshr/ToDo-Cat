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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    val speedPercent = call.argument<Int>("speedPercent") ?: 0
                    val speedMessage = call.argument<String>("speedMessage") ?: "TodoCat is running"
                    val tasksJson = call.argument<String>("tasksJson")
                    val isCatWhite = call.argument<Boolean>("isCatWhite")
                    val isDark = call.argument<Boolean>("isDark")
                    val intent = Intent(this, FloatingCatService::class.java).apply {
                        action = FloatingCatService.ACTION_START
                        putExtra(FloatingCatService.EXTRA_SPEED_PERCENT, speedPercent)
                        putExtra(FloatingCatService.EXTRA_SPEED_MESSAGE, speedMessage)
                        if (isCatWhite != null) {
                            putExtra(FloatingCatService.EXTRA_IS_WHITE, isCatWhite)
                        }
                        if (isDark != null) {
                            putExtra(FloatingCatService.EXTRA_IS_DARK, isDark)
                        }
                        if (tasksJson != null) {
                            putExtra(FloatingCatService.EXTRA_TASKS_JSON, tasksJson)
                        }
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "updateFloatingCat" -> {
                    val speedPercent = call.argument<Int>("speedPercent") ?: 0
                    val speedMessage = call.argument<String>("speedMessage") ?: "TodoCat is running"
                    val tasksJson = call.argument<String>("tasksJson")
                    val isCatWhite = call.argument<Boolean>("isCatWhite")
                    val isDark = call.argument<Boolean>("isDark")
                    val intent = Intent(this, FloatingCatService::class.java).apply {
                        action = FloatingCatService.ACTION_UPDATE
                        putExtra(FloatingCatService.EXTRA_SPEED_PERCENT, speedPercent)
                        putExtra(FloatingCatService.EXTRA_SPEED_MESSAGE, speedMessage)
                        if (isCatWhite != null) {
                            putExtra(FloatingCatService.EXTRA_IS_WHITE, isCatWhite)
                        }
                        if (isDark != null) {
                            putExtra(FloatingCatService.EXTRA_IS_DARK, isDark)
                        }
                        if (tasksJson != null) {
                            putExtra(FloatingCatService.EXTRA_TASKS_JSON, tasksJson)
                        }
                    }
                    startService(intent)
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
