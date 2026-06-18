import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/translations.dart';
import '../../core/constants/app_colors.dart';
import 'onboarding_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLang = ref.watch(onboardingProvider).appLanguage;
    final translations = ref.watch(translationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Logo Area
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LockApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                translations.get('chooseLanguage'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: _LanguageCard(
                        title: 'English',
                        flag: '🇬🇧',
                        isSelected: selectedLang == 'en',
                        onTap: () => _selectLanguage(ref, 'en'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _LanguageCard(
                        title: 'Türkçe',
                        flag: '🇹🇷',
                        isSelected: selectedLang == 'tr',
                        onTap: () => _selectLanguage(ref, 'tr'),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: selectedLang.isEmpty
                          ? null
                          : () => context.push('/onboarding/user-info'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Text(translations.get('continueText')),
                    ),
                    const SizedBox(height: 20),
                    _StepIndicator(currentStep: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(WidgetRef ref, String lang) async {
    ref.read(onboardingProvider.notifier).setLanguage(lang);
    ref.read(languageProvider.notifier).state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', lang);
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
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
      children: List.generate(7, (index) {
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
