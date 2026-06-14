import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_lock_service.dart';
import '../services/firebase_service.dart';

final usageSyncProvider = Provider<UsageSyncManager>((ref) {
  return UsageSyncManager(ref);
});

class UsageSyncManager {
  final Ref ref;
  Timer? _timer;

  UsageSyncManager(this.ref);

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
      print('DEBUG: Foreground Sync Triggered for $uid');
      await appLockServiceProvider.syncLimitStatus(uid);
    }
  }

  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }
}
