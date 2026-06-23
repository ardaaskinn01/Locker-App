import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import 'onboarding_provider.dart';
import 'avg_usage_screen.dart'; // Reuse slider shapes

class LimitSettingScreen extends ConsumerStatefulWidget {
  const LimitSettingScreen({super.key});

  @override
  ConsumerState<LimitSettingScreen> createState() => _LimitSettingScreenState();
}

class _LimitSettingScreenState extends ConsumerState<LimitSettingScreen> {
  @override
  void initState() {
    super.initState();
    // İş mantığı gereği limit otomatik olarak min değerden başlatılır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final avg = ref.read(onboardingProvider).avgUsage;
      if (avg == 1.0) {
        ref.read(onboardingProvider.notifier).setDailyLimit(0.5);
      } else if (avg > 1.0) {
        ref.read(onboardingProvider.notifier).setDailyLimit(0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final translations = ref.watch(translationProvider);
    
    final double maxLimit = state.avgUsage - 1.0;
    final double savings = state.avgUsage - state.dailyLimit;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                        translations.get('limitTitle'),
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

              // Büyük Seçilen Limit Gösterimi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${state.dailyLimit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translations.get('perDay'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Tasarruf Hesaplaması
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  translations.tr('savingsText', {'hours': savings.toStringAsFixed(1)}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 60),

              // Dinamik Slider / Seçim Alanı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _buildLimitInput(state, maxLimit),
              ),

              const Spacer(),

              // Alt Bilgi Kartı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          translations.get('infoText'),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Devam Et Butonu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/onboarding/target-lang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                      ),
                      child: Text(translations.get('continueText')),
                    ),
                    const SizedBox(height: 20),
                    const _StepIndicator(currentStep: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitInput(OnboardingState state, double maxLimit) {
    // Özel Durum 1: 30 dk sabit
    if (state.avgUsage == 1.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "0.5 (30 dk)",
          style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Özel Durum 2: Sadece 2 seçenek (SegmentedButton)
    if (state.avgUsage == 1.5) {
      return SegmentedButton<double>(
        segments: const [
          ButtonSegment(value: 0.5, label: Text("0.5 h")),
          ButtonSegment(value: 1.0, label: Text("1.0 h")),
        ],
        selected: {state.dailyLimit},
        onSelectionChanged: (val) {
          ref.read(onboardingProvider.notifier).setDailyLimit(val.first);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      );
    }

    // Normal Durum: Slider
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            trackShape: const GradientRectSliderTrackShape(),
            thumbShape: const GradientSliderThumbShape(),
            inactiveTrackColor: AppColors.surface,
          ),
          child: Slider(
            value: state.dailyLimit,
            min: 0.5,
            max: maxLimit,
            divisions: ((maxLimit - 0.5) / 0.5).round(),
            onChanged: (val) {
              ref.read(onboardingProvider.notifier).setDailyLimit(val);
            },
          ),
        ),
        _buildLabels(maxLimit),
      ],
    );
  }

  Widget _buildLabels(double maxLimit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("0.5h", style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text("${maxLimit}h", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
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
