import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import 'onboarding_provider.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translations = ref.watch(translationProvider);
    final isButtonEnabled = state.referralSource.isNotEmpty;

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
                    Text(
                      translations.get('howDidYouFindUs'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          _ReferralChip(
                            label: 'TikTok',
                            isSelected: state.referralSource == 'TikTok',
                            onSelected: () => _updateReferral(ref, 'TikTok'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: 'Instagram',
                            isSelected: state.referralSource == 'Instagram',
                            onSelected: () => _updateReferral(ref, 'Instagram'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: translations.get('friends'),
                            isSelected: state.referralSource == 'Friends',
                            onSelected: () => _updateReferral(ref, 'Friends'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: translations.get('other'),
                            isSelected: state.referralSource == 'Other',
                            onSelected: () => _updateReferral(ref, 'Other'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: isButtonEnabled
                          ? () => context.push('/onboarding/avg-usage')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Text(translations.get('next')),
                    ),
                    const SizedBox(height: 20),
                    _StepIndicator(currentStep: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateReferral(WidgetRef ref, String source) {
    ref.read(onboardingProvider.notifier).setReferral(source);
  }
}

class _ReferralChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ReferralChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentStep ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
