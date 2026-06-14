package com.aasoft.lockapp

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lockapp/lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("LockAppPrefs", Context.MODE_PRIVATE)
            
            when (call.method) {
                "setLockedApps" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    prefs.edit().putString("locked_apps", apps.joinToString(",")).apply()
                    result.success(null)
                }
                "setLimitStatus" -> {
                    val isLimitReached = call.argument<Boolean>("isLimitReached") ?: false
                    prefs.edit().putBoolean("is_limit_reached", isLimitReached).apply()
                    result.success(null)
                }
                "getLimitStatus" -> {
                    val isLimitReached = prefs.getBoolean("is_limit_reached", false)
                    result.success(isLimitReached)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "openUsageStatsSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "checkUsageAccess" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
                    val granted = mode == AppOpsManager.MODE_ALLOWED
                    result.success(granted)
                }
                "checkAccessibilityAccess" -> {
                    val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
                    val enabledServices = am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC)
                    var isEnabled = false
                    for (service in enabledServices) {
                        if (service.resolveInfo.serviceInfo.packageName == packageName) {
                            isEnabled = true
                            break
                        }
                    }
                    result.success(isEnabled)
                }
                "getAppUsageToday" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(getAppUsage(packageName))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getAppUsage(packageName: String): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        
        val start = cal.timeInMillis
        val end = System.currentTimeMillis()
        
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
        var totalTime: Long = 0
        
        if (stats != null) {
            for (stat in stats) {
                if (stat.packageName == packageName) {
                    totalTime += stat.totalTimeInForeground // millis
                }
            }
        }
        return totalTime / 60000 // Convert to minutes
    }
}
