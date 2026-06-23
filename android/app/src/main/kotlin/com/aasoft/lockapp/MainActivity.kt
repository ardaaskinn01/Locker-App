package com.aasoft.lockapp

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Process
import android.provider.Settings
import android.util.Log
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
                    val appsStr = apps.joinToString(",")
                    prefs.edit().putString("locked_apps", appsStr).apply()
                    
                    try {
                        openFileOutput("locked_apps.txt", Context.MODE_PRIVATE).use {
                            it.write(appsStr.toByteArray())
                        }
                    } catch (e: Exception) {
                        Log.e("LockApp", "Failed to write locked_apps backup file: ${e.message}", e)
                    }
                    
                    result.success(null)
                }
                "setLimitStatus" -> {
                    val isLimitReached = call.argument<Boolean>("isLimitReached") ?: false
                    prefs.edit().putBoolean("is_limit_reached", isLimitReached).apply()
                    
                    try {
                        openFileOutput("is_limit_reached.txt", Context.MODE_PRIVATE).use {
                            it.write((if (isLimitReached) "1" else "0").toByteArray())
                        }
                    } catch (e: Exception) {
                        Log.e("LockApp", "Failed to write is_limit_reached backup file: ${e.message}", e)
                    }
                    
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
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = android.net.Uri.fromParts("package", packageName, null)
                    }
                    startActivity(intent)
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
                    val expectedService = "$packageName/$packageName.AppLockAccessibilityService"
                    val enabledServicesSetting = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    )
                    var isEnabled = false
                    if (enabledServicesSetting != null) {
                        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
                        colonSplitter.setString(enabledServicesSetting)
                        while (colonSplitter.hasNext()) {
                            val componentName = colonSplitter.next()
                            if (componentName.equals(expectedService, ignoreCase = true)) {
                                isEnabled = true
                                break
                            }
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
