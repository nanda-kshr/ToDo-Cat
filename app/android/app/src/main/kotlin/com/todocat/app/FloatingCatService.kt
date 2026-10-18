package com.todocat.app

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import kotlin.math.abs

class FloatingCatService : Service() {

    companion object {
        const val ACTION_START = "com.todocat.app.START_FLOATING_CAT"
        const val ACTION_STOP = "com.todocat.app.STOP_FLOATING_CAT"
        const val ACTION_UPDATE = "com.todocat.app.UPDATE_FLOATING_CAT"

        const val EXTRA_SPEED_PERCENT = "speed_percent"
        const val EXTRA_SPEED_MESSAGE = "speed_message"
        const val EXTRA_TASKS_JSON = "tasks_json"
        const val EXTRA_IS_WHITE = "is_white"

        const val NOTIFICATION_ID = 8821
        const val CHANNEL_ID = "todocat_floating_cat_channel"

        var isRunning = false
            private set
    }

    private var windowManager: WindowManager? = null
    private var floatingContainer: FrameLayout? = null
    private var collapsedView: FrameLayout? = null
    private var expandedView: LinearLayout? = null
    private var dismissTargetView: FrameLayout? = null
    private var dismissTargetCircle: FrameLayout? = null

    private var imageView: ImageView? = null
    private var headerCatView: ImageView? = null
    private var tasksContainer: LinearLayout? = null
    private var speedBadgeText: TextView? = null

    private val handler = Handler(Looper.getMainLooper())
    private var currentFrameIndex = 0
    private var frameIntervalMs = 70L
    private var speedPercent = 0
    private var speedMessage = "TodoCat is running"
    private var tasksJsonString: String? = null
    private var isExpanded = false
    private var isCatWhite = false
    private var collapsedX = 0
    private var collapsedY = 0

    private val snigletFont: Typeface? by lazy {
        try {
            androidx.core.content.res.ResourcesCompat.getFont(this, R.font.sniglet)
        } catch (_: Exception) {
            null
        }
    }

    private val blackCatFrames = intArrayOf(
        R.drawable.cat_0,
        R.drawable.cat_1,
        R.drawable.cat_2,
        R.drawable.cat_3,
        R.drawable.cat_4,
        R.drawable.cat_5,
        R.drawable.cat_6
    )

    private val whiteCatFrames = intArrayOf(
        R.drawable.cat_white_0,
        R.drawable.cat_white_1,
        R.drawable.cat_white_2,
        R.drawable.cat_white_3,
        R.drawable.cat_white_4,
        R.drawable.cat_white_5,
        R.drawable.cat_white_6
    )

