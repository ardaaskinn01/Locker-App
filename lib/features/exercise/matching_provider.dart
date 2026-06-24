import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchingItem {
  final String uniqueId; // Unique for each card (0-11)
  final String pairId;   // Same for both cards in a pair
  final String text;
  final bool isTarget; 
  bool isMatched;
  bool isFlipped;
  bool isError;

  MatchingItem({
    required this.uniqueId,
    required this.pairId,
    required this.text,
    required this.isTarget,
    this.isMatched = false,
    this.isFlipped = false,
    this.isError = false,
  });

  MatchingItem copyWith({bool? isMatched, bool? isFlipped, bool? isError}) {
    return MatchingItem(
      uniqueId: uniqueId,
      pairId: pairId,
      text: text,
      isTarget: isTarget,
      isMatched: isMatched ?? this.isMatched,
      isFlipped: isFlipped ?? this.isFlipped,
      isError: isError ?? this.isError,
    );
  }
}

class MatchingState {
  final List<MatchingItem> items;
  final int matchesFound;
  final bool isFinished;
  final int totalPairs;
  final bool isBusy; // Prevent clicking while cards are flipping back

  MatchingState({
    required this.items,
    this.matchesFound = 0,
    this.isFinished = false,
    required this.totalPairs,
    this.isBusy = false,
  });

  MatchingState copyWith({
    List<MatchingItem>? items,
    int? matchesFound,
    bool? isFinished,
    bool? isBusy,
  }) {
    return MatchingState(
      items: items ?? this.items,
      matchesFound: matchesFound ?? this.matchesFound,
      isFinished: isFinished ?? this.isFinished,
      totalPairs: totalPairs,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

final matchingProvider = StateNotifierProvider.family<MatchingNotifier, MatchingState, List<Map<String, String>>>((ref, pairs) {
  return MatchingNotifier(pairs);
});

class MatchingNotifier extends StateNotifier<MatchingState> {
  MatchingNotifier(List<Map<String, String>> pairs) : super(_initialState(pairs));

  static MatchingState _initialState(List<Map<String, String>> pairs) {
    List<MatchingItem> items = [];
    for (int i = 0; i < pairs.length; i++) {
       final pair = pairs[i];
       final pairId = 'pair_$i';
       // Explicitly read 'word' (target) and 'translation' (native) keys
       final targetText = pair['word'] ?? pair.entries.first.value;
       final nativeText = pair['translation'] ?? pair.entries.last.value;
       
       items.add(MatchingItem(uniqueId: '${pairId}_t', pairId: pairId, text: targetText, isTarget: true));
       items.add(MatchingItem(uniqueId: '${pairId}_n', pairId: pairId, text: nativeText, isTarget: false));
    }
    items.shuffle();
    return MatchingState(items: items, totalPairs: pairs.length);
  }

  void flipCard(MatchingItem item) {
    if (state.isBusy || item.isMatched || item.isFlipped || state.isFinished) return;

    final flippedItems = state.items.where((i) => i.isFlipped && !i.isMatched).toList();
    
    // Flip the clicked card
    final newItems = state.items.map((i) => i.uniqueId == item.uniqueId ? i.copyWith(isFlipped: true) : i).toList();
    state = state.copyWith(items: newItems);

    if (flippedItems.length == 1) {
      // Second card flipped, check match
      final firstItem = flippedItems.first;
      state = state.copyWith(isBusy: true);

      if (firstItem.pairId == item.pairId) {
        // MATCH!
        final matches = state.matchesFound + 1;
        final isLast = matches == state.totalPairs;
        
        state = state.copyWith(
          matchesFound: matches,
          items: state.items.map((i) {
            if (i.pairId == item.pairId) return i.copyWith(isMatched: true, isFlipped: true);
            return i;
          }).toList(),
          isBusy: true,
        );

        if (isLast) {
          Timer(const Duration(milliseconds: 800), () {
            state = state.copyWith(isFinished: true, isBusy: false);
          });
        } else {
          state = state.copyWith(isBusy: false);
        }
      } else {
        // FAIL!
        // Show error color then flip back after 1 second
        state = state.copyWith(
          items: state.items.map((i) {
            if (i.uniqueId == firstItem.uniqueId || i.uniqueId == item.uniqueId) {
              return i.copyWith(isError: true);
            }
            return i;
          }).toList(),
        );

        Timer(const Duration(milliseconds: 1000), () {
          state = state.copyWith(
            isBusy: false,
            items: state.items.map((i) {
              if (i.uniqueId == firstItem.uniqueId || i.uniqueId == item.uniqueId) {
                return i.copyWith(isFlipped: false, isError: false);
              }
              return i;
            }).toList(),
          );
        });
      }
    }
  }
}