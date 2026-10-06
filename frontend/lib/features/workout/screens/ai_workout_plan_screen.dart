import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/core/config/app_theme.dart';
import 'package:rhockai/features/camera_ai/camera_ai_screen.dart';
import '../data/repositories/ai_workout_plan_repository.dart';

class AIWorkoutPlanScreen extends ConsumerStatefulWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  ConsumerState<AIWorkoutPlanScreen> createState() =>
      _AIWorkoutPlanScreenState();
}

class _AIWorkoutPlanScreenState extends ConsumerState<AIWorkoutPlanScreen> {
  int? _adaptingExerciseId;

  Future<void> _adaptExercise(PlannedExercise exercise) async {
    setState(() => _adaptingExerciseId = exercise.id);
    try {
      await ref
          .read(aiWorkoutPlanRepositoryProvider)
          .adaptExercise(exercise.id);
      ref.invalidate(aiWorkoutPlanProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not adapt exercise: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _adaptingExerciseId = null);
    }
  }

  Future<void> _startExercise(PlannedExercise exercise) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraAIScreen(
          exerciseType: exercise.exerciseType,
          targetReps: exercise.reps,
          targetSets: exercise.sets,
          onWorkoutCompleted: () => ref
              .read(aiWorkoutPlanRepositoryProvider)
              .completeExercise(exercise.id),
        ),
      ),
    );
    if (mounted) ref.invalidate(aiWorkoutPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(aiWorkoutPlanProvider);
    final plan =
        planAsync.maybeWhen(data: (value) => value, orElse: () => null);
    final nextExercise = plan?.nextExercise;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MY AI PLAN',
            style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40),
                const SizedBox(height: 12),
                Text('Unable to load your plan. $error',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(aiWorkoutPlanProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () => ref.refresh(aiWorkoutPlanProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              _buildPlanHeader(value),
              const SizedBox(height: 24),
              Text(
                "TODAY'S WORKOUT",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              if (value.exercises.isEmpty)
                const Text('No exercises are available for this workout yet.'),
              for (var index = 0; index < value.exercises.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildExerciseCard(value.exercises[index], index),
                ),
              if (nextExercise == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Workout complete')),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: nextExercise == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startExercise(nextExercise),
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START NEXT EXERCISE'),
            ),
    );
  }

  Widget _buildPlanHeader(AIWorkoutPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        image: DecorationImage(
          image: const NetworkImage(
              'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
          opacity: 0.2,
          colorFilter: ColorFilter.mode(
              AppTheme.neonBlue.withValues(alpha: 0.3), BlendMode.color),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'DAY ${plan.currentDay} • ${plan.focusArea.toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.neonBlue,
                letterSpacing: 1.5,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            plan.planName.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by Dynamic Progressive Overload',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(PlannedExercise exercise, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: exercise.isSubstituted
                ? AppTheme.neonGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rajdhani',
                      ),
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
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${exercise.sets} SETS × ${exercise.reps} REPS ${exercise.targetWeightKg != null ? '• ${exercise.targetWeightKg} KG' : ''}",
                        style: const TextStyle(
                          color: AppTheme.neonBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: exercise.isCompleted || _adaptingExerciseId != null
                      ? null
                      : () => _adaptExercise(exercise),
                  icon: _adaptingExerciseId == exercise.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz_rounded,
                          color: Colors.white54),
                  tooltip: 'Adapt Equipment',
                ),
              ],
            ),
          ),

          // AI Notes Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: exercise.isSubstituted
                  ? AppTheme.neonGreen.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  exercise.isSubstituted
                      ? Icons.check_circle_outline_rounded
                      : Icons.psychology_rounded,
                  color: exercise.isSubstituted
                      ? AppTheme.neonGreen
                      : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.isSubstituted
                        ? "Adapted from ${exercise.originalExercise ?? 'another exercise'}"
                        : exercise.aiNote,
                    style: TextStyle(
                      color: exercise.isSubstituted
                          ? AppTheme.neonGreen
                          : Colors.white54,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
