import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import '../camera_ai/session/session_model.dart';
import '../gamification/data/models/user_stats.dart';
import '../gamification/providers/gamification_provider.dart';
import '../gamification/widgets/xp_gained_overlay.dart';
import '../gamification/widgets/level_up_dialog.dart';
import '../../core/services/health_service.dart';
import '../workout/share/results_share_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final bool isDemo;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    this.isDemo = false,
  });

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  DifficultyFeedback? _selectedFeedback;
  bool _feedbackSubmitted = false;

  int _xpGained = 0;
  int _newStreak = 0;
  int _newLevel = 1;
  bool _showXpOverlay = false;

  UserStats _stats = const UserStats();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3))..play();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.isDemo) {
        await HealthService().initialize();
        await HealthService().saveWorkout(
          exerciseName: widget.session.exerciseType,
          caloriesBurned: widget.session.caloriesBurned.toDouble(),
          startTime: widget.session.startTime,
          endTime: widget.session.endTime ?? DateTime.now(),
        );
      }

      // Record workout WITHOUT feedback first so streak/XP show immediately
      await _recordWorkout(feedback: null);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _recordWorkout({DifficultyFeedback? feedback}) async {
    if (widget.isDemo) {
      return;
    }
    final result = await ref
        .read(gamificationProvider.notifier)
        .recordWorkout(session: widget.session, feedback: feedback);

    if (!mounted) {
      return;
    }
    setState(() {
      _xpGained = result.xpGained;
      _newStreak = result.newStreak;
      _newLevel = result.newLevel;
      _stats = result.updatedStats;
      _showXpOverlay = true;
    });

    if (result.leveledUp) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => LevelUpDialog(
            newLevel: result.newLevel,
            rankTitle: result.updatedStats.rankTitle,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback(DifficultyFeedback feedback) async {
    if (_feedbackSubmitted) {
      return;
    }
    setState(() {
      _selectedFeedback = feedback;
      _feedbackSubmitted = true;
    });

    // Re-record with feedback to adjust difficulty modifier + add bonus XP
    await _recordWorkout(feedback: feedback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'PERFORMANCE ANALYSIS',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryHero(),
                  const SizedBox(height: 20),

                  // ── XP + Streak Bar ──────────────────────────────
                  _buildXPStreakBar(),
                  const SizedBox(height: 20),

                  // ── Stats Grid ───────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricCard(
                          'TOTAL REPS',
                          '${widget.session.totalReps}',
                          'COUNT',
                          Icons.bolt_rounded,
                          AppTheme.neonBlue),
                      _buildMetricCard(
                          'ACCURACY',
                          '${widget.session.averageAccuracy.toInt()}%',
                          'QUALITY',
                          Icons.verified_user_rounded,
                          AppTheme.neonGreen),
                      _buildMetricCard(
                          'TEMPO',
                          '${widget.session.averageTempoScore.toInt()}',
                          'RHYTHM',
                          Icons.speed_rounded,
                          Colors.orangeAccent),
                      _buildMetricCard(
                          'CALORIES',
                          '${widget.session.caloriesBurned}',
                          'BURN',
                          Icons.local_fire_department_rounded,
                          AppTheme.neonOrange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Difficulty Feedback ──────────────────────────
                  _buildFeedbackSection(),
                  const SizedBox(height: 24),

                  // ── Level Progress ───────────────────────────────
                  _buildLevelProgress(),
                  const SizedBox(height: 24),

                  // ── Share Button ─────────────────────────────────
                  ElevatedButton(
                    onPressed: _shareScorecard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'GENERATE SHARE CARD',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontFamily: 'Rajdhani',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (widget.session.videoUrl != null)
                    TextButton.icon(
                      onPressed: () => _shareVideo(context),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Share Raw AI Video'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white38,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      if (widget.isDemo) {
                        Navigator.pushReplacementNamed(context, '/');
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      widget.isDemo
                          ? 'SIGN UP TO SAVE PROGRESS'
                          : 'RETURN TO DASHBOARD',
                      style: const TextStyle(
                        color: Colors.white24,
                        letterSpacing: 2,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Confetti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.greenAccent,
                Colors.blueAccent,
                Colors.pinkAccent,
                Colors.orangeAccent,
                Colors.purpleAccent,
              ],
            ),

            // Floating XP Badge
            if (_showXpOverlay)
              Positioned(
                top: 80,
                child: XpGainedOverlay(
                  xp: _xpGained,
                  onDone: () {
                    if (mounted) {
                      setState(() => _showXpOverlay = false);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Power Score ─────────────────────────────────────────────────────
  Widget _buildSummaryHero() {
    final double powerScore =
        (widget.session.totalReps * widget.session.averageAccuracy / 100);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: (powerScore / 500).clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    powerScore.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  const Text(
                    'POWER SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.neonGreen,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── XP + Streak Bar ──────────────────────────────────────────────────────
  Widget _buildXPStreakBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // XP Gained
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Color(0xFF00D9FF), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '+$_xpGained XP EARNED',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 1,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Level $_newLevel · ${_stats.rankTitle}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$_newStreak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        fontSize: 22,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'STREAK',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Difficulty Feedback ──────────────────────────────────────────────────
  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded,
                  color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'HOW DID THAT FEEL?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your AI coach will adapt your next workout based on this.',
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeedbackButton(
                feedback: DifficultyFeedback.tooHard,
                label: 'Struggled',
                emoji: '😅',
                color: AppTheme.neonOrange,
              ),
              const SizedBox(width: 8),
              _buildFeedbackButton(
                feedback: DifficultyFeedback.perfect,
                label: 'Perfect',
                emoji: '💯',
                color: AppTheme.neonGreen,
              ),
              const SizedBox(width: 8),
              _buildFeedbackButton(
                feedback: DifficultyFeedback.tooEasy,
                label: 'Too Easy',
                emoji: '⚡',
                color: AppTheme.neonBlue,
              ),
            ],
          ),
          if (_feedbackSubmitted && _selectedFeedback != null) ...[
            const SizedBox(height: 14),
            _buildFeedbackResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackButton({
    required DifficultyFeedback feedback,
    required String label,
    required String emoji,
    required Color color,
  }) {
    final isSelected = _selectedFeedback == feedback;
    final isDisabled = _feedbackSubmitted && !isSelected;
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : () => _submitFeedback(feedback),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.white.withValues(alpha: isDisabled ? 0.04 : 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Colors.white.withValues(alpha: isDisabled ? 0.3 : 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackResult() {
    final feedback = _selectedFeedback!;
    String message;
    Color color;
    IconData icon;

    switch (feedback) {
      case DifficultyFeedback.tooHard:
        message = 'Got it! Next session will be slightly easier. +10 XP courage bonus!';
        color = AppTheme.neonOrange;
        icon = Icons.trending_down_rounded;
        break;
      case DifficultyFeedback.perfect:
        message = 'Dialled in! Keeping this intensity. +5 XP consistency bonus!';
        color = AppTheme.neonGreen;
        icon = Icons.check_circle_rounded;
        break;
      case DifficultyFeedback.tooEasy:
        message = 'Beast mode! Ramping up your next session by 10%.';
        color = AppTheme.neonBlue;
        icon = Icons.trending_up_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Level Progress Bar ───────────────────────────────────────────────────
  Widget _buildLevelProgress() {
    final progress = _stats.levelProgress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded,
                      color: Color(0xFF00D9FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LEVEL $_newLevel · ${_stats.rankTitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '${_stats.xp} / ${_stats.xpToNextLevel} XP',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00D9FF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 ${_stats.currentStreak}-day streak',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                '${_stats.totalWorkouts} total workouts',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Metric Card ──────────────────────────────────────────────────────────
  Widget _buildMetricCard(
      String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontFamily: 'Rajdhani',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _shareScorecard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsShareScreen(
          session: widget.session,
          streak: _newStreak,
        ),
      ),
    );
  }

  Future<void> _shareVideo(BuildContext context) async {
    if (widget.session.videoUrl == null) {
      return;
    }
    final text =
        'Check out my ${widget.session.exerciseType} form on Rhockai! '
        'Accuracy: ${widget.session.averageAccuracy.toStringAsFixed(1)}% | '
        'Reps: ${widget.session.totalReps}';
    await SharePlus.instance.share(ShareParams(
      files: [XFile(widget.session.videoUrl!)],
      text: text,
    ));
  }
}
