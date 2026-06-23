import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/translations.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/seed_service.dart';
import 'home_providers.dart';
import '../../core/services/app_lock_service.dart';
import '../../models/user_model.dart';
import 'daily_mini_game_screen.dart';
import '../../core/services/usage_sync_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // Run seed logic when home screen is first shown (session should be active)
    SeedService.seedDemoExercisesIfNeeded();
    // Start foreground usage sync timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageSyncProvider).startSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    userAsync.whenData((user) {
      if (user != null && user.lastChallengeResult != null && !_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showChallengeResultDialog(context, ref, user.uid, user.lastChallengeResult!);
        });
      }
    });

    return const _HomeTabView();
  }

  void _showChallengeResultDialog(
    BuildContext context, 
    WidgetRef ref, 
    String uid, 
    Map<String, dynamic> result,
  ) {
    final bool wasSuccess = result['wasSuccess'] ?? false;
    final int betAmount = result['betAmount'] ?? 0;
    final int reward = wasSuccess ? betAmount * 2 : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2841),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wasSuccess ? 'Tebrikler!' : 'Başaramadın',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  wasSuccess
                      ? "Dünkü günlük limit hedefine ulaştın ve sosyal medyada kaybolmadın! Yatırılan $betAmount Jeton'un iki katını kazandın."
                      : "Dün günlük sosyal medya limitini aştın ve meydan okumayı kaybettin. Yatırdığın $betAmount Jeton yandı.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 32),
                if (wasSuccess) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '+$reward Jeton',
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (wasSuccess) {
                        await ref.read(firebaseServiceProvider).claimChallengeReward(uid);
                      } else {
                        await ref.read(firebaseServiceProvider).dismissChallengeResult(uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      wasSuccess ? 'Ödülü Al' : 'Tamam',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeTabView extends ConsumerWidget {
  const _HomeTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: userAsync.when(
          loading: () => const _LoadingHomeView(),
          error: (e, st) => _ErrorHomeView(onRetry: () => ref.invalidate(userProvider)),
          data: (user) {
            if (user == null) {
              return _ErrorHomeView(onRetry: () => ref.invalidate(userProvider));
            }
            return _HomeBody(user: user);
          },
        ),
      ),
    );
  }
}
class _LoadingHomeView extends StatelessWidget {
  const _LoadingHomeView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Yükleniyor...',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorHomeView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorHomeView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 24),
              Text(
                'Bağlantı Hatası',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kullanıcı verileri yüklenemedi.\nLütfen internet bağlantınızı kontrol edin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final UserModel user;
  const _HomeBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationProvider);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations.get('hello'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.name.isNotEmpty ? user.name : translations.get('other'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const JetonCounter(),
                ],
              ),
            ),
            const DailyUsageBar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ActionCard(
                icon: Icons.timer_outlined,
                label: translations.get('getExtensionTitle'),
                subtitle: translations.get('getExtensionSubtitle'),
                isFullWidth: true,
                color: AppColors.primaryBlue.withOpacity(0.15),
                onTap: () async {
                  if (user.jetons < 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(translations.get('insufficientJetons')), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  try {
                     await ref.read(firebaseServiceProvider).buyBonusTime(user.uid);
                     await appLockServiceProvider.syncLimitStatus(user.uid);
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(translations.get('bonusAdded')), behavior: SnackBarBehavior.floating),
                       );
                     }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            DailyChallengeCard(user: user),
            const SizedBox(height: 20),
            DailyMiniGameCard(user: user),
            const SizedBox(height: 20),
            const QuickActionsRow(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget withAnimatedScale({VoidCallback? onTap}) {
    return _AnimatedScaleWrapper(onTap: onTap, child: this);
  }
}

class _AnimatedScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _AnimatedScaleWrapper({required this.child, this.onTap});

  @override
  State<_AnimatedScaleWrapper> createState() => _AnimatedScaleWrapperState();
}

