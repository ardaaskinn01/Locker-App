import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firebase_service.dart';
import '../../models/exercise_model.dart';
import '../home/home_providers.dart';
import '../../core/utils/seed_data.dart';

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

typedef TrackArg = ({String level, ExerciseType type});

/// Firebase egzersizleri ile yerel şablonları birleştirerek 60 elemanlık tüm parkuru oluşturan sağlayıcı.
final mergedExerciseTrackProvider = Provider.family<List<ExerciseModel>, TrackArg>((ref, arg) {
  final user = ref.watch(userProvider).value;
  if (user == null) return [];

  final firebaseExercises = ref.watch(exerciseListProvider(arg.level)).value ?? [];
  final lang = user.targetLanguage.isEmpty ? 'en' : user.targetLanguage;
  final level = arg.level;
  final type = arg.type;

  // Firebase egzersizlerini filtrele ve sırala
  final fromFirebase = firebaseExercises.where((e) => e.type == type).toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  // 60'lık yerel şablon listesini oluştur
  List<ExerciseModel> placeholders;
  switch (type) {
    case ExerciseType.matching:
      placeholders = SeedData.matchingTrack(language: lang, level: level);
      break;
    case ExerciseType.quiz:
      placeholders = SeedData.quizTrack(language: lang, level: level);
      break;
    case ExerciseType.sentenceBuilder:
      placeholders = SeedData.sentenceTrack(language: lang, level: level);
      break;
    default:
      placeholders = SeedData.matchingTrack(language: lang, level: level);
  }

  // Firebase verilerini yerel şablonların üzerine yaz (order değerine göre)
  final Map<int, ExerciseModel> byOrder = {for (var e in placeholders) e.order: e};
  for (final fb in fromFirebase) {
    byOrder[fb.order] = fb;
  }

  final merged = byOrder.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return merged.map((e) => e.value).toList();
});