    private val frameRunnable = object : Runnable {
        override fun run() {
            val frames = if (isCatWhite) whiteCatFrames else blackCatFrames
            if (speedPercent <= 0) {
                imageView?.setImageResource(frames[0])
                headerCatView?.setImageResource(frames[0])
                handler.postDelayed(this, 400L)
                return
            }

            val resId = frames[currentFrameIndex % frames.size]
            imageView?.setImageResource(resId)
            headerCatView?.setImageResource(resId)
            currentFrameIndex = (currentFrameIndex + 1) % frames.size
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

        speedPercent = intent?.getIntExtra(EXTRA_SPEED_PERCENT, speedPercent) ?: speedPercent
        speedMessage = intent?.getStringExtra(EXTRA_SPEED_MESSAGE) ?: speedMessage
        if (intent?.hasExtra(EXTRA_IS_WHITE) == true) {
            isCatWhite = intent.getBooleanExtra(EXTRA_IS_WHITE, false)
        } else {
            isCatWhite = checkCatWhitePreference()
        }
        val newTasks = intent?.getStringExtra(EXTRA_TASKS_JSON)
        if (!newTasks.isNullOrEmpty()) {
            tasksJsonString = newTasks
        } else if (tasksJsonString == null) {
            loadTasksFromStorage()
        }

        calculateInterval(speedPercent)
        startForegroundServiceWithNotification()

        if (floatingContainer == null) {
            initFloatingViews()
        } else {
            updateExpandedUi()
        }

        handler.removeCallbacks(frameRunnable)
        handler.post(frameRunnable)

        return START_STICKY
    }

    private fun loadTasksFromStorage() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            tasksJsonString = prefs.getString("flutter.tasks_json", null)
                ?: prefs.getString("tasks_json", null)
        } catch (_: Exception) {}
    }

    private fun checkCatWhitePreference(): Boolean {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val variant = prefs.getString("flutter.cat_color_variant", "auto") ?: "auto"
            if (variant == "white") return true
            if (variant == "black") return false
            val themeMode = prefs.getString("flutter.theme_mode", "system") ?: "system"
            if (themeMode == "dark") return true
            if (themeMode == "light") return false
            val nightModeFlags = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
            return nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
        } catch (_: Exception) {
            return false
        }
    }

    private fun saveTasksToStorage(json: String) {
        tasksJsonString = json
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("flutter.tasks_json", json)
                .putString("tasks_json", json)
                .apply()
        } catch (_: Exception) {}
    }

    private fun calculateInterval(speed: Int) {
        val clamped = speed.coerceIn(0, 100)
        frameIntervalMs = if (clamped <= 0) {
            500L
        } else {
            (330 - (clamped * 2.95).toLong()).coerceIn(35L, 330L)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TodoCat Floating Companion",
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

        val notifIcon = if (isCatWhite) R.drawable.cat_white_0 else R.drawable.cat_0
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TodoCat Floating Companion")
            .setContentText(speedMessage)
            .setSmallIcon(notifIcon)
            .setContentIntent(openAppPendingIntent)
            .addAction(0, "Close Cat", stopPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
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

    @SuppressLint("ClickableViewAccessibility")
    private fun initFloatingViews() {
        val wm = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return
        windowManager = wm

        val density = resources.displayMetrics.density
        val catSizePx = (56 * density).toInt()

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        // --- 1. Floating Window Params (Collapsed initially) ---
        val catParams = WindowManager.LayoutParams(
            catSizePx,
            catSizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (20 * density).toInt()
            y = (200 * density).toInt()
        }

        // --- 2. Sleek Minimal Dismiss Target View at bottom center ---
        val dismissSizePx = (52 * density).toInt()
        val dismissParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = (36 * density).toInt()
        }

        val dismissContainer = FrameLayout(this).apply {
            visibility = View.GONE
            alpha = 0f
        }

        val dismissCircle = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#80171717")) // Sleek translucent dark
                setStroke((1.5f * density).toInt(), Color.parseColor("#40FFFFFF"))
            }
        }
        dismissTargetCircle = dismissCircle

        val dismissIcon = TextView(this).apply {
            text = "✕"
            textSize = 17f
            setTextColor(Color.parseColor("#F4F4F5"))
            gravity = Gravity.CENTER
            typeface = snigletFont ?: Typeface.DEFAULT_BOLD
        }
        dismissCircle.addView(dismissIcon, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.CENTER
        ))

        dismissContainer.addView(dismissCircle, FrameLayout.LayoutParams(dismissSizePx, dismissSizePx))
        dismissTargetView = dismissContainer
        wm.addView(dismissContainer, dismissParams)

        // --- 3. Main Floating Container ---
        val root = FrameLayout(this)
        floatingContainer = root

        // Collapsed View: Pure transparent background!
        val colView = FrameLayout(this).apply {
            background = null
            elevation = 0f
        }
        val iv = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
            val frames = if (isCatWhite) whiteCatFrames else blackCatFrames
            setImageResource(frames[0])
            background = null
        }
        imageView = iv
        colView.addView(iv, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
        collapsedView = colView
        root.addView(colView, FrameLayout.LayoutParams(catSizePx, catSizePx))

        // Expanded View: Sleek rounded tasks card
        val expView = buildExpandedView(density, wm, catParams)
        expView.visibility = View.GONE
        expandedView = expView
        root.addView(expView)

        // --- 4. Drag & Tap Logic for Collapsed View ---
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        colView.setOnTouchListener { _, event ->
            val dm = resources.displayMetrics
            val screenW = dm.widthPixels
            val screenH = dm.heightPixels

            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = catParams.x
                    initialY = catParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - initialTouchX
                    val deltaY = event.rawY - initialTouchY

                    if (!isDragging && (abs(deltaX) > 8 || abs(deltaY) > 8)) {
                        isDragging = true
                        dismissContainer.visibility = View.VISIBLE
                        dismissContainer.animate().alpha(1.0f).setDuration(150).start()
                    }

                    if (isDragging) {
                        catParams.x = initialX + deltaX.toInt()
                        catParams.y = initialY + deltaY.toInt()
                        wm.updateViewLayout(root, catParams)

                        // Check if cat is near the bottom center dismiss target
                        val isOver = event.rawY > (screenH - 140 * density) &&
                                abs(event.rawX - screenW / 2) < (70 * density)

                        if (isOver) {
                            dismissCircle.background = GradientDrawable().apply {
                                shape = GradientDrawable.OVAL
                                setColor(Color.parseColor("#CC991B1B")) // Refined crimson
                                setStroke((1.5f * density).toInt(), Color.parseColor("#F87171"))
                            }
                            dismissCircle.animate().scaleX(1.10f).scaleY(1.10f).setDuration(120).start()
                        } else {
                            dismissCircle.background = GradientDrawable().apply {
                                shape = GradientDrawable.OVAL
                                setColor(Color.parseColor("#80171717"))
                                setStroke((1.5f * density).toInt(), Color.parseColor("#40FFFFFF"))
                            }
                            dismissCircle.animate().scaleX(1.0f).scaleY(1.0f).setDuration(120).start()
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    dismissContainer.animate().alpha(0f).setDuration(120).withEndAction {
                        dismissContainer.visibility = View.GONE
                    }.start()

                    if (isDragging) {
                        val isOver = event.rawY > (screenH - 140 * density) &&
                                abs(event.rawX - screenW / 2) < (70 * density)
                        if (isOver) {
                            Toast.makeText(this, "Floating Cat closed", Toast.LENGTH_SHORT).show()
                            stopSelf()
                            return@setOnTouchListener true
                        }
                    } else {
                        val totalDeltaX = abs(event.rawX - initialTouchX)
                        val totalDeltaY = abs(event.rawY - initialTouchY)
                        if (totalDeltaX < 12 && totalDeltaY < 12) {
                            // TAP DETECTED -> Expand Tasks Panel!
                            expand(wm, catParams, density)
                        }
                    }
                    true
                }
                else -> false
            }
        }

        wm.addView(root, catParams)
    }

    private fun buildExpandedView(
        density: Float,
        wm: WindowManager,
        catParams: WindowManager.LayoutParams
    ): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#171717"))
                cornerRadius = 18 * density
                setStroke((1 * density).toInt(), Color.parseColor("#2E2E2E"))
            }
            val pad = (14 * density).toInt()
            setPadding(pad, pad, pad, pad)
            elevation = 12 * density

            // Header Row: [Mini Cat, Title + Speed Badge, Collapse Button]
            val headerRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL

                val catIv = ImageView(context).apply {
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    setImageResource(R.drawable.cat_0)
                }
                headerCatView = catIv
                addView(catIv, LinearLayout.LayoutParams((32 * density).toInt(), (32 * density).toInt()))

                val titleCol = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding((10 * density).toInt(), 0, 0, 0)

                    val titleText = TextView(context).apply {
                        text = "TodoCat"
                        setTextColor(Color.WHITE)
                        textSize = 15f
                        typeface = snigletFont ?: Typeface.DEFAULT_BOLD
                    }
                    addView(titleText)

                    val badge = TextView(context).apply {
                        text = "$speedPercent% Speed"
                        setTextColor(Color.parseColor("#F59E0B"))
                        textSize = 11f
                        snigletFont?.let { typeface = it }
                    }
                    speedBadgeText = badge
                    addView(badge)
                }
                addView(titleCol, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

                // Minimize / Close icon button
                val closeBtn = TextView(context).apply {
                    text = "✕"
                    setTextColor(Color.parseColor("#A3A3A3"))
                    textSize = 16f
                    typeface = Typeface.DEFAULT_BOLD
                    setPadding((8 * density).toInt(), (4 * density).toInt(), (8 * density).toInt(), (4 * density).toInt())
                    setOnClickListener {
                        collapse(wm, catParams, density)
                    }
                }
                addView(closeBtn)
            }
            addView(headerRow)

            // Divider
            val div = View(context).apply {
                setBackgroundColor(Color.parseColor("#262626"))
            }
            val divParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (1 * density).toInt()
            ).apply {
                topMargin = (10 * density).toInt()
                bottomMargin = (10 * density).toInt()
            }
            addView(div, divParams)

            // Scrollable Tasks List Container
            val scrollView = ScrollView(context).apply {
                isFillViewport = true
            }
            val taskListCol = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
            }
            tasksContainer = taskListCol
            scrollView.addView(taskListCol, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ))
            addView(scrollView, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            ))

            // Inline Quick Add Task Row: [EditText, Add Button]
            val quickAddRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, (10 * density).toInt(), 0, 0)

                val input = EditText(context).apply {
                    hint = "Quick add a task..."
                    setHintTextColor(Color.parseColor("#737373"))
                    setTextColor(Color.WHITE)
                    textSize = 13f
                    snigletFont?.let { typeface = it }
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#262626"))
                        cornerRadius = 8 * density
                    }
                    val p = (8 * density).toInt()
                    setPadding(p, p, p, p)
                }
                addView(input, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

                val addBtn = TextView(context).apply {
                    text = "+ Add"
                    setTextColor(Color.BLACK)
                    textSize = 12f
                    typeface = snigletFont ?: Typeface.DEFAULT_BOLD
                    background = GradientDrawable().apply {
                        setColor(Color.WHITE)
                        cornerRadius = 8 * density
                    }
                    val hp = (12 * density).toInt()
                    val vp = (8 * density).toInt()
                    setPadding(hp, vp, hp, vp)
                    setOnClickListener {
                        val title = input.text.toString().trim()
                        if (title.isNotEmpty()) {
                            addNewTask(title)
                            input.setText("")
                        }
                    }
                }
                val addParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    marginStart = (8 * density).toInt()
                }
                addView(addBtn, addParams)
            }
            addView(quickAddRow)

            // Open Full App Button
            val openAppBtn = TextView(context).apply {
                text = "Open TodoCat App"
                setTextColor(Color.parseColor("#A5B4FC"))
                textSize = 12f
                typeface = snigletFont ?: Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(0, (8 * density).toInt(), 0, (2 * density).toInt())
                setOnClickListener {
                    val intent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    startActivity(intent)
                    collapse(wm, catParams, density)
                }
            }
            addView(openAppBtn)
        }
    }

    private fun expand(wm: WindowManager, catParams: WindowManager.LayoutParams, density: Float) {
        if (isExpanded) return
        isExpanded = true

        // Save collapsed position to restore when closed
        collapsedX = catParams.x
        collapsedY = catParams.y

        val dm = resources.displayMetrics
        val w = (dm.widthPixels * 0.90).toInt().coerceAtMost((360 * density).toInt())
        val h = (440 * density).toInt().coerceAtMost((dm.heightPixels * 0.72).toInt())

        catParams.width = w
        catParams.height = h
        // Center popup on screen to prevent clipping off-screen
        catParams.x = ((dm.widthPixels - w) / 2).coerceAtLeast(0)
        catParams.y = ((dm.heightPixels - h) / 2).coerceAtLeast(0)
        catParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL

        collapsedView?.visibility = View.GONE
        expandedView?.visibility = View.VISIBLE

        updateExpandedUi()
        wm.updateViewLayout(floatingContainer, catParams)
    }

    private fun collapse(wm: WindowManager, catParams: WindowManager.LayoutParams, density: Float) {
        if (!isExpanded) return
        isExpanded = false

        val dm = resources.displayMetrics
        val catSizePx = (56 * density).toInt()
        catParams.width = catSizePx
        catParams.height = catSizePx
        // Restore to exact collapsed coordinates on screen
        catParams.x = collapsedX.coerceIn(0, (dm.widthPixels - catSizePx).coerceAtLeast(0))
        catParams.y = collapsedY.coerceIn(0, (dm.heightPixels - catSizePx).coerceAtLeast(0))
        catParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

        expandedView?.visibility = View.GONE
        collapsedView?.visibility = View.VISIBLE

        wm.updateViewLayout(floatingContainer, catParams)
    }

    private fun updateExpandedUi() {
        val container = tasksContainer ?: return
        val density = resources.displayMetrics.density
        container.removeAllViews()

        speedBadgeText?.text = "$speedPercent% Speed • $speedMessage"

        val raw = tasksJsonString
        if (raw.isNullOrEmpty()) {
            val emptyTv = TextView(this).apply {
                text = "No tasks yet!\nType above to add a new task."
                setTextColor(Color.parseColor("#737373"))
                textSize = 13f
                snigletFont?.let { typeface = it }
                gravity = Gravity.CENTER
                setPadding(0, (30 * density).toInt(), 0, (30 * density).toInt())
            }
            container.addView(emptyTv)
            return
        }

        try {
            val jsonArray = JSONArray(raw)
            if (jsonArray.length() == 0) {
                val emptyTv = TextView(this).apply {
                    text = "No tasks yet!\nType above to add a new task."
                    setTextColor(Color.parseColor("#737373"))
                    textSize = 13f
                    snigletFont?.let { typeface = it }
                    gravity = Gravity.CENTER
                    setPadding(0, (30 * density).toInt(), 0, (30 * density).toInt())
                }
                container.addView(emptyTv)
                return
            }

            for (i in 0 until jsonArray.length()) {
                val item = jsonArray.getJSONObject(i)
                val id = item.optString("id", "")
                val title = item.optString("title", "Untitled Task")
                val completed = item.optBoolean("completed", false)
                val priority = item.optString("priority", "medium")

                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    background = GradientDrawable().apply {
                        setColor(if (completed) Color.parseColor("#121212") else Color.parseColor("#1F1F1F"))
                        cornerRadius = 8 * density
                    }
                    val p = (8 * density).toInt()
                    setPadding(p, p, p, p)
                }

                // Checkbox
                val checkView = TextView(this).apply {
                    text = ""
                    textSize = 12f
                    setTextColor(Color.BLACK)
                    gravity = Gravity.CENTER
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = 4 * density
                        setColor(if (completed) Color.parseColor("#10B981") else Color.TRANSPARENT)
                        setStroke((1.5f * density).toInt(), if (completed) Color.parseColor("#10B981") else Color.parseColor("#525252"))
                    }
                }
                val checkParams = LinearLayout.LayoutParams((18 * density).toInt(), (18 * density).toInt()).apply {
                    marginEnd = (10 * density).toInt()
                }
                row.addView(checkView, checkParams)

                // Title
                val titleView = TextView(this).apply {
                    this.text = title
                    textSize = 13f
                    snigletFont?.let { typeface = it }
                    setTextColor(if (completed) Color.parseColor("#737373") else Color.WHITE)
                    if (completed) {
                        paintFlags = paintFlags or Paint.STRIKE_THRU_TEXT_FLAG
                    }
                }
                row.addView(titleView, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

                // Priority Indicator
                val priorityColor = when (priority.lowercase()) {
                    "high" -> Color.parseColor("#EF4444")
                    "low" -> Color.parseColor("#6B7280")
                    else -> Color.parseColor("#F59E0B")
                }
                val prioDot = View(this).apply {
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(priorityColor)
                    }
                }
                val prioParams = LinearLayout.LayoutParams((6 * density).toInt(), (6 * density).toInt()).apply {
                    marginStart = (6 * density).toInt()
                }
                row.addView(prioDot, prioParams)

                // Toggle click listener
                row.setOnClickListener {
                    toggleTaskCompleted(id, !completed)
                }

                val rowParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomMargin = (6 * density).toInt()
                }
                container.addView(row, rowParams)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun toggleTaskCompleted(taskId: String, newCompleted: Boolean) {
        val raw = tasksJsonString ?: return
        try {
            val jsonArray = JSONArray(raw)
            var activeCount = 0
            for (i in 0 until jsonArray.length()) {
                val item = jsonArray.getJSONObject(i)
                if (item.optString("id") == taskId) {
                    item.put("completed", newCompleted)
                }
                if (!item.optBoolean("completed", false)) {
                    activeCount++
                }
            }

            val updatedJson = jsonArray.toString()
            saveTasksToStorage(updatedJson)

            speedPercent = if (jsonArray.length() == 0 || activeCount == 0) 0 else ((activeCount / 5.0) * 100).toInt().coerceIn(0, 100)
            calculateInterval(speedPercent)
            handler.removeCallbacks(frameRunnable)
            handler.post(frameRunnable)

            updateExpandedUi()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun addNewTask(title: String) {
        try {
            val jsonArray = if (!tasksJsonString.isNullOrEmpty()) {
                JSONArray(tasksJsonString)
            } else {
                JSONArray()
            }

            val newTask = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("title", title)
                put("completed", false)
                put("priority", "medium")
            }

            // Prepend new task
            val newArray = JSONArray()
            newArray.put(newTask)
            for (i in 0 until jsonArray.length()) {
                newArray.put(jsonArray.get(i))
            }

            val updatedJson = newArray.toString()
            saveTasksToStorage(updatedJson)

            var activeCount = 0
            for (i in 0 until newArray.length()) {
                if (!newArray.getJSONObject(i).optBoolean("completed", false)) {
                    activeCount++
                }
            }
            speedPercent = if (newArray.length() == 0 || activeCount == 0) 0 else ((activeCount / 5.0) * 100).toInt().coerceIn(0, 100)
            calculateInterval(speedPercent)
            handler.removeCallbacks(frameRunnable)
            handler.post(frameRunnable)

            updateExpandedUi()
            Toast.makeText(this, "Task created!", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(frameRunnable)

        floatingContainer?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {}
            floatingContainer = null
        }

        dismissTargetView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {}
            dismissTargetView = null
        }

        super.onDestroy()
    }
}
