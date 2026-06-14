import '../../models/exercise_model.dart';

class SeedData {
  static List<ExerciseModel> seedEnglishA1Exercises() {
    return [..._matchingExercises(), ..._quizExercises(), ..._sentenceExercises()];
  }

  /// 60 matching exercises for the Matching track (demo: first 5 filled, rest placeholder)
  static List<ExerciseModel> matchingTrack({String language = 'en', String level = 'A1'}) {
    final filled = _matchingExercises(language: language, level: level);
    final placeholders = List.generate(55, (i) => ExerciseModel(
      id: '${language}_${level}_matching_${i + 6}',
      language: language,
      level: level,
      type: ExerciseType.matching,
      order: i + 6,
      title: 'Eşleştirme ${i + 6}',
      content: {},
    ));
    return [...filled, ...placeholders];
  }

  /// 60 quiz exercises for the Quiz track
  static List<ExerciseModel> quizTrack({String language = 'en', String level = 'A1'}) {
    final filled = _quizExercises(language: language, level: level);
    final placeholders = List.generate(55, (i) => ExerciseModel(
      id: '${language}_${level}_quiz_${i + 6}',
      language: language,
      level: level,
      type: ExerciseType.quiz,
      order: i + 6,
      title: 'Quiz ${i + 6}',
      content: {},
    ));
    return [...filled, ...placeholders];
  }

  /// 60 sentence builder exercises for the Sentence track
  static List<ExerciseModel> sentenceTrack({String language = 'en', String level = 'A1'}) {
    final filled = _sentenceExercises(language: language, level: level);
    final placeholders = List.generate(55, (i) => ExerciseModel(
      id: '${language}_${level}_sentence_${i + 6}',
      language: language,
      level: level,
      type: ExerciseType.sentenceBuilder,
      order: i + 6,
      title: 'Cümle ${i + 6}',
      content: {},
    ));
    return [...filled, ...placeholders];
  }

  static List<ExerciseModel> _matchingExercises({String language = 'en', String level = 'A1'}) {
    return [
      ExerciseModel(
        id: 'demo_matching_1',
        language: language,
        level: level,
        order: 1,
        type: ExerciseType.matching,
        title: 'Hayvanlar',
        content: {
          'pairs': [
            {'word': 'cat', 'translation': 'kedi'},
            {'word': 'dog', 'translation': 'köpek'},
            {'word': 'bird', 'translation': 'kuş'},
            {'word': 'fish', 'translation': 'balık'},
            {'word': 'lion', 'translation': 'aslan'},
            {'word': 'horse', 'translation': 'at'},
          ]
        },
      ),
      ExerciseModel(
        id: 'demo_matching_2',
        language: language,
        level: level,
        order: 2,
        type: ExerciseType.matching,
        title: 'Renkler',
        content: {
          'pairs': [
            {'word': 'red', 'translation': 'kırmızı'},
            {'word': 'blue', 'translation': 'mavi'},
            {'word': 'green', 'translation': 'yeşil'},
            {'word': 'yellow', 'translation': 'sarı'},
            {'word': 'black', 'translation': 'siyah'},
            {'word': 'white', 'translation': 'beyaz'},
          ]
        },
      ),
      ExerciseModel(
        id: 'demo_matching_3',
        language: language,
        level: level,
        order: 3,
        type: ExerciseType.matching,
        title: 'Sayılar',
        content: {
          'pairs': [
            {'word': 'one', 'translation': 'bir'},
            {'word': 'two', 'translation': 'iki'},
            {'word': 'three', 'translation': 'üç'},
            {'word': 'four', 'translation': 'dört'},
            {'word': 'five', 'translation': 'beş'},
            {'word': 'six', 'translation': 'altı'},
          ]
        },
      ),
      ExerciseModel(
        id: 'demo_matching_4',
        language: language,
        level: level,
        order: 4,
        type: ExerciseType.matching,
        title: 'Meyveler',
        content: {
          'pairs': [
            {'word': 'apple', 'translation': 'elma'},
            {'word': 'banana', 'translation': 'muz'},
            {'word': 'orange', 'translation': 'portakal'},
            {'word': 'grape', 'translation': 'üzüm'},
            {'word': 'pear', 'translation': 'armut'},
            {'word': 'strawberry', 'translation': 'çilek'},
          ]
        },
      ),
      ExerciseModel(
        id: 'demo_matching_5',
        language: language,
        level: level,
        order: 5,
        type: ExerciseType.matching,
        title: 'Vücut',
        content: {
          'pairs': [
            {'word': 'hand', 'translation': 'el'},
            {'word': 'eye', 'translation': 'göz'},
            {'word': 'nose', 'translation': 'burun'},
            {'word': 'ear', 'translation': 'kulak'},
            {'word': 'foot', 'translation': 'ayak'},
            {'word': 'mouth', 'translation': 'ağız'},
          ]
        },
      ),
    ];
  }

