import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise_model.dart';

class QuizQuestion {
  final String sentence;
  final String blank;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.sentence,
    required this.blank,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      sentence: map['sentence'] ?? '',
      blank: map['blank'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }
}

class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int selectedOption; // -1 for none
  final bool isAnswered;
  final int correctCount;
  final int wrongCount;
  final bool isFinished;

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedOption = -1,
    this.isAnswered = false,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isFinished = false,
  });

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? selectedOption,
    bool? isAnswered,
    int? correctCount,
    int? wrongCount,
    bool? isFinished,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: selectedOption ?? this.selectedOption,
      isAnswered: isAnswered ?? this.isAnswered,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(List<QuizQuestion> questions) : super(QuizState(questions: questions));

  void selectOption(int index) {
    if (state.isAnswered) return;
    state = state.copyWith(selectedOption: index);
  }

  bool checkAnswer() {
    if (state.selectedOption == -1 || state.isAnswered) return false;

    final isCorrect = state.selectedOption == state.questions[state.currentIndex].correctIndex;
    
    state = state.copyWith(
      isAnswered: true,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      wrongCount: !isCorrect ? state.wrongCount + 1 : state.wrongCount,
    );

    return isCorrect;
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedOption: -1,
        isAnswered: false,
      );
    } else {
      state = state.copyWith(isFinished: true);
    }
  }
}

final quizProvider = StateNotifierProvider.family<QuizNotifier, QuizState, List<QuizQuestion>>((ref, questions) {
  return QuizNotifier(questions);
});
