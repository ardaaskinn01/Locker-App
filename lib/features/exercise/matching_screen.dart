import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/exercise_model.dart';
import 'matching_provider.dart';
import '../path/path_providers.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  const MatchingScreen({super.key, required this.exercise});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  late List<Map<String, String>> _pairs;

  @override
  void initState() {
    super.initState();
    final List<dynamic> data = widget.exercise.content['pairs'] ?? [];
    _pairs = data.map((p) => Map<String, String>.from(p as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matchingState = ref.watch(matchingProvider(_pairs));
    final notifier = ref.read(matchingProvider(_pairs).notifier);

    if (matchingState.isFinished) {
      return _ResultScreen(
        exercise: widget.exercise,
        matches: matchingState.matchesFound,
        total: matchingState.totalPairs,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.exercise.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: matchingState.matchesFound / matchingState.totalPairs,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${matchingState.matchesFound} / ${matchingState.totalPairs} eşleşme',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Memory Grid (3 columns for 12 cards)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: matchingState.items.length,
                  itemBuilder: (context, index) {
                    final item = matchingState.items[index];
                    return _MemoryCard(
                      item: item,
                      onTap: () => notifier.flipCard(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MatchingItem item;
  final VoidCallback onTap;

  const _MemoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _getBgColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor(), width: 2),
          boxShadow: [
            if (item.isFlipped && !item.isMatched)
              BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 8),
          ],
        ),
        child: Center(
          child: item.isFlipped || item.isMatched
              ? Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    item.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: item.isMatched ? Colors.white70 : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Text(
                  '?',
                  style: TextStyle(color: Colors.white38, fontSize: 24, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Color _getBgColor() {
    if (item.isMatched) return AppColors.primaryGreen.withOpacity(0.2);
    if (item.isError) return Colors.redAccent.withOpacity(0.2);
    if (item.isFlipped) return Colors.white.withOpacity(0.15);
    return Colors.white.withOpacity(0.05);
  }

  Color _getBorderColor() {
    if (item.isMatched) return AppColors.primaryGreen;
    if (item.isError) return Colors.redAccent;
    if (item.isFlipped) return Colors.white54;
    return Colors.white10;
  }
}

class _ResultScreen extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  final int matches;
  final int total;

  const _ResultScreen({required this.exercise, required this.matches, required this.total});

  @override
  ConsumerState<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<_ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = ref.read(firebaseServiceProvider).currentUserId;
      if (uid != null) {
        await ref.read(firebaseServiceProvider).completeExercise(
          uid,
          widget.exercise.id,
          type: widget.exercise.type.name,
          level: widget.exercise.level,
          language: widget.exercise.language,
          score: widget.total,
          jetonReward: 20,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(mergedExerciseTrackProvider((level: widget.exercise.level, type: widget.exercise.type)));
    final currentIndex = track.indexWhere((e) => e.id == widget.exercise.id);
    final nextExercise = (currentIndex != -1 && currentIndex < track.length - 1) ? track[currentIndex + 1] : null;
    final hasNext = nextExercise != null && nextExercise.content.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 100),
            const SizedBox(height: 24),
            const Text(
              'Tebrikler!',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Tüm kelimeleri eşleştirdin.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
            ),
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    '+20 Jeton Kazandın!',
                    style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(adServiceProvider).showInterstitial(
                          onComplete: () {
                            if (context.mounted) {
                              if (hasNext) {
                                context.pushReplacement('/exercise/${nextExercise.id}');
                              } else {
                                context.pop();
                              }
                            }
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        hasNext ? 'SONRAKİ EGZERSİZ' : 'YOL\'A DÖN',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  if (hasNext) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref.read(adServiceProvider).showInterstitial(
                          onComplete: () {
                            if (context.mounted) context.pop();
                          },
                        );
                      },
                      child: const Text('YOL\'A DÖN', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
