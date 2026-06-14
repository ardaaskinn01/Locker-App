import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentenceChallenge {
  final List<String> originalWords;
  final String correctSentence;

  SentenceChallenge({
    required this.originalWords,
    required this.correctSentence,
  });

  factory SentenceChallenge.fromMap(Map<String, dynamic> map) {
    return SentenceChallenge(
      originalWords: List<String>.from(map['words'] ?? []),
      correctSentence: map['correct'] ?? '',
    );
  }
}

class SentenceBuilderState {
  final List<SentenceChallenge> challenges;
  final int currentIndex;
  final List<String> shuffledWords;
  final List<String> selectedWords;
  final bool? isCorrect;
  final int score;
  final bool isFinished;

  SentenceBuilderState({
    required this.challenges,
    this.currentIndex = 0,
    this.shuffledWords = const [],
    this.selectedWords = const [],
    this.isCorrect,
    this.score = 0,
    this.isFinished = false,
  });

  SentenceBuilderState copyWith({
    List<SentenceChallenge>? challenges,
    int? currentIndex,
    List<String>? shuffledWords,
    List<String>? selectedWords,
    bool? isCorrect,
    int? score,
    bool? isFinished,
  }) {
    return SentenceBuilderState(
      challenges: challenges ?? this.challenges,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffledWords: shuffledWords ?? this.shuffledWords,
      selectedWords: selectedWords ?? this.selectedWords,
      isCorrect: isCorrect,
      score: score ?? this.score,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class SentenceBuilderNotifier extends StateNotifier<SentenceBuilderState> {
  SentenceBuilderNotifier(List<SentenceChallenge> challenges) : super(SentenceBuilderState(challenges: challenges)) {
    _initChallenge();
  }

  void _initChallenge() {
    final current = state.challenges[state.currentIndex];
    final shuffled = List<String>.from(current.originalWords)..shuffle();
    state = state.copyWith(
      shuffledWords: shuffled,
      selectedWords: [],
      isCorrect: null,
    );
  }

  void selectWord(String word) {
    if (state.isCorrect != null) return;
    
    // Kelimeyi havuzdan çıkar, seçilenlere ekle
    final newShuffled = List<String>.from(state.shuffledWords);
    // Sadece ilk bulduğunu silmek önemli (aynı kelimeden birden fazla olabilir)
    newShuffled.remove(word);
    
    state = state.copyWith(
      selectedWords: [...state.selectedWords, word],
      shuffledWords: newShuffled,
    );
  }

  void deselectWord(String word) {
    if (state.isCorrect != null) return;

    final newSelected = List<String>.from(state.selectedWords);
    newSelected.remove(word);

    state = state.copyWith(
      selectedWords: newSelected,
      shuffledWords: [...state.shuffledWords, word],
    );
  }

  bool checkAnswer() {
    final current = state.challenges[state.currentIndex];
    final userSentence = state.selectedWords.join(' ');
    final isCorrect = userSentence == current.correctSentence;

    state = state.copyWith(
      isCorrect: isCorrect,
      score: isCorrect ? state.score + 1 : state.score,
    );

    return isCorrect;
  }

  void nextChallenge() {
    if (state.currentIndex < state.challenges.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      _initChallenge();
    } else {
      state = state.copyWith(isFinished: true);
    }
  }

  void resetChallenge() {
    _initChallenge();
  }
}

final sentenceBuilderProvider = StateNotifierProvider.family<SentenceBuilderNotifier, SentenceBuilderState, List<SentenceChallenge>>((ref, challenges) {
  return SentenceBuilderNotifier(challenges);
});
