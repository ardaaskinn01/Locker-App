import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_lock_service.dart';
import '../services/firebase_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

final usageSyncProvider = Provider<UsageSyncManager>((ref) {
  final manager = UsageSyncManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

class UsageSyncManager with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;

  UsageSyncManager(this.ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  void startSync() async {
    _timer?.cancel();
    await _checkAndSyncBackgroundTime();
    _performSync();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _performSync();
    });
  }

  Future<void> _checkAndSyncBackgroundTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeMs = prefs.getInt('background_start_time');
      if (startTimeMs != null) {
        await prefs.remove('background_start_time');
        final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        final durationSeconds = DateTime.now().difference(startTime).inSeconds;
        if (durationSeconds > 0) {
          final testMode = prefs.getBool('test_mode_enabled') ?? false;
          int usageMinutes = 0;
          if (testMode) {
            // Test mode: 10 seconds spent outside = 1 minute of usage
            usageMinutes = (durationSeconds / 10).ceil();
          } else {
            usageMinutes = (durationSeconds / 60).floor();
          }
          if (usageMinutes > 0) {
            await _addBackgroundUsageToFirestore(usageMinutes);
          }
        }
      }
    } catch (e) {
      print('Error checking background time on launch: $e');
    }
  }

  Future<void> _performSync() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid != null) {
      await appLockServiceProvider.syncLockedApps(uid);
      await appLockServiceProvider.syncLimitStatus(uid);
    }
  }

  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
          await prefs.setInt('background_start_time', DateTime.now().millisecondsSinceEpoch);
        } else if (state == AppLifecycleState.resumed) {
          final startTimeMs = prefs.getInt('background_start_time');
          if (startTimeMs != null) {
            await prefs.remove('background_start_time');
            final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
            final durationSeconds = DateTime.now().difference(startTime).inSeconds;
            if (durationSeconds > 0) {
              final testMode = prefs.getBool('test_mode_enabled') ?? false;
              int usageMinutes = 0;
              if (testMode) {
                // Test mode: 10 seconds spent outside = 1 minute of usage
                usageMinutes = (durationSeconds / 10).ceil();
              } else {
                usageMinutes = (durationSeconds / 60).floor();
              }
              if (usageMinutes > 0) {
                await _addBackgroundUsageToFirestore(usageMinutes);
              }
            }
          }
        }
      } catch (e) {
        print('Error handling lifecycle background time: $e');
      }
    }
  }

  Future<void> _addBackgroundUsageToFirestore(int minutes) async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final currentUsage = doc.data()?['todaysTotalUsageMinutes'] ?? 0;
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'todaysTotalUsageMinutes': currentUsage + minutes,
          });
          // Immediately sync iOS native shield state after updating duration
          await appLockServiceProvider.syncLimitStatus(uid);
        }
      } catch (e) {
        print('Failed to sync background usage: $e');
      }
    }
  }
}
