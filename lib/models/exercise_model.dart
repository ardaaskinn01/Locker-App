import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType { flashcard, quiz, sentenceBuilder, matching }

class UserExerciseProgress {
  final DateTime completedAt;
  final int score;
  final int jetonEarned;

  UserExerciseProgress({
    required this.completedAt,
    required this.score,
    required this.jetonEarned,
  });

  Map<String, dynamic> toMap() => {
    'completedAt': Timestamp.fromDate(completedAt),
    'score': score,
    'jetonEarned': jetonEarned,
  };

  factory UserExerciseProgress.fromMap(Map<String, dynamic> map) {
    return UserExerciseProgress(
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      score: map['score'] ?? 0,
      jetonEarned: map['jetonEarned'] ?? 0,
    );
  }
}

class ExerciseModel {
  final String id;
  final String language;
  final String level;
  final ExerciseType type;
  final int order;
  final String title;
  final Map<String, dynamic> content;
  final UserExerciseProgress? progress;

  ExerciseModel({
    required this.id,
    required this.language,
    required this.level,
    required this.type,
    required this.order,
    required this.title,
    required this.content,
    this.progress,
  });

  bool get isCompleted => progress != null;

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'level': level,
      'type': type.name,
      'order': order,
      'title': title,
      'content': content,
    };
  }

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc, {Map<String, dynamic>? data}) {
    final actualData = data ?? (doc.data() as Map<String, dynamic>);
    return ExerciseModel(
      id: doc.id,
      language: actualData['language'] ?? '',
      level: actualData['level'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.name == (actualData['type'] == 'sentence' ? 'sentenceBuilder' : actualData['type']),
        orElse: () => ExerciseType.flashcard,
      ),
      order: actualData['order'] ?? 0,
      title: actualData['title'] ?? '',
      content: actualData['content'] ?? {},
      progress: actualData['progress'] != null 
          ? UserExerciseProgress.fromMap(actualData['progress']) 
          : null,
    );
  }
}
