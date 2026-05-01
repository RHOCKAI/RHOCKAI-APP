import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../camera_ai/session/session_provider.dart';
import '../camera_ai/session/session_model.dart';
import '../progress/data/providers/progress_provider.dart';
import '../progress/data/models/progress_models.dart';

// 📊 Workout History Screen
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(allSessionsProvider);
    final statsAsync = ref.watch(statsProvider(30)); // Last 30 days stats

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workout History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allSessionsProvider);
            ref.invalidate(statsProvider(30));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Stats summary
              _buildStatsRow(stats),
              const SizedBox(height: 24),

              const Text(
                'RECENT SESSIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Color(0xFF6B7394),
                ),
              ),
              const SizedBox(height: 16),

              historyAsync.when(
                data: (sessions) => sessions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text('No workouts found yet!',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      )
                    : Column(
                        children: sessions
                            .map((session) => Column(
                                  children: [
                                    _buildWorkoutCard(session),
                                    const SizedBox(height: 16),
                                  ],
                                ))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                    child: Text('Error loading history: $err',
                        style: const TextStyle(color: Colors.red))),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsRow(SessionStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            'Total',
            stats.totalSessions.toString(),
            'workouts',
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            'Reps',
            stats.totalReps.toString(),
            'total',
            Icons.repeat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            'Accuracy',
            '${stats.averageAccuracy.toInt()}%',
            'avg',
            Icons.star,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
      String label, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2749).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7394)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSession session) {
    final color = _getExerciseColor(session.exerciseType);
    final durationString =
        '${session.duration.inSeconds ~/ 60}:${(session.duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.exerciseType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      DateFormat('MMM dd, h:mm a').format(session.startTime),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7394)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${session.averageAccuracy.toInt()}%',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildWorkoutStat(Icons.repeat, '${session.totalReps} its'),
              const SizedBox(width: 20),
              _buildWorkoutStat(Icons.timer, durationString),
              const SizedBox(width: 20),
              _buildWorkoutStat(
                  Icons.local_fire_department, '${session.caloriesBurned} cal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7394), size: 16),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB0B8D4))),
      ],
    );
  }

  Color _getExerciseColor(String type) {
    switch (type.toLowerCase()) {
      case 'push-ups':
        return const Color(0xFF00D9FF);
      case 'squats':
        return const Color(0xFF00FF88);
      case 'planks':
        return const Color(0xFFFF6B35);
      default:
        return Colors.purpleAccent;
    }
  }
}
