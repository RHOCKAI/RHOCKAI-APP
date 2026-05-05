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
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('AI CIRCUIT BUILDER', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w900, letterSpacing: 2)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'DAILY OPTIMIZATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.neonBlue,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Based on your goals and current fatigue levels, we\'ve built this 4-step protocol.',
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildTag(Icons.timer_outlined, '15 MIN'),
                    const SizedBox(width: 12),
                    _buildTag(Icons.local_fire_department_outlined, '150 KCAL'),
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
                  decoration: AppTheme.cardDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(exercise.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.defaultSets} SETS × ${exercise.defaultReps} REPS',
                              style: const TextStyle(
                                color: AppTheme.neonBlue, 
                                fontSize: 11, 
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 20),
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  // Start the first exercise in circuit
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraAIScreen(exerciseType: _circuit.first.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'START CIRCUIT SESSION', 
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Rajdhani'),
                ),
              ),
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
        color: AppTheme.neonBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3)),
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
