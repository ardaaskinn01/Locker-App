import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';
import 'streak_service.dart';
import 'firebase_analytics_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService(ref));

class FirebaseService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService(this._ref);

  Future<String?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw Exception('Auth Error: ${e.message}');
    }
  }

  Future<void> createUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'lastJetonReset': FieldValue.serverTimestamp(),
      'currentStreak': 0,
      'longestStreak': 0,
      'totalExercisesCompleted': 0,
      'totalJetonsEarned': 0,
    });
  }

  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await _firestore.collection('users').doc(uid).update({field: value});
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _firestore.collection('users').doc(uid).update(fields);
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Stream<List<ExerciseModel>> getExercises(String uid, String language, String level) {
    // Stream 1: global exercise definitions
    final exercisesStream = _firestore
        .collection('exercises')
        .where('language', isEqualTo: language)
        .where('level', isEqualTo: level)
        .orderBy('order', descending: false)
        .snapshots();

    // Stream 2: user-specific completion progress
    final progressStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .snapshots();

    // Manually combine: whenever either stream emits, re-merge
    Map<String, Map<String, dynamic>>? latestProgress;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? latestExercises;

    return Stream.multi((controller) {
      final subEx = exercisesStream.listen((snap) {
        latestExercises = snap.docs;
        if (latestProgress != null && latestExercises != null) {
          controller.add(_mergeExercises(latestExercises!, latestProgress!));
        }
      }, onError: controller.addError);

      final subProg = progressStream.listen((snap) {
        latestProgress = {for (var d in snap.docs) d.id: d.data()};
        if (latestExercises != null) {
          controller.add(_mergeExercises(latestExercises!, latestProgress!));
        }
      }, onError: controller.addError);

      controller.onCancel = () {
        subEx.cancel();
        subProg.cancel();
      };
    });
  }

  List<ExerciseModel> _mergeExercises(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> exerciseDocs,
    Map<String, Map<String, dynamic>> progressMap,
  ) {
    return exerciseDocs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (progressMap.containsKey(doc.id)) {
        data['progress'] = progressMap[doc.id];
      }
      return ExerciseModel.fromFirestore(doc, data: data);
    }).toList();
  }

  Future<void> awardJetons(String uid, int amount, {String source = 'exercise'}) async {
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      
      final int current = snap.data()?['jetons'] ?? 0;
      final int total = snap.data()?['totalJetonsEarned'] ?? 0;
      final int dailyExerciseCount = snap.data()?['dailyExerciseCount'] ?? 0;

      if (source == 'exercise' && dailyExerciseCount >= 6) {
        throw Exception('Günlük egzersiz limitin doldu (6/6). Yarın devam et!');
      }

      int newAmount = current + amount;
      if (newAmount < 0) newAmount = 0; // Guard for negative tokens

      tx.update(docRef, {
        'jetons': newAmount,
        'totalJetonsEarned': total + amount,
      });
    });
    await AnalyticsService.logJetonEarned(amount: amount, source: source);
  }

  /// Combined method to award jetons and complete exercise in ONE transaction
  Future<bool> completeExercise(
    String uid,
    String exerciseId, {
    required String type,
    required String level,
    required String language,
    required int score,
    int jetonReward = 100,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    bool levelUnlocked = false;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;

      // 1. Check daily exercise limit for jetons
      final int dailyExerciseCount = data['dailyExerciseCount'] ?? 0;
      bool canEarnJetons = dailyExerciseCount < 6;

      // 2. User Stats
      final int totalCompleted = (data['totalExercisesCompleted'] ?? 0) + 1;
      final int dailyCount = dailyExerciseCount + 1;
      final List<String> unlockedLevels = List<String>.from(data['unlockedLevels'] ?? []);

      // 3. Jeton Update
      if (canEarnJetons) {
        final int currentJetons = data['jetons'] ?? 0;
        final int totalJetons = data['totalJetonsEarned'] ?? 0;
        tx.update(docRef, {
          'jetons': currentJetons + jetonReward,
          'totalJetonsEarned': totalJetons + jetonReward,
        });
      }

      // 4. Level-up check (simplified: every 3 unique exercises for demo)
      final Map<String, String?> nextLevelMap = {'A1': 'A2', 'A2': 'B1'};
      final String? nextLevel = nextLevelMap[level];
      if (nextLevel != null && !unlockedLevels.contains(nextLevel) && totalCompleted % 3 == 0) {
        unlockedLevels.add(nextLevel);
        levelUnlocked = true;
      }

      tx.update(docRef, {
        'totalExercisesCompleted': totalCompleted,
        'dailyExerciseCount': dailyCount,
        'unlockedLevels': unlockedLevels,
      });

      // 5. Save specific exercise progress
      final progressRef = _firestore.collection('users').doc(uid).collection('progress').doc(exerciseId);
      tx.set(progressRef, {
        'completedAt': FieldValue.serverTimestamp(),
        'score': score,
        'jetonEarned': canEarnJetons ? jetonReward : 0,
        'level': level,
        'language': language,
        'type': type,
      });
    });

    await _ref.read(streakServiceProvider).updateStreak(uid);
    await AnalyticsService.logExerciseCompleted(type: type, level: level, language: language, score: score);
    if (levelUnlocked) await AnalyticsService.logLevelUnlocked(level);

    return levelUnlocked;
  }

  Future<void> buyBonusTime(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      
      final data = snap.data()!;
      final int currentJetons = data['jetons'] ?? 0;
      final int bonus = data['bonusMinutes'] ?? 0;

      if (currentJetons < 100) {
        throw Exception('Yetersiz jeton! 5 dakika için 100 jeton gerekiyor.');
      }

      tx.update(docRef, {
        'jetons': currentJetons - 100,
        'bonusMinutes': bonus + 5,
      });
    });
    // Log spending if possible (optional based on analytics service)
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
