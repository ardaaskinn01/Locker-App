import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_analytics_service.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateStreak(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final int currentStreak = data['currentStreak'] ?? 0;
      final int longestStreak = data['longestStreak'] ?? 0;
      final Timestamp? lastActiveTsp = data['lastActiveDate'];

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      int newStreak = currentStreak;

      if (lastActiveTsp == null) {
        // First exercise ever
        newStreak = 1;
      } else {
        final DateTime lastActive = lastActiveTsp.toDate();
        final DateTime lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
        final int diff = today.difference(lastActiveDay).inDays;

        if (diff == 0) {
          // Already active today — no change
          return;
        } else if (diff == 1) {
          // Yesterday was active — continue streak
          newStreak = currentStreak + 1;
        } else {
          // Streak broken
          newStreak = 1;
        }
      }

      final int newLongest = newStreak > longestStreak ? newStreak : longestStreak;

      tx.update(docRef, {
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActiveDate': Timestamp.fromDate(today),
      });
    });

    // Log analytics
    await AnalyticsService.logStreakUpdated();
  }
}

final streakServiceProvider = Provider((ref) => StreakService());
