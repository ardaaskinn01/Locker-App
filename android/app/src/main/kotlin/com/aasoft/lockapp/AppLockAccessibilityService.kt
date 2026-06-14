package com.aasoft.lockapp

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppLockAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val packageName = event.packageName?.toString() ?: return
        
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val prefs: SharedPreferences = getSharedPreferences("LockAppPrefs", Context.MODE_PRIVATE)
        val lockedAppsRaw = prefs.getString("locked_apps", "") ?: ""
        val isLimitReached = prefs.getBoolean("is_limit_reached", false)

        val lockedApps = lockedAppsRaw.split(",").filter { it.isNotEmpty() }

        if (isLimitReached && lockedApps.contains(packageName)) {
            // Target locked app opened and limit reached -> Launch LockScreen
            val lockIntent = Intent(this, LockScreenActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_NO_ANIMATION or 
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                putExtra("LOCKED_PACKAGE", packageName)
            }
            startActivity(lockIntent)
        }
    }

    override fun onInterrupt() {
        // No operation
    }
}
