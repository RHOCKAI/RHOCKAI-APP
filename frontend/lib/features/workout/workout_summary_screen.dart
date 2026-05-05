import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import '../camera_ai/session/session_model.dart';
import '../gamification/data/repositories/gamification_repository.dart';
import '../../core/services/health_service.dart';
import '../workout/share/results_share_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSession session;
  final bool isDemo;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    this.isDemo = false,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  int _streak = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _loadStreak();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStreak() async {
    final repo = GamificationRepository();
    final stats = await repo.getUserStats();
    if (mounted) {
      setState(() {
        _streak = stats.currentStreak;
      });
    }

    if (!widget.isDemo) {
      await HealthService().initialize();
      await HealthService().saveWorkout(
        exerciseName: widget.session.exerciseType,
        caloriesBurned: widget.session.caloriesBurned.toDouble(),
        startTime: widget.session.startTime,
        endTime: widget.session.endTime ?? DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('PERFORMANCE ANALYSIS', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w900, letterSpacing: 2)),
        automaticallyImplyLeading: false,
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryHero(),
                  const SizedBox(height: 24),
                  
                  // GRID STATS
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricCard('TOTAL REPS', '${widget.session.totalReps}', 'COUNT', Icons.bolt_rounded, AppTheme.neonBlue),
                      _buildMetricCard('ACCURACY', '${widget.session.averageAccuracy.toInt()}%', 'QUALITY', Icons.verified_user_rounded, AppTheme.neonGreen),
                      _buildMetricCard('TEMPO', '${widget.session.averageTempoScore.toInt()}', 'RHYTHM', Icons.speed_rounded, Colors.orangeAccent),
                      _buildMetricCard('CALORIES', '${widget.session.caloriesBurned}', 'BURN', Icons.local_fire_department_rounded, AppTheme.neonOrange),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // EXERCISE INFO CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(context),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.neonBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: AppTheme.neonBlue),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.exerciseType.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Rajdhani',
                                  letterSpacing: 1,
                                ),
                              ),
                              const Text(
                                'Daily AI Session Completed',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_streak 🔥',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'STREAK',
                              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _shareScorecard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    
                  const SizedBox(height: 40),
                  
                  TextButton(
                    onPressed: () {
                      if (widget.isDemo) {
                        Navigator.pushReplacementNamed(context, '/');
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      widget.isDemo ? 'SIGN UP TO SAVE PROGRESS' : 'RETURN TO DASHBOARD',
                      style: const TextStyle(
                        color: Colors.white24,
                        letterSpacing: 2,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // fall down
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
            Colors.purpleAccent
          ],
        ),
      ],
    ),
  ),
);
  }

  Widget _buildSummaryHero() {
    final double powerScore = (widget.session.totalReps * widget.session.averageAccuracy / 100);
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
                  value: powerScore / 500, // Arbitrary normalization for 500 as "perfect"
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
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

  Widget _buildMetricCard(String label, String value, String subtitle, IconData icon, Color color) {
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

  void _shareScorecard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsShareScreen(
          session: widget.session,
          streak: _streak,
        ),
      ),
    );
  }

  Future<void> _shareVideo(BuildContext context) async {
    if (widget.session.videoUrl == null) {
      return;
    }

    final text = 'Check out my ${widget.session.exerciseType} form on Rhockai! Accuracy: ${widget.session.averageAccuracy.toStringAsFixed(1)}% | Reps: ${widget.session.totalReps}';
    
    await SharePlus.instance.share(ShareParams(
      files: [XFile(widget.session.videoUrl!)],
      text: text,
    ));
  }
}

