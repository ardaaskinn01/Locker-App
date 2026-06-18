import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart';

class JetonResetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks if the user needs a daily reset and performs it if necessary.
  Future<void> checkAndReset(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final int resetHour = data['resetHour'] ?? 4;
      final int? pendingResetHour = data['pendingResetHour'];
      final Timestamp lastReset = data['lastJetonReset'] ?? Timestamp.fromMillisecondsSinceEpoch(0);

      if (AppDateUtils.isResetDue(lastReset, resetHour)) {
        final WriteBatch batch = _firestore.batch();
        final docRef = _firestore.collection('users').doc(uid);

        // Perform Reset
        final Map<String, dynamic> updates = {
          'dailyExerciseCount': 0,
          'dailyRewardedAdCount': 0,
          'bonusMinutes': 0,
          'lastJetonReset': FieldValue.serverTimestamp(),
        };

        // If there's a pending hour change, apply it now during the reset cycle
        if (pendingResetHour != null) {
          updates['resetHour'] = pendingResetHour;
          updates['pendingResetHour'] = FieldValue.delete();
        }

        // Eşleşen günlük meydan okuma varsa değerlendir
        final activeChallenge = data['activeChallenge'] as Map<dynamic, dynamic>?;
        if (activeChallenge != null) {
          final int betAmount = activeChallenge['betAmount'] ?? 0;
          final bool exceededLimit = activeChallenge['exceededLimit'] ?? false;
          final bool wasSuccess = !exceededLimit;

          updates['lastChallengeResult'] = {
            'betAmount': betAmount,
            'wasSuccess': wasSuccess,
            'claimed': false,
          };
          updates['activeChallenge'] = FieldValue.delete();
        }

        batch.update(docRef, updates);
        await batch.commit();
        print('JetonResetService: Reset completed for $uid');
      }
    } catch (e) {
      print('JetonResetService Error: $e');
    }
  }

  /// Updates the reset hour. If it's different from the current one,
  /// it's scheduled as "pending" to prevent immediate multi-reset cheats.
  Future<void> updateResetHour(String uid, int newHour) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final currentResetHour = userDoc.data()?['resetHour'] ?? 4;

      if (currentResetHour == newHour) {
        await _firestore.collection('users').doc(uid).update({
          'resetHour': newHour,
          'pendingResetHour': FieldValue.delete(),
        });
      } else {
        // Schedule for next reset cycle
        await _firestore.collection('users').doc(uid).update({
          'pendingResetHour': newHour,
        });
      }
    } catch (e) {
      print('JetonResetService updateResetHour Error: $e');
    }
  }
}

final jetonResetServiceProvider = JetonResetService();
