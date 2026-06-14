import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_service.dart';
import '../../models/exercise_model.dart';
import '../home/home_providers.dart';

/// Belirli bir seviye için egzersiz listesini dinleyen sağlayıcı.
final exerciseListProvider = StreamProvider.family<List<ExerciseModel>, String>((ref, level) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final user = ref.watch(userProvider).value;
  
  if (user == null) return Stream.value([]);
  
  return firebaseService.getExercises(user.uid, user.targetLanguage, level);
});

/// Seviye bazlı ilerleme istatistiklerini hesaplayan sağlayıcı
final levelProgressProvider = StreamProvider.family<({int completed, int total, double percent}), String>((ref, level) {
  final user = ref.watch(userProvider).value;
  if (user == null) return Stream.value((completed: 0, total: 180, percent: 0.0));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('progress')
      .where('level', isEqualTo: level)
      .snapshots()
      .map((snap) {
        final completed = snap.docs.length;
        const total = 180; // Her seviye için 60x3=180 egzersiz
        return (
          completed: completed,
          total: total,
          percent: (completed / total).clamp(0.0, 1.0),
        );
      });
});
