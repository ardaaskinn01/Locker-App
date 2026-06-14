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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Run seed logic when home screen is first shown (session should be active)
    SeedService.seedDemoExercisesIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return const _HomeTabView();
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
  final dynamic user;
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
            const SizedBox(height: 32),
            const QuickActionsRow(),
            const SizedBox(height: 140),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          AnimatedFlipCounter(
            value: jetons,
            textStyle: const TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w900,
              fontSize: 20,
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2841).withOpacity(0.7),
              borderRadius: BorderRadius.circular(40),
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
                const SizedBox(height: 32),
                Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuart,
                      height: 16,
                      width: (MediaQuery.of(context).size.width - 112) * progress,
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
                ),
                const SizedBox(height: 24),
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
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.timer_outlined,
            label: translations.get('getExtensionTitle'),
            subtitle: translations.get('getExtensionSubtitle'),
            isFullWidth: true,
            color: AppColors.primaryBlue.withOpacity(0.15),
            onTap: () async {
              final user = ref.read(userProvider).value;
              if (user != null) {
                if (user.jetons < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(translations.get('insufficientJetons')), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }
                try {
                   await ref.read(firebaseServiceProvider).buyBonusTime(user.uid);
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
              }
            },
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(32),
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
          const SizedBox(height: 20),
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
