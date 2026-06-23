import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_lock_service.dart';
import '../services/firebase_service.dart';

final usageSyncProvider = Provider<UsageSyncManager>((ref) {
  final manager = UsageSyncManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

class UsageSyncManager with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;
  DateTime? _backgroundTime;

  UsageSyncManager(this.ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  void startSync() {
    _timer?.cancel();
    // Run immediately then every 60 seconds
    _performSync();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _performSync();
    });
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isIOS) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _backgroundTime = DateTime.now();
      } else if (state == AppLifecycleState.resumed) {
        if (_backgroundTime != null) {
          final difference = DateTime.now().difference(_backgroundTime!).inMinutes;
          _backgroundTime = null;
          if (difference > 0) {
            _addBackgroundUsageToFirestore(difference);
          }
        }
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
