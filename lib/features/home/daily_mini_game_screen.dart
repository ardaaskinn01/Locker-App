import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyMiniGameScreen extends ConsumerStatefulWidget {
  final String uid;
  final String level;
  final String language;

  const DailyMiniGameScreen({
    super.key,
    required this.uid,
    required this.level,
    required this.language,
  });

  @override
  ConsumerState<DailyMiniGameScreen> createState() => _DailyMiniGameScreenState();
}

class _DailyMiniGameScreenState extends ConsumerState<DailyMiniGameScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  bool _isSaving = false;

  // Animation values for swiping
  Offset _dragOffset = Offset.zero;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_swipeController);

    _loadGame();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Fetch game based on current day index (deterministic 1, 2, or 3)
      final gameIndex = (DateTime.now().day % 3) + 1;
      final doc = await firestore.collection('daily_mini_games').doc('daily_mini_game_$gameIndex').get();
      if (doc.exists) {
        final data = doc.data()!;
        final qList = List<Map<String, dynamic>>.from(
          (data['questions'] as List).map((q) => Map<String, dynamic>.from(q)),
        );
        setState(() {
          _questions = qList;
          _isLoading = false;
        });
      } else {
        // Fallback dummy questions if not seeded
        setState(() {
          _questions = [
            {'word': 'hello', 'meaning': 'merhaba', 'isCorrect': true},
            {'word': 'red', 'meaning': 'mavi', 'isCorrect': false},
            {'word': 'water', 'meaning': 'su', 'isCorrect': true},
            {'word': 'book', 'meaning': 'kitap', 'isCorrect': true},
            {'word': 'milk', 'meaning': 'kahve', 'isCorrect': false},
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to local questions if Firestore load fails (e.g. permission denied on live server)
      setState(() {
        _questions = [
          {'word': 'hello', 'meaning': 'merhaba', 'isCorrect': true},
          {'word': 'red', 'meaning': 'mavi', 'isCorrect': false},
          {'word': 'water', 'meaning': 'su', 'isCorrect': true},
          {'word': 'book', 'meaning': 'kitap', 'isCorrect': true},
          {'word': 'milk', 'meaning': 'kahve', 'isCorrect': false},
        ];
        _isLoading = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final threshold = 120.0;
    if (_dragOffset.dx > threshold) {
      // Swiped Right -> User answers TRUE
      _evaluateAnswer(true);
    } else if (_dragOffset.dx < -threshold) {
      // Swiped Left -> User answers FALSE
      _evaluateAnswer(false);
    } else {
      // Snap back
      _swipeAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack),
      );
      _swipeController.forward(from: 0.0).then((_) {
        setState(() {
          _dragOffset = Offset.zero;
        });
      });
    }
  }

  void _evaluateAnswer(bool userSelection) {
    final currentQ = _questions[_currentIndex];
    final bool isCorrect = currentQ['isCorrect'] ?? false;
    final bool gotItRight = userSelection == isCorrect;

    if (gotItRight) {
      _correctCount++;
    }

    // Determine target throw offset (Right for true selection, Left for false selection)
    final targetOffset = userSelection ? const Offset(500, 0) : const Offset(-500, 0);

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    _swipeController.forward(from: 0.0).then((_) {
      _swipeController.reset();
      setState(() {
        _dragOffset = Offset.zero;
        if (_currentIndex < _questions.length - 1) {
          _currentIndex++;
        } else {
          _isFinished = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          // Glowing background blobs using RadialGradient (fully compatible with GLES Impeller)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.20),
                    const Color(0xFF6366F1).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD946EF).withOpacity(0.14),
                    const Color(0xFFD946EF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -140,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.10),
                    const Color(0xFF06B6D4).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withOpacity(0.08),
                    AppColors.accentGold.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Günlük Kelime Oyunu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance back button
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  )
                else if (_questions.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.white.withOpacity(0.4), size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Oyun Yüklenemedi',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sorular veritabanından alınamadı.\nLütfen internet bağlantınızı kontrol edin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                              });
                              _loadGame();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isFinished)
                  Expanded(child: _buildFinishedView())
                else
                  Expanded(child: _buildGameView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    final progress = (_currentIndex + 1) / _questions.length;
    final topQuestion = _questions[_currentIndex];

    // Calculate rotation angle based on drag distance
    final double rotationAngle = (_dragOffset.dx / 300).clamp(-0.2, 0.2);

    return Column(
      children: [
        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Text(
                      'Soru ${_currentIndex + 1} / ${_questions.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Doğru: $_correctCount',
                          style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: AppColors.accentGold,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),

        // Swipe Cards Stack
        Center(
          child: SizedBox(
            width: 320,
            height: 400,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Underneath Card (next card teaser)
                if (_currentIndex < _questions.length - 1)
                  Transform.scale(
                    scale: 0.95,
                    child: Transform.translate(
                      offset: const Offset(0, 15),
                      child: _buildBaseCard(_questions[_currentIndex + 1], isTop: false),
                    ),
                  ),

                // Top Interactive Card
                GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: AnimatedBuilder(
                    animation: _swipeController,
                    builder: (context, child) {
                      final currentOffset = _swipeController.isAnimating ? _swipeAnimation.value : _dragOffset;
                      final currentRotation = _swipeController.isAnimating ? (currentOffset.dx / 300).clamp(-0.2, 0.2) : rotationAngle;

                      return Transform.translate(
                        offset: currentOffset,
                        child: Transform.rotate(
                          angle: currentRotation,
                          child: _buildBaseCard(topQuestion, isTop: true),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Swipe Help Indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHelpIndicator(
                icon: Icons.close_rounded,
                label: 'Yanlış (Sola)',
                color: Colors.redAccent,
                onTap: () => _evaluateAnswer(false),
              ),
              _buildHelpIndicator(
                icon: Icons.done_rounded,
                label: 'Doğru (Sağa)',
                color: const Color(0xFF39D2C0),
                onTap: () => _evaluateAnswer(true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBaseCard(Map<String, dynamic> q, {required bool isTop}) {
    final word = q['word'] ?? '';
    final meaning = q['meaning'] ?? '';

    // Swipe hint overlays (only visible on top card during drag)
    final dragX = _dragOffset.dx;
    double greenOpacity = 0.0;
    double redOpacity = 0.0;
    if (isTop) {
      if (dragX > 0) {
        greenOpacity = (dragX / 150).clamp(0.0, 0.85);
      } else {
        redOpacity = (-dragX / 150).clamp(0.0, 0.85);
      }
    }

    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B).withOpacity(0.85),
            const Color(0xFF0F172A).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            // Card Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    word.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Text(
                      'EŞLEŞİYOR MU?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: AppColors.accentGold.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Correct/Green Overlay
            if (isTop && greenOpacity > 0.0)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF10B981).withOpacity(greenOpacity),
                  child: greenOpacity > 0.15
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white.withOpacity(greenOpacity.clamp(0.0, 1.0)),
                                size: 80,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'DOĞRU',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(greenOpacity.clamp(0.0, 1.0)),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),

            // Incorrect/Red Overlay
            if (isTop && redOpacity > 0.0)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFEF4444).withOpacity(redOpacity),
                  child: redOpacity > 0.15
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Colors.white.withOpacity(redOpacity.clamp(0.0, 1.0)),
                                size: 80,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'YANLIŞ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(redOpacity.clamp(0.0, 1.0)),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpIndicator({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedView() {
    final reward = _correctCount * 5;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentGold,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tebrikler!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugünün kelime oyununu başarıyla tamamladın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.85),
                    const Color(0xFF0F172A).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Skor: $_correctCount / ${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          '+$reward Jeton',
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            shadows: [
                              Shadow(
                                color: AppColors.accentGold,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    setState(() => _isSaving = true);
                    try {
                      await ref
                          .read(firebaseServiceProvider)
                          .completeDailyMiniGame(widget.uid, reward);
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : const Text(
                          'Ödülü Al ve Kapat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
