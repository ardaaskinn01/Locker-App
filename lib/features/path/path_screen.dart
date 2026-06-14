import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../home/home_providers.dart';
import '../home/home_screen.dart'; // To use JetonCounter
import 'path_providers.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Öğrenme Yolun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const JetonCounter(),
                  ],
                ),
              ),

              // Floating language/user info card
              userAsync.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return _UserInfoHeader(user: user);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              Expanded(
                child: userAsync.when(
                  data: (user) {
                    if (user == null) return const Center(child: CircularProgressIndicator());
                    
                    final levels = [
                      ('A1', 'Beginner', [AppColors.primaryBlue.withOpacity(0.8), const Color(0xFF39D2C0)]),
                      ('A2', 'Elementary', [const Color(0xFF9B51E0), const Color(0xFFE040FB)]),
                      ('B1', 'Intermediate', [const Color(0xFFFF9100), const Color(0xFFFF3D00)]),
                    ];

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                      itemCount: levels.length,
                      itemBuilder: (context, index) {
                        final levelData = levels[index];
                        final code = levelData.$1;
                        final title = levelData.$2;
                        final colors = levelData.$3;
                        final isUnlocked = user.unlockedLevels.contains(code);
                        final isLast = index == levels.length - 1;

                        return Consumer(
                          builder: (context, ref, child) {
                            final stats = ref.watch(levelProgressProvider(code)).value ?? (completed: 0, total: 180, percent: 0.0);
                            
                            return Column(
                              children: [
                                _LevelCard(
                                  level: code,
                                  title: title,
                                  flag: _getFlagStatic(user.targetLanguage),
                                  progress: stats.percent,
                                  isUnlocked: isUnlocked,
                                  exerciseCount: '${stats.completed} / ${stats.total}',
                                  gradientColors: colors,
                                ),
                                if (!isLast)
                                  _PathConnector(isUnlocked: isUnlocked),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                ),
              ),
              const SizedBox(height: 100), // Space for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  static String _getFlagStatic(String lang) {
    switch (lang) {
      case 'en': return '🇬🇧';
      case 'es': return '🇪🇸';
      case 'it': return '🇮🇹';
      default: return '🌐';
    }
  }
}

class _UserInfoHeader extends StatelessWidget {
  final dynamic user;
  const _UserInfoHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Text(_getFlag(user.targetLanguage), style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${user.targetLanguage.toUpperCase()} Yolculuğu',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.5)),
              ),
              child: const Text(
                'A1 Seviye',
                style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFlag(String lang) {
    switch (lang) {
      case 'en': return '🇬🇧';
      case 'es': return '🇪🇸';
      case 'it': return '🇮🇹';
      default: return '🌐';
    }
  }
}

class _PathConnector extends StatelessWidget {
  final bool isUnlocked;
  const _PathConnector({required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: List.generate(4, (index) => Expanded(
          child: Container(
            width: 2,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.primaryBlue.withOpacity(0.5) : Colors.white10,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        )),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String level;
  final String title;
  final String flag;
  final double progress;
  final bool isUnlocked;
  final String exerciseCount;
  final List<Color> gradientColors;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.flag,
    required this.progress,
    required this.isUnlocked,
    required this.exerciseCount,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          context.push('/path/$level');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu seviyeyi açmak için öncekileri tamamla!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: isUnlocked 
            ? LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
          color: isUnlocked ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isUnlocked ? Colors.white24 : Colors.white10),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                top: 40,
                bottom: 40,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        level,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(80, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Text(flag, style: const TextStyle(fontSize: 22)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exerciseCount,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (!isUnlocked)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.lock_rounded, color: Colors.white54, size: 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
