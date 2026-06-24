import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/exercise_model.dart';
import 'quiz_provider.dart';
import '../path/path_providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  const QuizScreen({super.key, required this.exercise});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    final List<dynamic> data = widget.exercise.content['questions'] ?? [];
    _questions = data.map((q) => QuizQuestion.fromMap(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider(_questions));
    final notifier = ref.read(quizProvider(_questions).notifier);

    if (quizState.isFinished) {
      return _ResultScreen(
        correctCount: quizState.correctCount,
        totalCount: _questions.length,
        exercise: widget.exercise,
      );
    }

    final currentQuestion = _questions[quizState.currentIndex];
    final progress = (quizState.currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
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
                        'Soru ${quizState.currentIndex + 1} / ${_questions.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const _AnimatedTimerCircle(),
                  ],
                ),
              ),

              // Progress Bar (Thin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ),

              const Spacer(),

              // Question Card (Frosted Glass)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _QuestionCard(question: currentQuestion),
              ),

              const Spacer(),

              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(currentQuestion.options.length, (index) {
                    final isSelected = quizState.selectedOption == index;
                    final isCorrect = currentQuestion.correctIndex == index;
                    
                    Color borderColor = Colors.white10;
                    Color bgColor = Colors.white.withOpacity(0.05);
                    Color glowColor = Colors.transparent;

                    if (quizState.isAnswered) {
                      if (isCorrect) {
                        bgColor = AppColors.primaryGreen.withOpacity(0.2);
                        borderColor = AppColors.primaryGreen;
                        glowColor = AppColors.primaryGreen.withOpacity(0.3);
                      } else if (isSelected) {
                        bgColor = Colors.redAccent.withOpacity(0.2);
                        borderColor = Colors.redAccent;
                        glowColor = Colors.redAccent.withOpacity(0.3);
                      }
                    } else if (isSelected) {
                      borderColor = AppColors.primaryBlue;
                      bgColor = AppColors.primaryBlue.withOpacity(0.1);
                      glowColor = AppColors.primaryBlue.withOpacity(0.2);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => notifier.selectOption(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              if (glowColor != Colors.transparent)
                                BoxShadow(color: glowColor, blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentQuestion.options[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (quizState.isAnswered && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
                              if (quizState.isAnswered && isSelected && !isCorrect)
                                const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // Action Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: quizState.selectedOption == -1 
                        ? null 
                        : () async {
                            if (!quizState.isAnswered) {
                              notifier.checkAnswer();
                            } else {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                notifier.nextQuestion();
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.white24,
                    ),
                    child: Text(
                      quizState.isAnswered ? 'SIRADAKİ' : 'KONTROL ET',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTimerCircle extends StatelessWidget {
  const _AnimatedTimerCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: const CircularProgressIndicator(
        value: 0.7,
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Colors.white),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final parts = question.sentence.split('___');
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: ' [____] ',
              style: TextStyle(
                color: AppColors.primaryBlue.withOpacity(0.8),
                decoration: TextDecoration.underline,
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends ConsumerStatefulWidget {
  final int correctCount;
  final int totalCount;
  final ExerciseModel exercise;

  const _ResultScreen({
    required this.correctCount,
    required this.totalCount,
    required this.exercise,
  });

  @override
  ConsumerState<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<_ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isSuccess = widget.correctCount >= (widget.totalCount * 0.8);
      final jetons = isSuccess ? 20 : 0;
      final uid = ref.read(firebaseServiceProvider).currentUserId;
      if (uid != null && isSuccess) {
        await ref.read(firebaseServiceProvider).completeExercise(
          uid,
          widget.exercise.id,
          type: widget.exercise.type.name,
          level: widget.exercise.level,
          language: widget.exercise.language,
          score: widget.correctCount,
          jetonReward: jetons,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.correctCount >= (widget.totalCount * 0.8);
    final jetons = isSuccess ? 20 : 0;
    final scorePercentage = widget.correctCount / widget.totalCount;
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
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _ScorePainter(score: scorePercentage),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(scorePercentage * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${widget.correctCount} / ${widget.totalCount}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              isSuccess ? 'Tebrikler!' : 'Tekrar Denemelisin',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (isSuccess)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '+$jetons Jeton Kazandın!',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
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

class _ScorePainter extends CustomPainter {
  final double score;
  _ScorePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    final paintBase = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBase);

    final paintArc = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryBlue, Color(0xFF39D2C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      3.14159 * 2 * score,
      false,
      paintArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
