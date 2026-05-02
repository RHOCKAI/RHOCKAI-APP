import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/l10n/app_localizations.dart';
import 'dart:math' as math;

import '../../camera_ai/session/session_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'widgets/accuracy_ring_widget.dart';
import 'controllers/share_card_controller.dart';

class ResultsShareScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final int streak;

  const ResultsShareScreen({
    super.key,
    required this.session,
    required this.streak,
  });

  @override
  ConsumerState<ResultsShareScreen> createState() => _ResultsShareScreenState();
}

class _ResultsShareScreenState extends ConsumerState<ResultsShareScreen>
    with TickerProviderStateMixin {
  final GlobalKey _squareCardKey = GlobalKey();
  final GlobalKey _storyCardKey = GlobalKey();
  final ShareCardController _controller = ShareCardController();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  bool _showWatermark = true;
  int _currentFormatIndex = 0; // 0: Square, 1: Story

  // Animation Controllers
  late AnimationController _slideUpController;
  late AnimationController _staggerController;
  late Animation<Offset> _slideUpAnimation;

  @override
  void initState() {
    super.initState();
    _loadPreference();

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideUpController,
      curve: Curves.easeOutCubic,
    ));

    _slideUpController.forward();
    _staggerController.forward();
  }

  Future<void> _loadPreference() async {
    final pref = await _controller.getWatermarkPreference();
    setState(() => _showWatermark = pref);
  }

  @override
  void dispose() {
    _slideUpController.dispose();
    _staggerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleShare() async {
    final key = _currentFormatIndex == 0 ? _squareCardKey : _storyCardKey;
    await _controller.shareCard(
      repaintKey: key,
      exercise: widget.session.exerciseType,
      reps: widget.session.totalReps,
      accuracy: widget.session.averageAccuracy,
      streak: widget.streak,
      watermarkVisible: _showWatermark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.shareWorkout.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Rajdhani',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SlideTransition(
              position: _slideUpAnimation,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentFormatIndex = index),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCardPreview(
                    key: _squareCardKey,
                    aspectRatio: 1.0,
                    isStory: false,
                    user: user,
                    l10n: l10n,
                  ),
                  _buildCardPreview(
                    key: _storyCardKey,
                    aspectRatio: 9 / 16,
                    isStory: true,
                    user: user,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ),
          _buildBottomPanel(l10n),
        ],
      ),
    );
  }

  Widget _buildCardPreview({
    required GlobalKey key,
    required double aspectRatio,
    required bool isStory,
    required Map<String, dynamic>? user,
    required AppLocalizations l10n,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: RepaintBoundary(
            key: key,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B5EA7).withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Background Particle Effect (Subtle)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(progress: _staggerController.value),
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(isStory ? 40 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(user, l10n),
                        const Spacer(),
                        _buildStatsGrid(l10n),
                        const Spacer(),
                        if (_showWatermark) _buildWatermark(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user, AppLocalizations l10n) {
    final userName = user?['full_name']?.split(' ')[0] ?? 'Champ';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.greatSession(userName).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Today · ${widget.session.exerciseType.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF7B5EA7),
          child: Text(
            userName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem(l10n.repsLabel, '${widget.session.totalReps}', Icons.bolt, 0)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  AccuracyRingWidget(
                    accuracy: widget.session.averageAccuracy,
                    size: 100,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getAccuracyTone(widget.session.averageAccuracy, l10n),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(child: _buildStatItem(l10n.kcal, '${widget.session.caloriesBurned}', Icons.local_fire_department, 2)),
            const SizedBox(width: 20),
            Expanded(child: _buildStatItem('STREAK', '🔥 ${widget.streak} DAYS', Icons.calendar_today, 3)),
          ],
        ),
      ],
    );
  }

  String _getAccuracyTone(double accuracy, AppLocalizations l10n) {
    if (accuracy >= 81) return l10n.eliteForm;
    if (accuracy >= 61) return l10n.solidSession;
    if (accuracy >= 50) return l10n.keepPushing;
    return l10n.formInProgress;
  }

  Widget _buildStatItem(String label, String value, IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7B5EA7), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Rajdhani',
            ),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermark() {
    return AnimatedOpacity(
      opacity: _showWatermark ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF00D9FF), size: 14),
              const SizedBox(width: 8),
              Text(
                'RHOCKAI · AI-POWERED FORM TRAINING',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFormatToggle(),
              _buildWatermarkToggle(l10n),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _handleShare,
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'SHARE TO PLATFORM',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontFamily: 'Rajdhani'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5EA7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.savedToHistory,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItem('SQUARE', _currentFormatIndex == 0, () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
          _buildToggleItem('STORY', _currentFormatIndex == 1, () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7B5EA7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWatermarkToggle(AppLocalizations l10n) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l10n.showRhockaiBadge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(l10n.helpOthersDiscover, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: _showWatermark,
          activeColor: const Color(0xFF00D9FF),
          onChanged: (val) {
            setState(() => _showWatermark = val);
            _controller.saveWatermarkPreference(val);
          },
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7B5EA7).withOpacity(0.05);
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + (progress * 50)) % size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 3 + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
