import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import 'onboarding_provider.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  const UserInfoScreen({super.key});

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(onboardingProvider).userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final translations = ref.watch(translationProvider);
    final isButtonEnabled = _nameController.text.isNotEmpty && state.referralSource.isNotEmpty;

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
                      translations.get('letsGetToKnowYou'),
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
                      // Name Field
                      TextField(
                        controller: _nameController,
                        onChanged: (val) {
                          ref.read(onboardingProvider.notifier).setName(val);
                          setState(() {}); // Refresh to update button state
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: translations.get('name'),
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.person, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Referral Source
                      Text(
                        translations.get('howDidYouFindUs'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _ReferralChip(
                            label: 'TikTok',
                            isSelected: state.referralSource == 'TikTok',
                            onSelected: () => _updateReferral('TikTok'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: 'Instagram',
                            isSelected: state.referralSource == 'Instagram',
                            onSelected: () => _updateReferral('Instagram'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: translations.get('friends'),
                            isSelected: state.referralSource == 'Friends',
                            onSelected: () => _updateReferral('Friends'),
                          ),
                          const SizedBox(height: 12),
                          _ReferralChip(
                            label: translations.get('other'),
                            isSelected: state.referralSource == 'Other',
                            onSelected: () => _updateReferral('Other'),
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
                    _StepIndicator(currentStep: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateReferral(String source) {
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
      children: List.generate(5, (index) {
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
