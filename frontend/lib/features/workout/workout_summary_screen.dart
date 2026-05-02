import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../camera_ai/session/session_model.dart';
import '../gamification/data/repositories/gamification_repository.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const Text(
                'WORKOUT COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.greenAccent,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 30),
              
              // THE SCORECARD
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                    children: [
                      const Text(
                        'RHOCKAI PERFORMANCE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // COMBINED POWER SCORE (Quantity x Quality)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: (widget.session.totalReps * widget.session.averageAccuracy) / 10000, // Normalized for gauge
                              strokeWidth: 12,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (widget.session.totalReps * widget.session.averageAccuracy / 100).toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'POWER SCORE',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // THE DUAL PILLARS: QUANTITY & QUALITY
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalancedStat(
                              'QUANTITY', 
                              '${widget.session.totalReps}', 
                              'REPS', 
                              Icons.bolt,
                            ),
                          ),
                          Container(width: 1, height: 50, color: Colors.white10),
                          Expanded(
                            child: _buildBalancedStat(
                              'QUALITY', 
                              '${widget.session.averageAccuracy.toStringAsFixed(0)}%', 
                              'ACCURACY', 
                              Icons.verified_user,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // SECONDARY STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildScorecardStat('TEMPO', widget.session.averageTempoScore.toStringAsFixed(0)),
                          _buildScorecardStat('KCALS', '${widget.session.caloriesBurned}'),
                          _buildScorecardStat('STREAK', '$_streak 🔥'),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.session.exerciseType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                onPressed: _shareScorecard,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('SHARE PERFORMANCE SCORECARD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (widget.session.videoUrl != null)
                TextButton.icon(
                  onPressed: () => _shareVideo(context),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Share Video Instead'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
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
                  widget.isDemo ? 'SIGN UP TO SAVE PROGRESS' : 'BACK TO DASHBOARD',
                  style: const TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
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

  Widget _buildBalancedStat(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScorecardStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
    if (widget.session.videoUrl == null) return;

    final text = 'Check out my ${widget.session.exerciseType} form on Rhockai! Accuracy: ${widget.session.averageAccuracy.toStringAsFixed(1)}% | Reps: ${widget.session.totalReps}';
    
    await Share.shareXFiles([XFile(widget.session.videoUrl!)], text: text);
  }
}

