import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/home_providers.dart';

class StreakBadge extends ConsumerStatefulWidget {
  const StreakBadge({super.key});

  @override
  ConsumerState<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends ConsumerState<StreakBadge> {
  late ConfettiController _confetti;
  int _lastStreak = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final streak = user.currentStreak;

        // Trigger confetti on every 7-day milestone
        if (streak > 0 && streak != _lastStreak && streak % 7 == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
        }
        _lastStreak = streak;

        final bool active = streak > 0;
        final Color color = active ? Colors.deepOrangeAccent : Colors.grey;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: [AppColors.accentGold, Colors.orange, Colors.redAccent],
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey(streak),
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 14, color: active ? null : Colors.grey)),
                    const SizedBox(width: 4),
                    Text(
                      active ? '$streak Gün' : '0',
                      style: TextStyle(
                        color: active ? Colors.deepOrangeAccent : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class MilestoneCard extends ConsumerWidget {
  const MilestoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final pages = [
          _MilestoneItem(
            emoji: '🗓',
            title: 'Haftalık Aktivite',
            value: '${user.currentStreak} / 7 Gün',
            subtitle: 'Bu hafta aktif günün',
          ),
          _MilestoneItem(
            emoji: '🏋️',
            title: 'Toplam Egzersiz',
            value: '${user.totalExercisesCompleted}',
            subtitle: 'Egzersiz tamamladın',
          ),
          _MilestoneItem(
            emoji: '🪙',
            title: 'Toplam Jeton',
            value: '${user.totalJetonsEarned}',
            subtitle: 'Jeton kazandın',
          ),
        ];

        return SizedBox(
          height: 120,
          child: PageView(
            padEnds: false,
            controller: PageController(viewportFraction: 0.88),
            children: pages.map((p) => _MilestonePageItem(item: p)).toList(),
          ),
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MilestoneItem {
  final String emoji, title, value, subtitle;
  const _MilestoneItem({required this.emoji, required this.title, required this.value, required this.subtitle});
}

class _MilestonePageItem extends StatelessWidget {
  final _MilestoneItem item;
  const _MilestonePageItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.primaryBlue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(
                item.value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(item.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
