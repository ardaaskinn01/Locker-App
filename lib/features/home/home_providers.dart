import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';

/// Firestore'daki kullanıcı belgesini gerçek zamanlı (Stream) takip eden sağlayıcı.
final userProvider = StreamProvider<UserModel?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final uid = firebaseService.currentUserId;
  
  if (uid == null) return Stream.value(null);
  return firebaseService.getUserStream(uid);
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
