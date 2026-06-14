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

  // legacy method for backward compatibility if needed elsewhere
  static Future<void> seedDatabase() async {
    await seedDemoExercisesIfNeeded();
  }
}
