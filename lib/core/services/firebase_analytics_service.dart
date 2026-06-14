import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logExerciseCompleted({
    required String type,
    required String level,
    required String language,
    required int score,
  }) async {
    await _analytics.logEvent(
      name: 'exercise_completed',
      parameters: {'type': type, 'level': level, 'language': language, 'score': score},
    );
  }

  static Future<void> logJetonEarned({
    required int amount,
    required String source, // 'exercise' | 'rewarded_ad'
  }) async {
    await _analytics.logEvent(
      name: 'jeton_earned',
      parameters: {'amount': amount, 'source': source},
    );
  }

  static Future<void> logStreakUpdated() async {
    await _analytics.logEvent(name: 'streak_updated');
  }

  static Future<void> logLevelUnlocked(String level) async {
    await _analytics.logEvent(
      name: 'level_unlocked',
      parameters: {'level': level},
    );
  }
}
