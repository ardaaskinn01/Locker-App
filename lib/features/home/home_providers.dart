import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';

/// Firestore'daki kullanıcı belgesini gerçek zamanlı (Stream) takip eden sağlayıcı.
/// FirebaseAuth oturumu yoksa otomatik anonim giriş yapılır.
final userProvider = StreamProvider<UserModel?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);

  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) {
      // If no user is logged in, try to sign in anonymously if onboarding is completed
      return Stream.fromFuture(SharedPreferences.getInstance().then((prefs) async {
        final onboarded = prefs.getBool('onboardingCompleted') ?? false;
        if (onboarded) {
          try {
            final cred = await FirebaseAuth.instance.signInAnonymously();
            if (cred.user != null) {
              // This sign in will trigger authStateChanges again and return the correct stream
              return const Stream<UserModel?>.empty();
            }
          } catch (_) {}
        }
        return Stream<UserModel?>.value(null);
      })).asyncExpand((s) => s);
    }
    
    // User is logged in, yield the user document stream
    return firebaseService.getUserStream(user.uid);
  });
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
