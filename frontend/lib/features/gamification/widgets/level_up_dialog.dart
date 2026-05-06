import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Shown when the user levels up after a workout
class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final String rankTitle;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.rankTitle,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scale;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4))
      ..play();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _scale, curve: Curves.elasticOut);
    _scale.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: pi / 2,
          maxBlastForce: 8,
          minBlastForce: 3,
          emissionFrequency: 0.06,
          numberOfParticles: 60,
          gravity: 0.15,
          colors: const [
            Color(0xFF00D9FF),
            Color(0xFF00FF88),
            Colors.amber,
            Colors.pinkAccent,
            Colors.purpleAccent,
          ],
        ),
        // Dialog
        Dialog(
          backgroundColor: Colors.transparent,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF141B38), Color(0xFF0D1226)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF00FF88)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00D9FF),
                      letterSpacing: 4,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LEVEL ${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Rajdhani',
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      widget.rankTitle,
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        fontSize: 12,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep pushing. The grind is working.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'LET\'S GO!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'Rajdhani',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
