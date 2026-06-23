package com.aasoft.lockapp

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.util.Log
import java.io.File

class AppLockAccessibilityService : AccessibilityService() {

    private var lockOverlayView: View? = null
    private var windowManager: WindowManager? = null
    private var activeLockedPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        Log.d("LockApp", "AppLockAccessibilityService connected.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            if (event == null) return
            
            var packageName = event.packageName?.toString()
            if (packageName == null) {
                packageName = rootInActiveWindow?.packageName?.toString()
            }
            if (packageName == null) return
            
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
            
            Log.d("LockApp", "onAccessibilityEvent: package=$packageName, class=${event.className}")
            
            val prefs: SharedPreferences = getSharedPreferences("LockAppPrefs", Context.MODE_PRIVATE)
            var lockedAppsRaw = prefs.getString("locked_apps", "") ?: ""
            var isLimitReached = prefs.getBoolean("is_limit_reached", false)

            try {
                val appsFile = File(filesDir, "locked_apps.txt")
                if (appsFile.exists()) {
                    lockedAppsRaw = appsFile.readText()
                }
                val limitFile = File(filesDir, "is_limit_reached.txt")
                if (limitFile.exists()) {
                    isLimitReached = limitFile.readText() == "1"
                }
            } catch (e: Exception) {
                Log.e("LockApp", "Failed to read backup configuration files: ${e.message}", e)
            }

            val lockedApps = lockedAppsRaw.split(",").filter { it.isNotEmpty() }

            if (isLimitReached && lockedApps.contains(packageName)) {
                // If target locked app is opened and limit is reached, show overlay
                showOverlay(packageName)
            } else {
                // Navigate away logic
                // If it is our own app, check if it's the actual MainActivity or FlutterActivity
                if (packageName == "com.aasoft.lockapp") {
                    val className = event.className?.toString() ?: ""
                    if (className.contains("MainActivity") || className.contains("FlutterActivity") || className.contains("LockScreenActivity")) {
                        Log.d("LockApp", "Dismissing overlay because user opened main app activity: $className")
                        removeOverlay()
                    }
                    return
                }
                
                // If it is a launcher, we always remove overlay
                val launchers = getLauncherPackages()
                if (launchers.contains(packageName)) {
                    removeOverlay()
                    return
                }
                
                // If it is a system or keyboard package, ignore it (keep current overlay state)
                if (isSystemOrInputPackage(packageName)) {
                    return
                }
                
                // If it is any other app that is not in lockedApps, remove overlay
                if (!lockedApps.contains(packageName)) {
                    removeOverlay()
                }
            }
        } catch (e: Exception) {
            Log.e("LockApp", "Error in onAccessibilityEvent: ${e.message}", e)
        }
    }

    private fun getLauncherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfos = packageManager.queryIntentActivities(intent, 0)
        val packages = mutableSetOf<String>()
        for (info in resolveInfos) {
            info.activityInfo?.packageName?.let { packages.add(it) }
        }
        return packages
    }

    private fun isSystemOrInputPackage(packageName: String): Boolean {
        if (packageName == "android" || packageName == "com.android.systemui" || packageName == "com.android.permissioncontroller") {
            return true
        }
        if (packageName.contains("inputmethod") || packageName.contains("keyboard") || packageName.contains("ime")) {
            return true
        }
        if (packageName.startsWith("com.miui.") || packageName.startsWith("com.xiaomi.")) {
            if (packageName == "com.miui.home" || packageName == "com.miui.mihome") {
                return false
            }
            return true
        }
        return false
    }

    private fun showOverlay(packageName: String) {
        if (lockOverlayView != null) {
            // Already showing
            return
        }

        activeLockedPackage = packageName
        Log.d("LockApp", "Showing lock overlay for package: $packageName")

        // Create the overlay view (same layout as LockScreenActivity)
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackground(GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor("#0F172A"), Color.parseColor("#1E293B"))
            ))
        }

        val iconText = TextView(this).apply {
            text = "⏳"
            textSize = 64f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        val title = TextView(this).apply {
            text = "Günlük Sınır Doldu!"
            textSize = 28f
            setTextColor(Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        val subtitle = TextView(this).apply {
            text = "Bugünkü sosyal medya sürenizi tamamladınız.\nDevam etmek için LockApp'e dönüp 5 dakika kazanmalısınız."
            textSize = 16f
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.2f)
            setPadding(0, 0, 0, 80)
        }

        val btnHome = Button(this).apply {
            text = "Jeton Kazan ve Süre Al"
            setTextColor(Color.WHITE)
            textSize = 16f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(64, 32, 64, 32)
            
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#3B82F6"))
                cornerRadius = 24f
            }
            setBackground(btnBg)
            
            setOnClickListener {
                removeOverlay()
                val intent = Intent(this@AppLockAccessibilityService, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                startActivity(intent)
            }
        }

        mainLayout.addView(iconText)
        mainLayout.addView(title)
        mainLayout.addView(subtitle)
        mainLayout.addView(btnHome)

        // Make layout focusable to capture back press
        mainLayout.isFocusableInTouchMode = true
        mainLayout.requestFocus()
        mainLayout.setOnKeyListener { _, keyCode, event ->
            if (keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_DOWN) {
                // Intercept back button and redirect to home launcher
                val startMain = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(startMain)
                true
            } else {
                false
            }
        }

        lockOverlayView = mainLayout

        val layoutParams = WindowManager.LayoutParams().apply {
            type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            format = PixelFormat.TRANSLUCENT
            flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
        }

        try {
            windowManager?.addView(mainLayout, layoutParams)
        } catch (e: Exception) {
            Log.e("LockApp", "Failed to add overlay view: ${e.message}", e)
            lockOverlayView = null
        }
    }

    private fun removeOverlay() {
        val view = lockOverlayView ?: return
        Log.d("LockApp", "Removing lock overlay.")
        try {
            windowManager?.removeView(view)
        } catch (e: Exception) {
            Log.e("LockApp", "Failed to remove overlay view: ${e.message}", e)
        } finally {
            lockOverlayView = null
            activeLockedPackage = null
        }
    }

    override fun onInterrupt() {
        removeOverlay()
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }
}
