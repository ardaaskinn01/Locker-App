import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class OnboardingState {
  final String appLanguage;
  final String userName;
  final String referralSource;
  final double avgUsage;
  final List<String> selectedApps;
  final double dailyLimit;
  final String targetLanguage;
  final String languageLevel;

  OnboardingState({
    this.appLanguage = '',
    this.userName = '',
    this.referralSource = '',
    this.avgUsage = 4.0,
    this.selectedApps = const [],
    this.dailyLimit = 0.0,
    this.targetLanguage = '',
    this.languageLevel = '',
  });

  OnboardingState copyWith({
    String? appLanguage,
    String? userName,
    String? referralSource,
    double? avgUsage,
    List<String>? selectedApps,
    double? dailyLimit,
    String? targetLanguage,
    String? languageLevel,
  }) {
    return OnboardingState(
      appLanguage: appLanguage ?? this.appLanguage,
      userName: userName ?? this.userName,
      referralSource: referralSource ?? this.referralSource,
      avgUsage: avgUsage ?? this.avgUsage,
      selectedApps: selectedApps ?? this.selectedApps,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      languageLevel: languageLevel ?? this.languageLevel,
    );
  }

  // İş Mantığı: Seçilen seviyeye göre açık olan seviyelerin listesini döner
  List<String> getCalculatedUnlockedLevels() {
    if (languageLevel == 'B1') return ['A1', 'A2', 'B1'];
    if (languageLevel == 'A2') return ['A1', 'A2'];
    return ['A1'];
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setLanguage(String lang) => state = state.copyWith(appLanguage: lang);
  void setName(String name) => state = state.copyWith(userName: name);
  void updateName(String name) => state = state.copyWith(userName: name);
  void setReferral(String source) => state = state.copyWith(referralSource: source);
  void setAvgUsage(double val) => state = state.copyWith(avgUsage: val);
  void setSelectedApps(List<String> apps) => state = state.copyWith(selectedApps: apps);
  void setDailyLimit(double val) => state = state.copyWith(dailyLimit: val);
  void setTargetLanguage(String lang) => state = state.copyWith(targetLanguage: lang);
  void setLanguageLevel(String level) => state = state.copyWith(languageLevel: level);

  // Tüm state'i toplar ve UserModel haritasına dönüştürür (Firebase kaydı için)
  Map<String, dynamic> finalizeOnboarding() {
    return {
      'name': state.userName,
      'referralSource': state.referralSource,
      'dailyAvgUsage': state.avgUsage,
      'selectedApps': state.selectedApps,
      'dailyLimit': state.dailyLimit,
      'targetLanguage': state.targetLanguage,
      'languageLevel': state.languageLevel,
      'unlockedLevels': state.getCalculatedUnlockedLevels(),
      'jetons': 0,
      'dailyExerciseCount': 0,
      'dailyRewardedAdCount': 0,
      'resetHour': 4,
      'lastJetonReset': Timestamp.now(),
      'createdAt': Timestamp.now(),
    };
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

final languageProvider = StateProvider<String>((ref) => 'en');