class _AnimatedScaleWrapperState extends State<_AnimatedScaleWrapper> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class JetonCounter extends ConsumerWidget {
  const JetonCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jetons = ref.watch(jetonProvider);
    final translations = ref.watch(translationProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2841),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          AnimatedFlipCounter(
            value: jetons,
            textStyle: const TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 16,
            width: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final user = ref.read(userProvider).value;
              if (user != null) {
                ref.read(adServiceProvider).showRewarded(
                  user: user,
                  firebaseService: ref.read(firebaseServiceProvider),
                  onRewarded: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.get('rewardSuccess')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onError: (err) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), behavior: SnackBarBehavior.floating)
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.accentGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF0F172A),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyUsageBar extends ConsumerWidget {
  const DailyUsageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationProvider);
    final userAsync = ref.watch(userProvider);
    final spentMin = ref.watch(usageMinutesProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final int limitMin = (user.dailyLimit * 60).round() + (user.bonusMinutes);
        if (limitMin == 0) return const SizedBox.shrink();
        final progress = (spentMin / limitMin).clamp(0.0, 1.0);
        final isLimitReached = spentMin >= limitMin;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2841).withOpacity(0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.get('todayUsage'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutQuart,
                          height: 12,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLimitReached 
                                ? [Colors.redAccent, Colors.redAccent.withOpacity(0.8)]
                                : [const Color(0xFF39D2C0), const Color(0xFF1CB5E0)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (isLimitReached ? Colors.redAccent : const Color(0xFF39D2C0)).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations.get('spentTime'),
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 18),
                            children: [
                              TextSpan(text: '$spentMin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              TextSpan(text: ' / $limitMin ${translations.get('hours').substring(0, 2)}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isLimitReached)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          translations.get('limitFull'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ).withAnimatedScale(onTap: () => context.push('/path'));
      },
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }
}

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.school_rounded, 
              label: translations.get('doPractice'), 
              subtitle: translations.get('saveTheDay'),
              onTap: () => context.push('/path'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionCard(
              icon: Icons.stars_rounded, 
              label: translations.get('watchAd'), 
              subtitle: translations.get('watchAdSubtitle'),
              onTap: () {
                final user = ref.read(userProvider).value;
                if (user != null) {
                  ref.read(adServiceProvider).showRewarded(
                    user: user,
                    firebaseService: ref.read(firebaseServiceProvider),
                    onRewarded: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(translations.get('rewardSuccess')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onError: (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFullWidth;
  final Color? color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isFullWidth = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              if (isFullWidth)
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).withAnimatedScale(onTap: onTap);
  }
}

class DailyChallengeCard extends ConsumerWidget {
  final UserModel user;

  const DailyChallengeCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationProvider);
    final active = user.activeChallenge;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2841).withOpacity(0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: active == null 
            ? _buildStartChallengeView(context, ref, translations)
            : _buildActiveChallengeView(context, ref, translations, active),
      ),
    );
  }

  Widget _buildStartChallengeView(BuildContext context, WidgetRef ref, Translations translations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                translations.get('dailyChallengeTitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          translations.get('dailyChallengeSubtitle'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              final started = await showDialog<bool>(
                context: context,
                builder: (context) => _BetSelectionDialog(user: user, ref: ref),
              );
              if (started == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(translations.get('dailyChallengeStarted')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
            ),
            child: Text(
              translations.get('dailyChallengeStartNow'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengeView(
    BuildContext context, 
    WidgetRef ref, 
    Translations translations, 
    Map<String, dynamic> challenge,
  ) {
    final bet = challenge['betAmount'] ?? 0;
    final exceeded = challenge['exceededLimit'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (exceeded ? Colors.redAccent : AppColors.accentGold).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                exceeded ? Icons.warning_amber_rounded : Icons.emoji_events_rounded, 
                color: exceeded ? Colors.redAccent : AppColors.accentGold, 
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                translations.get('dailyChallengeActive'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                translations.tr('dailyChallengeBet', {'bet': bet.toString()}),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (exceeded ? Colors.redAccent : const Color(0xFF39D2C0)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (exceeded ? Colors.redAccent : const Color(0xFF39D2C0)).withOpacity(0.4),
                ),
              ),
              child: Text(
                exceeded 
                    ? translations.get('dailyChallengeStatusExceeded')
                    : translations.get('dailyChallengeStatusNotExceeded'),
                style: TextStyle(
                  color: exceeded ? Colors.redAccent : const Color(0xFF39D2C0),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          exceeded 
              ? translations.get('dailyChallengeFailedMsg')
              : translations.get('dailyChallengeRunning'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BetSelectionDialog extends StatefulWidget {
  final UserModel user;
  final WidgetRef ref;

  const _BetSelectionDialog({required this.user, required this.ref});

  @override
  State<_BetSelectionDialog> createState() => _BetSelectionDialogState();
}

class _BetSelectionDialogState extends State<_BetSelectionDialog> {
  int _selectedBet = 50;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final translations = widget.ref.read(translationProvider);
    final userJetons = widget.user.jetons;

    return Dialog(
      backgroundColor: const Color(0xFF1E2841),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentGold,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              translations.get('dailyChallengeChooseBet'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              translations.get('dailyChallengeSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [30, 50, 100].map((amount) {
                final isSelected = _selectedBet == amount;
                final isAffordable = userJetons >= amount;
                
                return GestureDetector(
                  onTap: isAffordable ? () {
                    setState(() {
                      _selectedBet = amount;
                    });
                  } : null,
                  child: Opacity(
                    opacity: isAffordable ? 1.0 : 0.4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.accentGold.withOpacity(0.15) 
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.accentGold 
                              : Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            '$amount',
                            style: TextStyle(
                              color: isSelected ? AppColors.accentGold : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              '${translations.get('jetons')}: $userJetons 🪙',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (userJetons < _selectedBet) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.tr('dailyChallengeInsufficient', {'bet': _selectedBet.toString()})),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await widget.ref
                        .read(firebaseServiceProvider)
                        .startDailyChallenge(widget.user.uid, _selectedBet);
                    if (mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : Text(
                        translations.get('dailyChallengeStart'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyMiniGameCard extends ConsumerWidget {
  final UserModel user;

  const DailyMiniGameCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final bool completedToday = user.lastMiniGameDate == dateStr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: completedToday
              ? LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: completedToday 
                ? Colors.white.withOpacity(0.08) 
                : Colors.white.withOpacity(0.2), 
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (completedToday ? Colors.black : const Color(0xFFFF416C)).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completedToday ? Icons.task_alt_rounded : Icons.swipe_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Günlük Kelime Oyunu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              completedToday
                  ? 'Bugünün kelimelerini başarıyla tamamladın! Yarın tekrar gel.'
                  : 'Günün kelime kartlarını kaydırarak dil bilgini test et ve 25 jetona kadar kazan!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: completedToday
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DailyMiniGameScreen(
                              uid: user.uid,
                              level: user.languageLevel.isEmpty ? 'A1' : user.languageLevel,
                              language: user.targetLanguage.isEmpty ? 'en' : user.targetLanguage,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: completedToday 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.white,
                  foregroundColor: completedToday 
                      ? Colors.white30 
                      : const Color(0xFFFF416C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: Colors.white.withOpacity(0.05),
                ),
                child: Text(
                  completedToday ? 'Bugün Tamamlandı' : 'Oyuna Başla',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


