import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'features/onboarding/onboarding_provider.dart';
import 'features/onboarding/language_selection_screen.dart';
import 'features/onboarding/user_info_screen.dart';
import 'features/onboarding/avg_usage_screen.dart';
import 'features/onboarding/select_apps_screen.dart';
import 'features/onboarding/limit_setting_screen.dart';
import 'features/onboarding/target_language_screen.dart';

import 'features/home/home_screen.dart';
import 'features/home/home_providers.dart';
import 'features/path/path_screen.dart';
import 'features/path/level_detail_screen.dart';
import 'features/exercise/quiz_screen.dart';
import 'features/exercise/sentence_builder_screen.dart';
import 'features/exercise/matching_screen.dart';
import 'features/settings/settings_screen.dart';
import 'models/exercise_model.dart';
import 'core/services/firebase_service.dart';
import 'core/services/jeton_reset_service.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/seed_service.dart';
import 'core/services/connectivity_service.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/loading_error_widgets.dart';
import 'core/constants/app_colors.dart';
import 'core/services/usage_sync_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await jetonResetServiceProvider.checkAndReset(uid);
      await appLockServiceProvider.syncLockedApps(uid);
      await appLockServiceProvider.syncLimitStatus(uid);
    }
    return Future.value(true);
  });
}

final singleExerciseProvider = FutureProvider.family<ExerciseModel?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance.collection('exercises').doc(id).get();
  if (doc.exists) return ExerciseModel.fromFirestore(doc);
  return null;
});

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    await NotificationService().init();
    await AdService().initialize();

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      "daily-reset-task",
      "checkAndResetTask",
      frequency: const Duration(minutes: 1), // Demo için 1 dakikaya indirildi
      constraints: Constraints(networkType: NetworkType.connected),
    );

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    final String savedLang = prefs.getString('appLanguage') ?? 'en';

    runApp(ProviderScope(
      overrides: [languageProvider.overrideWith((ref) => savedLang)],
      child: MyApp(onboardingCompleted: onboardingCompleted),
    ));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends ConsumerWidget {
  final bool onboardingCompleted;
  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (onboardingCompleted) {
      // Start foreground sync timer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(usageSyncProvider).startSync();
      });
    }

    final language = ref.watch(languageProvider);
    ref.watch(notificationSyncProvider);

    ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (previous, next) {
      next.whenData((isConnected) {
        if (!isConnected) {
          debugPrint('No internet connection');
        } else {
          debugPrint('Internet connection restored');
        }
      });
    });

    final GoRouter router = GoRouter(
      initialLocation: onboardingCompleted ? '/home' : '/onboarding',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            String screenName = 'home';
            final loc = state.matchedLocation;
            if (loc.contains('onboarding')) screenName = 'onboarding';
            else if (loc.contains('path')) screenName = 'path';
            else if (loc.contains('exercise')) screenName = 'exercise';
            else if (loc.contains('settings')) screenName = 'settings';

            final bool showNavBar = !loc.contains('onboarding') && !loc.contains('exercise');
            final int currentIndex = _calculateSelectedIndex(loc);

            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: showNavBar ? 100 : 0),
                      child: child,
                    ),
                  ),
                  if (showNavBar)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BannerAdWidget(
                            key: ValueKey(screenName),
                            screenName: screenName,
                          ),
                          _FloatingNavBar(
                            currentIndex: currentIndex,
                            onTap: (index) => _onItemTapped(index, context),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/path', builder: (context, state) => const PathScreen()),
            GoRoute(
              path: '/path/:level',
              builder: (context, state) => LevelDetailScreen(level: state.pathParameters['level']!),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/edit-apps',
              builder: (context, state) => const SelectAppsScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const LanguageSelectionScreen(),
              routes: [
                GoRoute(path: 'user-info', builder: (context, state) => const UserInfoScreen()),
                GoRoute(path: 'avg-usage', builder: (context, state) => const AvgUsageScreen()),
                GoRoute(path: 'select-apps', builder: (context, state) => const SelectAppsScreen()),
                GoRoute(path: 'limit', builder: (context, state) => const LimitSettingScreen()),
                GoRoute(path: 'target-lang', builder: (context, state) => const TargetLanguageScreen()),
              ],
            ),
            GoRoute(
              path: '/exercise/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return Consumer(builder: (context, ref, child) {
                  final exerciseAsync = ref.watch(singleExerciseProvider(id));
                  return exerciseAsync.when(
                    data: (ex) {
                      if (ex == null) return const Scaffold(body: Center(child: Text('Not found')));
                      if (ex.type == ExerciseType.quiz) return QuizScreen(exercise: ex);
                      if (ex.type == ExerciseType.sentenceBuilder) return SentenceBuilderScreen(exercise: ex);
                      if (ex.type == ExerciseType.matching || ex.type == ExerciseType.flashcard) {
                        return MatchingScreen(exercise: ex);
                      }
                      return const Scaffold(body: Center(child: Text('Unknown exercise type')));
                    },
                    loading: () => const Scaffold(body: LoadingWidget()),
                    error: (err, _) => Scaffold(body: CommonErrorWidget(message: 'Hata: $err', onRetry: () {
                      ref.invalidate(singleExerciseProvider(id));
                    })),
                  );
                });
              },
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'LockApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: Locale(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      routerConfig: router,
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/path')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/path');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2841), // Matching Home Screen elements
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Ana Sayfa',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.map_rounded,
            label: 'Yolum',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Ayarlar',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
