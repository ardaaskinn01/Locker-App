import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/exercise_model.dart';
import 'sentence_builder_provider.dart';
import '../path/path_providers.dart';

class SentenceBuilderScreen extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  const SentenceBuilderScreen({super.key, required this.exercise});

  @override
  ConsumerState<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends ConsumerState<SentenceBuilderScreen> with SingleTickerProviderStateMixin {
  late List<SentenceChallenge> _challenges;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    final List<dynamic> data = widget.exercise.content['sentences'] ?? [];
    _challenges = data.map((s) => SentenceChallenge.fromMap(s)).toList();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final sbState = ref.watch(sentenceBuilderProvider(_challenges));
    final notifier = ref.read(sentenceBuilderProvider(_challenges).notifier);
    final translations = ref.watch(translationProvider);

    if (sbState.isFinished) {
      return _ResultScreen(
        score: sbState.score,
        total: _challenges.length,
        exercise: widget.exercise,
      );
    }

    final currentChallenge = sbState.challenges[sbState.currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Top Bar
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
                        'Soru ${sbState.currentIndex + 1} / ${_challenges.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Thin Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (sbState.currentIndex + 1) / _challenges.length,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Instruction
              const Text(
                'Cümleyi oluştur:',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              // Drop Zone (Frosted glass + dotted border)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(sbState.isCorrect == false ? _shakeAnimation.value : 0, 0),
                    child: child,
                  ),
                  child: DottedBorder(
                    color: sbState.isCorrect == true
                        ? AppColors.primaryGreen
                        : (sbState.isCorrect == false ? Colors.redAccent : Colors.white24),
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(20),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 100),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sbState.selectedWords.isEmpty
                            ? [
                                Text(
                                  'Kelimelere dokun…',
                                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                                ),
                              ]
                            : sbState.selectedWords.map((word) => _WordChip(
                                word: word,
                                onTap: () => notifier.deselectWord(word),
                                isSelected: true,
                                color: sbState.isCorrect == true ? AppColors.primaryGreen : null,
                              )).toList(),
                      ),
                    ),
                  ),
                ),
              ),

              // Error hint
              if (sbState.isCorrect == false)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                  child: Text(
                    translations.tr('correctAnswer', {'sentence': currentChallenge.correctSentence}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),

              const Spacer(),

              // Word Bank (pill chips)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: sbState.shuffledWords.map((word) {
                    return _WordChip(
                      word: word,
                      onTap: () => notifier.selectWord(word),
                      isSelected: false,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Full-width Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: sbState.selectedWords.isEmpty || sbState.isCorrect != null
                        ? (sbState.isCorrect != null ? () => notifier.nextChallenge() : null)
                        : () {
                            final correct = notifier.checkAnswer();
                            if (!correct) _triggerShake();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      sbState.isCorrect != null ? 'DEVAM ET' : 'KONTROL ET',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? color;

  const _WordChip({
    required this.word,
    required this.onTap,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: color == null ? LinearGradient(
            colors: isSelected 
                ? [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)]
                : [AppColors.surface, AppColors.surface.withOpacity(0.8)],
          ) : null,
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          word,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

class _ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final ExerciseModel exercise;

  const _ResultScreen({required this.score, required this.total, required this.exercise});

  @override
  ConsumerState<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<_ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isSuccess = widget.score >= (widget.total * 0.7);
      final jetons = isSuccess ? 20 : 0;
      final uid = ref.read(firebaseServiceProvider).currentUserId;
      if (uid != null && isSuccess) {
        await ref.read(firebaseServiceProvider).completeExercise(
          uid,
          widget.exercise.id,
          type: widget.exercise.type.name,
          level: widget.exercise.level,
          language: widget.exercise.language,
          score: widget.score,
          jetonReward: jetons,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.score >= (widget.total * 0.7); 
    final jetons = isSuccess ? 20 : 0;
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
            Icon(
              isSuccess ? Icons.workspace_premium_rounded : Icons.refresh_rounded,
              size: 100,
              color: isSuccess ? AppColors.accentGold : Colors.white24,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess ? 'Tebrikler!' : 'Tekrar Denemelisin',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Skor: ${widget.score} / ${widget.total}",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 48),
            
            if (isSuccess)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+$jetons Jeton Kazandın!',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 16),
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
                              if (hasNext && isSuccess) {
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
                        (hasNext && isSuccess) ? 'SONRAKİ EGZERSİZ' : 'YOL\'A DÖN',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  if (hasNext && isSuccess) ...[
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
            
            if (!isSuccess)
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('TEKRAR DENE', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
