import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import 'onboarding_provider.dart';

class AvgUsageScreen extends ConsumerWidget {
  const AvgUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translations = ref.watch(translationProvider);

    // Dinamik motivasyon metni ve emoji seçimi
    String getMotivationText() {
      if (state.avgUsage <= 2.0) return translations.get('motivationGreat');
      if (state.avgUsage <= 4.0) return translations.get('motivationGood');
      return translations.get('motivationBad');
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        translations.get('avgUsageTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Büyük Saat Gösterimi
              Text(
                '${state.avgUsage}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                translations.get('hours'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Özel Slider Tasarımı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 12,
                        activeTrackColor: Colors.transparent, // Custom painter kullanacağız
                        inactiveTrackColor: AppColors.surface,
                        trackShape: const GradientRectSliderTrackShape(),
                        thumbShape: const GradientSliderThumbShape(),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
                        activeTickMarkColor: Colors.white24,
                        inactiveTickMarkColor: Colors.white10,
                      ),
                      child: Slider(
                        value: state.avgUsage,
                        min: 1.0,
                        max: 7.0,
                        divisions: 12, // 0.5 adımlarla (7-1)*2
                        onChanged: (val) {
                          ref.read(onboardingProvider.notifier).setAvgUsage(val);
                        },
                      ),
                    ),
                    // Alt Etiketler (1s ... 7s)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          return Text(
                            '${index + 1}h',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Motivasyon Metni (AnimatedSwitcher ile yumuşak geçiş)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey<String>(getMotivationText()),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      getMotivationText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Alt Butonlar
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/onboarding/select-apps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                      ),
                      child: Text(translations.get('next')),
                    ),
                    const SizedBox(height: 20),
                    _StepIndicator(currentStep: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM SLIDER SHAPES ---

class GradientRectSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const GradientRectSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryBlue, AppColors.primaryGreen],
      ).createShader(trackRect);

    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor!;

    // Inactive (arka plan)
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(8)),
      inactivePaint,
    );

    // Active (ilerleme)
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, const Radius.circular(8)),
      activePaint,
    );
  }
}

class GradientSliderThumbShape extends SliderComponentShape {
  const GradientSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 40);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint thumbPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
      ).createShader(Rect.fromCircle(center: center, radius: 15))
      ..style = PaintingStyle.fill;

    // Dış gölge
    canvas.drawCircle(center, 18, Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    
    // Beyaz Thumb
    canvas.drawCircle(center, 15, thumbPaint);

    // Değeri thumb içine yaz (Opsiyonel)
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentStep ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: index == currentStep ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
