import 'package:flutter/material.dart';
import '../../../core/constants/exercises.dart';
import '../../../core/config/app_theme.dart';
import '../../camera_ai/camera_ai_screen.dart';

class DailyCircuitScreen extends StatefulWidget {
  const DailyCircuitScreen({super.key});

  @override
  State<DailyCircuitScreen> createState() => _DailyCircuitScreenState();
}

class _DailyCircuitScreenState extends State<DailyCircuitScreen> {
  late List<ExerciseData> _circuit;

  @override
  void initState() {
    super.initState();
    _generateCircuit();
  }

  void _generateCircuit() {
    // Generate a simple 4-exercise full body circuit
    final all = Exercises.allExercises.toList();
    all.shuffle();
    _circuit = [
      all.firstWhere((e) => e.category == 'upper_body' || e.muscleGroups.contains('chest')),
      all.firstWhere((e) => e.category == 'lower_body'),
      all.firstWhere((e) => e.category == 'core'),
      all.firstWhere((e) => e.category == 'full_body' || e.id == 'burpee'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('AI Daily Circuit', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR PERSONALIZED PLAN',
                  style: TextStyle(color: AppTheme.neonBlue, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on your goals and fitness level, we built this 4-exercise full-body circuit to maximize results.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTag(Icons.timer, '15 Min'),
                    const SizedBox(width: 8),
                    _buildTag(Icons.local_fire_department, '~150 kcal'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _circuit.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final exercise = _circuit[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2749),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(exercise.imageUrl),
                            fit: BoxFit.cover,
                            opacity: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Rajdhani',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.defaultSets} Sets × ${exercise.defaultReps} Reps',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: AppTheme.neonBlue, size: 36),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraAIScreen(exerciseType: exercise.id),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neonBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.neonBlue),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.neonBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
