import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/seed_data.dart';

class SeedService {
  static const String _demoSeedKey = 'demo_exercise_fixed_v3';

  /// Forced seed for demo purposes. Logs to console to help track status.
  static Future<void> seedDemoExercisesIfNeeded() async {
    print('DEBUG: SeedService.seedDemoExercisesIfNeeded starting...');
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Seed daily mini games first
      await seedDailyMiniGamesIfNeeded();

      // Force seed for each exercise type (5 examples each)
      final matching = SeedData.matchingTrack().take(5);
      final quizes = SeedData.quizTrack().take(5);
      final sentences = SeedData.sentenceTrack().take(5);

      final allDemoContents = [...matching, ...quizes, ...sentences];
      
      print('DEBUG: SeedService - Attempting to write ${allDemoContents.length} demo exercises to collection "exercises"...');

      final batch = firestore.batch();
      for (final ex in allDemoContents) {
        final docRef = firestore.collection('exercises').doc(ex.id);
        batch.set(docRef, ex.toMap(), SetOptions(merge: true));
      }
      
      await batch.commit();
      print('DEBUG: SeedService - SUCCESSFULLY UPLOADED DEMO DATA.');
    } catch (e) {
      print('DEBUG: SeedService ERROR during upload: $e');
    }
  }

  static Future<void> seedDailyMiniGamesIfNeeded() async {
    print('DEBUG: SeedService.seedDailyMiniGamesIfNeeded starting...');
    try {
      final firestore = FirebaseFirestore.instance;
      
      final game1 = {
        'id': 'daily_mini_game_1',
        'language': 'en',
        'level': 'A1',
        'questions': [
          {'word': 'cat', 'meaning': 'kedi', 'isCorrect': true},
          {'word': 'red', 'meaning': 'mavi', 'isCorrect': false},
          {'word': 'water', 'meaning': 'su', 'isCorrect': true},
          {'word': 'book', 'meaning': 'kitap', 'isCorrect': true},
          {'word': 'milk', 'meaning': 'kahve', 'isCorrect': false},
        ],
      };

      final game2 = {
        'id': 'daily_mini_game_2',
        'language': 'en',
        'level': 'A1',
        'questions': [
          {'word': 'dog', 'meaning': 'köpek', 'isCorrect': true},
          {'word': 'yellow', 'meaning': 'yeşil', 'isCorrect': false},
          {'word': 'apple', 'meaning': 'elma', 'isCorrect': true},
          {'word': 'school', 'meaning': 'okul', 'isCorrect': true},
          {'word': 'bread', 'meaning': 'peynir', 'isCorrect': false},
        ],
      };

      final game3 = {
        'id': 'daily_mini_game_3',
        'language': 'en',
        'level': 'A1',
        'questions': [
          {'word': 'bird', 'meaning': 'kuş', 'isCorrect': true},
          {'word': 'blue', 'meaning': 'kırmızı', 'isCorrect': false},
          {'word': 'orange', 'meaning': 'portakal', 'isCorrect': true},
          {'word': 'teacher', 'meaning': 'öğretmen', 'isCorrect': true},
          {'word': 'fish', 'meaning': 'balık', 'isCorrect': true},
        ],
      };

      final batch = firestore.batch();
      
      batch.set(firestore.collection('daily_mini_games').doc(game1['id'] as String), game1, SetOptions(merge: true));
      batch.set(firestore.collection('daily_mini_games').doc(game2['id'] as String), game2, SetOptions(merge: true));
      batch.set(firestore.collection('daily_mini_games').doc(game3['id'] as String), game3, SetOptions(merge: true));
      
      await batch.commit();
      print('DEBUG: SeedService - SUCCESSFULLY SEEDED DAILY MINI GAMES.');
    } catch (e) {
      print('DEBUG: SeedService ERROR during mini games seed: $e');
    }
  }

  // legacy method for backward compatibility if needed elsewhere
  static Future<void> seedDatabase() async {
    await seedDemoExercisesIfNeeded();
  }
}
