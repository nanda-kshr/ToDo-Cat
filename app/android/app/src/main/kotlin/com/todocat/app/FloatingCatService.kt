package com.todocat.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class FloatingCatService : Service() {

    companion object {
        const val ACTION_START = "com.todocat.app.START_FLOATING_CAT"
        const val ACTION_STOP = "com.todocat.app.STOP_FLOATING_CAT"
        const val ACTION_UPDATE = "com.todocat.app.UPDATE_FLOATING_CAT"

        const val EXTRA_SPEED_PERCENT = "speed_percent"
        const val EXTRA_SPEED_MESSAGE = "speed_message"

        const val NOTIFICATION_ID = 8821
        const val CHANNEL_ID = "todocat_floating_cat_channel"

        var isRunning = false
            private set
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var imageView: ImageView? = null

    private val handler = Handler(Looper.getMainLooper())
    private var currentFrameIndex = 0
    private var frameIntervalMs = 70L
    private var speedMessage = "TodoCat is running"

    private val frameResources = intArrayOf(
        R.drawable.cat_0,
        R.drawable.cat_1,
        R.drawable.cat_2,
        R.drawable.cat_3,
        R.drawable.cat_4,
        R.drawable.cat_5,
        R.drawable.cat_6,
        R.drawable.cat_7,
        R.drawable.cat_8,
        R.drawable.cat_9,
        R.drawable.cat_10,
        R.drawable.cat_11,
        R.drawable.cat_12,
        R.drawable.cat_13,
        R.drawable.cat_14
    )

    private val frameRunnable = object : Runnable {
        override fun run() {
            imageView?.setImageResource(frameResources[currentFrameIndex])
            currentFrameIndex = (currentFrameIndex + 1) % frameResources.size
            handler.postDelayed(this, frameIntervalMs)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        if (action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val speedPercent = intent?.getIntExtra(EXTRA_SPEED_PERCENT, 0) ?: 0
        speedMessage = intent?.getStringExtra(EXTRA_SPEED_MESSAGE) ?: "TodoCat is running"
        calculateInterval(speedPercent)

        startForegroundServiceWithNotification()

        if (floatingView == null) {
            initFloatingView()
            handler.post(frameRunnable)
        }

        return START_STICKY
    }

    private fun calculateInterval(speed: Int) {
        val clamped = speed.coerceIn(0, 100)
        frameIntervalMs = if (clamped <= 0) {
            100L // Relaxed idle jog when 0 tasks
        } else {
            (110 - (clamped * 0.75).toLong()).coerceIn(35L, 110L)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TodoCat Floating Cat",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows active floating cat runner on screen"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceWithNotification() {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, FloatingCatService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TodoCat Floating Companion")
            .setContentText(speedMessage)
            .setSmallIcon(R.drawable.cat_0)
            .setContentIntent(openAppPendingIntent)
            .addAction(0, "Close Cat", stopPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // API 34+
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun initFloatingView() {
        val wm = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return
        windowManager = wm

        val density = resources.displayMetrics.density
        val sizePx = (54 * density).toInt()

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (20 * density).toInt()
            y = (240 * density).toInt()
        }

        val card = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = 14 * density
            }
            background = bg
            val pad = (4 * density).toInt()
            setPadding(pad, pad, pad, pad)
            elevation = 10 * density
        }

        val iv = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
            setImageResource(R.drawable.cat_0)
        }
        imageView = iv

        card.addView(iv, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        // Drag & Tap Listener
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        card.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    wm.updateViewLayout(card, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val deltaX = abs(event.rawX - initialTouchX)
                    val deltaY = abs(event.rawY - initialTouchY)
                    if (deltaX < 12 && deltaY < 12) {
                        // Click detected
                        Toast.makeText(this, speedMessage, Toast.LENGTH_SHORT).show()
                    }
                    true
                }
                else -> false
            }
        }

        floatingView = card
        wm.addView(card, params)
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(frameRunnable)

        floatingView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {}
            floatingView = null
        }

        super.onDestroy()
    }
}
