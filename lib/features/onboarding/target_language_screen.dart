import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import 'onboarding_provider.dart';

class TargetLanguageScreen extends ConsumerStatefulWidget {
  const TargetLanguageScreen({super.key});

  @override
  ConsumerState<TargetLanguageScreen> createState() => _TargetLanguageScreenState();
}

class _TargetLanguageScreenState extends ConsumerState<TargetLanguageScreen> {
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final l10n = AppLocalizations.of(context)!;
    final isLevelVisible = state.targetLanguage.isNotEmpty;
    final isButtonEnabled = state.targetLanguage.isNotEmpty && state.languageLevel.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
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
                            l10n.targetLangTitle,
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

                  // Dil Seçimi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: _languages.map((lang) {
                        final isSelected = state.targetLanguage == lang['code'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _LangCard(
                              lang: lang,
                              isSelected: isSelected,
                              onTap: () => ref.read(onboardingProvider.notifier).setTargetLanguage(lang['code']!),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Seviye Seçimi (Dinamik Görünüm)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isLevelVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: isLevelVisible
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.selectLevel,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _LevelTile(
                                    level: 'A1',
                                    title: 'A1 - Beginner',
                                    subtitle: l10n.a1Desc,
                                    isSelected: state.languageLevel == 'A1',
                                    onTap: () => ref.read(onboardingProvider.notifier).setLanguageLevel('A1'),
                                  ),
                                  const SizedBox(height: 12),
                                  _LevelTile(
                                    level: 'A2',
                                    title: 'A2 - Elementary',
                                    subtitle: l10n.a2Desc,
                                    isSelected: state.languageLevel == 'A2',
                                    onTap: () => ref.read(onboardingProvider.notifier).setLanguageLevel('A2'),
                                  ),
                                  const SizedBox(height: 12),
                                  _LevelTile(
                                    level: 'B1',
                                    title: 'B1 - Intermediate',
                                    subtitle: l10n.b1Desc,
                                    isSelected: state.languageLevel == 'B1',
                                    onTap: () => ref.read(onboardingProvider.notifier).setLanguageLevel('B1'),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Başlayalım Butonu
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: isButtonEnabled ? _handleFinalize : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                          ),
                          child: Text(l10n.letsStart),
                        ),
                        const SizedBox(height: 20),
                        _StepIndicator(currentStep: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(l10n.registering, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleFinalize() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      
      // 1. Anonim Giriş
      final uid = await firebaseService.signInAnonymously();
      
      if (uid != null) {
        // 2. Veritabanına kayıt
        final userData = ref.read(onboardingProvider.notifier).finalizeOnboarding();
        await firebaseService.createUserDocument(uid, userData);
        
        // 3. SharedPreferences güncelleme
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingCompleted', true);
        
        // 4. Ana Sayfaya yönlendirme
        if (mounted) {
          context.go('/home');
        }
      } else {
        throw Exception("UID is null");
      }
    } catch (e) {
      debugPrint("ONBOARDING_ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.errorOccurred}: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _LangCard extends StatelessWidget {
  final Map<String, String> lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangCard({required this.lang, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(lang['name']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String level;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: isSelected ? AppColors.primaryBlue : Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: isSelected ? AppColors.primaryBlue.withOpacity(0.7) : Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primaryBlue),
          ],
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
