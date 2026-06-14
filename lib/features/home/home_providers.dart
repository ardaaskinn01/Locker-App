import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';

/// Firestore'daki kullanıcı belgesini gerçek zamanlı (Stream) takip eden sağlayıcı.
/// FirebaseAuth oturumu yoksa otomatik anonim giriş yapılır.
final userProvider = StreamProvider<UserModel?>((ref) async* {
  final firebaseService = ref.watch(firebaseServiceProvider);
  String? uid = firebaseService.currentUserId;

  if (uid == null) {
    // FirebaseAuth oturumu yoksa yeniden anonim giriş yap
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboardingCompleted') ?? false;
    if (!onboarded) {
      yield null;
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      uid = cred.user?.uid;
    } catch (_) {
      yield null;
      return;
    }
  }

  if (uid == null) {
    yield null;
    return;
  }

  yield* firebaseService.getUserStream(uid);
});

/// Sadece jeton miktarını takip etmek için özelleşmiş sağlayıcı.
final jetonProvider = Provider<int>((ref) {
  return ref.watch(userProvider).maybeWhen(
    data: (user) => user?.jetons ?? 0,
    orElse: () => 0,
  );
});

/// Bugün harcanan toplam süreyi Firestore'daki gerçek değerden okuyan sağlayıcı.
final usageMinutesProvider = Provider<int>((ref) {
  return ref.watch(userProvider).maybeWhen(
    data: (user) {
      if (user == null) return 0;
      return user.todaysTotalUsageMinutes;
    },
    orElse: () => 0,
  );
});