  static List<ExerciseModel> _quizExercises({String language = 'en', String level = 'A1'}) {
    return [
      ExerciseModel(
        id: '${language}_${level}_quiz_1',
        language: language,
        level: level,
        order: 1,
        type: ExerciseType.quiz,
        title: 'Am / Is / Are',
        content: {
          'questions': [
            {'sentence': 'I ___ a student.', 'blank': 'am', 'options': ['am', 'is', 'are'], 'correctIndex': 0},
            {'sentence': 'She ___ my friend.', 'blank': 'is', 'options': ['am', 'is', 'are'], 'correctIndex': 1},
            {'sentence': 'They ___ happy.', 'blank': 'are', 'options': ['am', 'is', 'are'], 'correctIndex': 2},
            {'sentence': 'We ___ from Turkey.', 'blank': 'are', 'options': ['am', 'is', 'are'], 'correctIndex': 2},
            {'sentence': 'He ___ a doctor.', 'blank': 'is', 'options': ['is', 'am', 'are'], 'correctIndex': 0},
          ]
        },
      ),
      ExerciseModel(
        id: '${language}_${level}_quiz_2',
        language: language,
        level: level,
        order: 2,
        type: ExerciseType.quiz,
        title: 'Have / Has',
        content: {
          'questions': [
            {'sentence': 'I ___ a book.', 'blank': 'have', 'options': ['have', 'has', 'had'], 'correctIndex': 0},
            {'sentence': 'She ___ a cat.', 'blank': 'has', 'options': ['have', 'has', 'had'], 'correctIndex': 1},
          ]
        },
      ),
      ExerciseModel(
        id: '${language}_${level}_quiz_3',
        language: language,
        level: level,
        order: 3,
        type: ExerciseType.quiz,
        title: 'Do / Does',
        content: {},
      ),
      ExerciseModel(
        id: '${language}_${level}_quiz_4',
        language: language,
        level: level,
        order: 4,
        type: ExerciseType.quiz,
        title: 'Zamanlar - Present',
        content: {},
      ),
      ExerciseModel(
        id: '${language}_${level}_quiz_5',
        language: language,
        level: level,
        order: 5,
        type: ExerciseType.quiz,
        title: 'Soru Kelimeleri',
        content: {},
      ),
    ];
  }

  static List<ExerciseModel> _sentenceExercises({String language = 'en', String level = 'A1'}) {
    return [
      ExerciseModel(
        id: '${language}_${level}_sentence_1',
        language: language,
        level: level,
        order: 1,
        type: ExerciseType.sentenceBuilder,
        title: 'Tanışma Cümleleri',
        content: {
          'sentences': [
            {'words': ['I', 'am', 'a', 'student'], 'correct': 'I am a student'},
            {'words': ['She', 'is', 'my', 'friend'], 'correct': 'She is my friend'},
            {'words': ['We', 'are', 'from', 'Turkey'], 'correct': 'We are from Turkey'},
          ]
        },
      ),
      ExerciseModel(
        id: '${language}_${level}_sentence_2',
        language: language,
        level: level,
        order: 2,
        type: ExerciseType.sentenceBuilder,
        title: 'Günlük Cümleler',
        content: {
          'sentences': [
            {'words': ['I', 'like', 'cats', 'very', 'much'], 'correct': 'I like cats very much'},
            {'words': ['She', 'is', 'a', 'good', 'student'], 'correct': 'She is a good student'},
          ]
        },
      ),
      ExerciseModel(
        id: '${language}_${level}_sentence_3',
        language: language,
        level: level,
        order: 3,
        type: ExerciseType.sentenceBuilder,
        title: 'Ev ve Aile',
        content: {},
      ),
      ExerciseModel(
        id: '${language}_${level}_sentence_4',
        language: language,
        level: level,
        order: 4,
        type: ExerciseType.sentenceBuilder,
        title: 'Alışveriş',
        content: {},
      ),
      ExerciseModel(
        id: '${language}_${level}_sentence_5',
        language: language,
        level: level,
        order: 5,
        type: ExerciseType.sentenceBuilder,
        title: 'Seyahat',
        content: {},
      ),
    ];
  }
}
