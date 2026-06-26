import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppLockService {
  static const MethodChannel _lockChannel = MethodChannel('com.lockapp/lock');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> checkUsageAccess() async {
    return await _lockChannel.invokeMethod('checkUsageAccess');
  }

  static Future<bool> checkAccessibilityAccess() async {
    return await _lockChannel.invokeMethod('checkAccessibilityAccess');
  }

  static Future<void> openAccessibilitySettings() async {
    await _lockChannel.invokeMethod('openAccessibilitySettings');
  }

  Future<bool> requestUsageStatsPermission() async {
    if (Platform.isAndroid) {
      try {
        final bool granted = await _lockChannel.invokeMethod('checkUsageAccess');
        if (granted) return true;
        
        await _lockChannel.invokeMethod('openUsageStatsSettings');
        return false;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> requestAccessibilityPermission() async {
    if (Platform.isAndroid) {
      try {
        await _lockChannel.invokeMethod('openAccessibilitySettings');
        return false; // Can't easily check access natively without service running
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> openAppSettings() async {
    try {
      await _lockChannel.invokeMethod('openAppSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      try {
        // Use native UNUserNotificationCenter for reliable iOS permission request
        final bool granted = await _lockChannel.invokeMethod('requestNotificationPermission');
        return granted;
      } catch (e) {
        // Fallback to permission_handler if native channel fails
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> checkNotificationPermission() async {
    if (Platform.isIOS) {
      try {
        final bool granted = await _lockChannel.invokeMethod('checkNotificationPermission');
        return granted;
      } catch (e) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
    }
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestScreenTimePermission() async {
    if (Platform.isIOS) {
      try {
        final bool granted = await _lockChannel.invokeMethod('requestScreenTimePermission');
        return granted;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> checkBackgroundRefreshAccess() async {
    if (Platform.isIOS) {
      try {
        final bool granted = await _lockChannel.invokeMethod('checkBackgroundRefreshAccess');
        return granted;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<int> selectAppsIOS() async {
    if (Platform.isIOS) {
      try {
        final int count = await _lockChannel.invokeMethod('selectAppsIOS');
        return count;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  static Future<int> getBackgroundTimeSpent({bool isBackgroundTask = false}) async {
    if (Platform.isIOS) {
      try {
        final int seconds = await _lockChannel.invokeMethod(
          'getBackgroundTimeSpent',
          {'isBackgroundTask': isBackgroundTask},
        );
        return seconds;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Syncs locked apps from Firestore to Native SharedPreferences
  Future<void> syncLockedApps(String uid) async {
    if (!Platform.isAndroid) return;
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;
      
      final List<dynamic> appsDynamic = doc.data()?['selectedApps'] ?? [];
      final List<String> apps = appsDynamic.map((e) => _getRealPackageName(e.toString())).toList();
      
      await _lockChannel.invokeMethod('setLockedApps', {'packages': apps});
    } catch (e) {
      print('SyncLockedApps error: $e');
    }
  }

  /// Evaluates usage limit and updates Native SharedPreferences/Shields
  Future<void> syncLimitStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final double dailyLimitHours = (data['dailyLimit'] ?? 0.0) * 1.0;
      final int dailyLimitMinutes = (dailyLimitHours * 60).round();
      final List<dynamic> appsDynamic = data['selectedApps'] ?? [];
      
      if (dailyLimitMinutes <= 0 || appsDynamic.isEmpty) return;

      int totalUsage = 0;
      final Map<String, dynamic> appUsageMap = {};
      
      // Bonus minutes added to base limit
      final int bonusMinutes = data['bonusMinutes'] ?? 0;
      final int totalAllowedMinutes = dailyLimitMinutes + bonusMinutes;

      if (Platform.isAndroid) {
        // Calculate total usage of selected apps
        for (var app in appsDynamic) {
          final String packageName = app.toString();
          final realPackage = _getRealPackageName(packageName);
          if (realPackage.isNotEmpty) {
            final int usage = await _lockChannel.invokeMethod('getAppUsageToday', {'packageName': realPackage});
            totalUsage += usage;
            appUsageMap[packageName] = usage;
          }
        }
      } else if (Platform.isIOS) {
        totalUsage = data['todaysTotalUsageMinutes'] ?? 0;
      }

      final bool isLimitReached = totalUsage >= totalAllowedMinutes;
      await _lockChannel.invokeMethod('setLimitStatus', {
        'isLimitReached': isLimitReached,
        'totalAllowedMinutes': totalAllowedMinutes,
        'todaysTotalUsageMinutes': totalUsage,
      });

      if (Platform.isAndroid) {
        final Map<String, dynamic> updates = {
          'todaysUsageDetails': appUsageMap,
          'todaysTotalUsageMinutes': totalUsage,
        };

        if (isLimitReached && data['activeChallenge'] != null) {
          updates['activeChallenge.exceededLimit'] = true;
        }

        // Update Firestore with the current usage report
        await _firestore.collection('users').doc(uid).update(updates);
      } else if (Platform.isIOS) {
        if (isLimitReached && data['activeChallenge'] != null) {
          await _firestore.collection('users').doc(uid).update({
            'activeChallenge.exceededLimit': true,
          });
        }
      }

    } catch (e) {
      print('SyncLimitStatus error: $e');
    }
  }

  String _getRealPackageName(String knownName) {
    switch (knownName.toLowerCase()) {
      case 'instagram': return 'com.instagram.android';
      case 'tiktok': return 'com.zhiliaoapp.musically';
      case 'twitter/x': return 'com.twitter.android';
      case 'youtube': return 'com.google.android.youtube';
      case 'facebook': return 'com.facebook.katana';
      case 'snapchat': return 'com.snapchat.android';
      case 'pinterest': return 'com.pinterest';
      default: return knownName;
    }
  }
}

final appLockServiceProvider = AppLockService();
