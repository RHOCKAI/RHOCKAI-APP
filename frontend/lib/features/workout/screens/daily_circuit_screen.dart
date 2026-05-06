import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/exercises.dart';
import '../../../core/config/app_theme.dart';
import '../../camera_ai/camera_ai_screen.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/logic/adaptive_intelligence.dart';

class DailyCircuitScreen extends ConsumerStatefulWidget {
  const DailyCircuitScreen({super.key});

  @override
  ConsumerState<DailyCircuitScreen> createState() => _DailyCircuitScreenState();
}

class _DailyCircuitScreenState extends ConsumerState<DailyCircuitScreen> {
  late List<ExerciseData> _circuit;
  bool _isRegenerated = false;

  @override
  void initState() {
    super.initState();
    _generateCircuit();
  }

  void _generateCircuit() {
    final stats = ref.read(gamificationProvider).valueOrNull;
    final difficulty = stats != null
        ? AdaptiveIntelligence.recommendedDifficulty(stats)
        : 'beginner';

    // Filter exercises by recommended difficulty
    List<ExerciseData> pool;
    if (difficulty == 'advanced') {
      pool = [...Exercises.advancedExercises, ...Exercises.intermediateExercises];
    } else if (difficulty == 'intermediate') {
      pool = [...Exercises.intermediateExercises, ...Exercises.beginnerExercises];
    } else {
      pool = Exercises.beginnerExercises.toList();
    }

    pool.shuffle();

    // Build a balanced 4-exercise full-body circuit
    ExerciseData? upper;
    ExerciseData? lower;
    ExerciseData? core;
    ExerciseData? cardio;

    for (final e in pool) {
      if (upper == null && (e.category == 'upper_body')) upper = e;
      if (lower == null && e.category == 'lower_body') lower = e;
      if (core == null && e.category == 'core') core = e;
      if (cardio == null && e.category == 'full_body') cardio = e;
    }

    // Fallbacks if any slot empty
    upper ??= pool.first;
    lower ??= pool.length > 1 ? pool[1] : pool.first;
    core ??= pool.length > 2 ? pool[2] : pool.first;
    cardio ??= pool.length > 3 ? pool[3] : pool.first;

    setState(() {
      _circuit = [upper!, lower!, core!, cardio!];
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(gamificationProvider);
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'AI CIRCUIT BUILDER',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isRegenerated = !_isRegenerated);
              _generateCircuit();
            },
            tooltip: 'Regenerate circuit',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty chip
                if (stats != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: AppTheme.neonBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_rounded,
                            color: AppTheme.neonBlue, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'AI ADAPTED · ${AdaptiveIntelligence.recommendedDifficulty(stats).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.neonBlue,
                            letterSpacing: 2,
                            fontFamily: 'Rajdhani',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Based on your performance history, we\'ve built this adaptive full-body protocol.',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                // Stats row
                if (stats != null)
                  Row(
                    children: [
                      _buildTag(Icons.bolt_rounded,
                          'LVL ${stats.level}', AppTheme.neonBlue),
                      const SizedBox(width: 10),
                      _buildTag(Icons.local_fire_department_rounded,
                          '${stats.currentStreak}🔥 STREAK', Colors.orange),
                      const SizedBox(width: 10),
                      _buildTag(Icons.timer_outlined, '15 MIN', Colors.white54),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Exercise List ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _circuit.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final exercise = _circuit[index];
                final adaptedReps = stats != null
                    ? AdaptiveIntelligence.calculateNextRepGoal(stats, exercise)
                    : exercise.defaultReps;
                final adaptedSets = stats != null
                    ? AdaptiveIntelligence.calculateNextSetGoal(stats, exercise)
                    : exercise.defaultSets;
                final modifier = stats?.getDifficultyModifier(exercise.id) ?? 1.0;
                final isScaled = modifier != 1.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(context),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          exercise.imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: Colors.white10,
                            child: Center(
                              child: Text(exercise.emoji,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  exercise.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Rajdhani',
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (isScaled) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (modifier > 1.0
                                              ? AppTheme.neonBlue
                                              : AppTheme.neonOrange)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      modifier > 1.0 ? '↑ SCALED' : '↓ SCALED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: modifier > 1.0
                                            ? AppTheme.neonBlue
                                            : AppTheme.neonOrange,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$adaptedSets SETS × $adaptedReps REPS',
                              style: const TextStyle(
                                color: AppTheme.neonBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.muscleGroups
                                  .take(2)
                                  .join(' · ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white24, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CameraAIScreen(exerciseType: exercise.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Start Button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CameraAIScreen(exerciseType: _circuit.first.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'START CIRCUIT SESSION',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
