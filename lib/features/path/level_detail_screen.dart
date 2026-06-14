import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exercise_model.dart';
import '../../core/utils/seed_data.dart';
import 'path_providers.dart';

class LevelDetailScreen extends ConsumerStatefulWidget {
  final String level;
  const LevelDetailScreen({super.key, required this.level});

  @override
  ConsumerState<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends ConsumerState<LevelDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TrackTab(label: 'Eşleştirme', type: ExerciseType.matching, color: Color(0xFF9B51E0)),
    _TrackTab(label: 'Quiz', type: ExerciseType.quiz, color: Color(0xFF0062FF)),
    _TrackTab(label: 'Cümle', type: ExerciseType.sentenceBuilder, color: Color(0xFF00C896)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider(widget.level));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      '${widget.level} Yolu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0062FF), Color(0xFF9B51E0)],
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: _tabs.map((t) => Tab(text: t.label, height: 40)).toList(),
                  ),
                ),
              ),

              // Tab Content
              Expanded(
                child: exercisesAsync.when(
                  data: (firebaseExercises) {
                    return TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (tabIndex) {
                        final tab = _tabs[tabIndex];
                        final track = _buildTrack(firebaseExercises, tab.type);
                        return _TrackPathView(
                          exercises: track,
                          accentColor: tab.color,
                        );
                      }),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, __) {
                    // Fallback: show local placeholders even on error
                    return TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (tabIndex) {
                        final tab = _tabs[tabIndex];
                        final track = _buildTrack([], tab.type);
                        return _TrackPathView(exercises: track, accentColor: tab.color);
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Merge Firebase exercises with local placeholders to always show 60 items.
  List<ExerciseModel> _buildTrack(List<ExerciseModel> firebaseAll, ExerciseType type) {
    final lang = 'en'; // Could come from user provider
    final level = widget.level;

    // Filter Firebase exercises of this type
    final fromFirebase = firebaseAll.where((e) => e.type == type).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // Build 60-item placeholder list
    List<ExerciseModel> placeholders;
    switch (type) {
      case ExerciseType.matching:
        placeholders = SeedData.matchingTrack(language: lang, level: level);
        break;
      case ExerciseType.quiz:
        placeholders = SeedData.quizTrack(language: lang, level: level);
        break;
      case ExerciseType.sentenceBuilder:
        placeholders = SeedData.sentenceTrack(language: lang, level: level);
        break;
      default:
        placeholders = SeedData.matchingTrack(language: lang, level: level);
    }

    // Overlay Firebase data: replace placeholder with real data by order
    final Map<int, ExerciseModel> byOrder = {for (var e in placeholders) e.order: e};
    for (final fb in fromFirebase) {
      byOrder[fb.order] = fb;
    }

    final merged = byOrder.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return merged.map((e) => e.value).toList();
  }
}

class _TrackTab {
  final String label;
  final ExerciseType type;
  final Color color;
  const _TrackTab({required this.label, required this.type, required this.color});
}

// ─── Path View ────────────────────────────────────────────────────────────────

class _TrackPathView extends StatelessWidget {
  final List<ExerciseModel> exercises;
  final Color accentColor;

  const _TrackPathView({required this.exercises, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        // Sequential unlock: first is always unlocked, rest need previous completed
        final isUnlocked = index == 0 || exercises[index - 1].isCompleted;
        final isLast = index == exercises.length - 1;

        // Winding path offsets: center → right → center → left → repeat
        final double hOffset = [0.0, 0.45, 0.0, -0.45][index % 4];
        final double nextHOffset = [0.0, 0.45, 0.0, -0.45][(index + 1) % 4];

        return Column(
          children: [
            Align(
              alignment: Alignment(hOffset, 0),
              child: _PathNode(
                exercise: exercise,
                isUnlocked: isUnlocked,
                accentColor: accentColor,
                index: index + 1,
              ),
            ),
            if (!isLast)
              _CurvedConnector(
                fromOffset: hOffset,
                toOffset: nextHOffset,
                isCompleted: exercise.isCompleted,
                accentColor: accentColor,
              ),
          ],
        );
      },
    );
  }
}

// ─── Node ─────────────────────────────────────────────────────────────────────

class _PathNode extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isUnlocked;
  final Color accentColor;
  final int index;

  const _PathNode({
    required this.exercise,
    required this.isUnlocked,
    required this.accentColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = exercise.isCompleted;
    final bool hasContent = exercise.content.isNotEmpty;

    final Color nodeColor = isCompleted
        ? const Color(0xFF00C896)
        : (isUnlocked && hasContent ? accentColor : Colors.white.withOpacity(0.08));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (!isUnlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Önceki egzersizi tamamla!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }
            if (!hasContent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu egzersiz henüz hazırlanıyor...'),
                  backgroundColor: Colors.blueGrey,
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }
            context.push('/exercise/${exercise.id}');
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              if (isUnlocked && !isCompleted)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              // Main circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeColor,
                  border: Border.all(
                    color: isUnlocked ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                      : Icon(
                          isUnlocked && hasContent ? _typeIcon(exercise.type) : Icons.lock_rounded,
                          color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.2),
                          size: 28,
                        ),
                ),
              ),
              // "Coming soon" badge
              if (!hasContent && isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Yakında', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            exercise.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnlocked ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.matching: return Icons.compare_arrows_rounded;
      case ExerciseType.quiz: return Icons.quiz_rounded;
      case ExerciseType.sentenceBuilder: return Icons.text_fields_rounded;
      case ExerciseType.flashcard: return Icons.style_rounded;
    }
  }
}

// ─── Connector ────────────────────────────────────────────────────────────────

class _CurvedConnector extends StatelessWidget {
  final double fromOffset;
  final double toOffset;
  final bool isCompleted;
  final Color accentColor;

  const _CurvedConnector({
    required this.fromOffset,
    required this.toOffset,
    required this.isCompleted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(
          fromX: 0.5 + fromOffset * 0.3,
          toX: 0.5 + toOffset * 0.3,
          color: isCompleted ? accentColor.withOpacity(0.6) : Colors.white.withOpacity(0.07),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final double fromX;
  final double toX;
  final Color color;

  _ConnectorPainter({required this.fromX, required this.toX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(fromX * size.width, 0);
    path.quadraticBezierTo(
      (fromX + toX) / 2 * size.width,
      size.height / 2,
      toX * size.width,
      size.height,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.fromX != fromX || old.toX != toX || old.color != color;
}

