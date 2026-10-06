import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/core/network/api_client.dart';

class PlannedExercise {
  final int id;
  final String exerciseType;
  final String name;
  final int sets;
  final int reps;
  final int? targetWeightKg;
  final String aiNote;
  final bool isSubstituted;
  final String? originalExercise;
  final int restSeconds;
  final bool isCompleted;

  const PlannedExercise({
    required this.id,
    required this.exerciseType,
    required this.name,
    required this.sets,
    required this.reps,
    required this.targetWeightKg,
    required this.aiNote,
    required this.isSubstituted,
    required this.originalExercise,
    required this.restSeconds,
    required this.isCompleted,
  });

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      id: json['id'] as int,
      exerciseType: json['exercise_type'] as String,
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      targetWeightKg: (json['target_weight'] as num?)?.round(),
      aiNote: json['ai_note'] as String? ?? '',
      isSubstituted: json['is_substituted'] as bool? ?? false,
      originalExercise: json['original_exercise'] as String?,
      restSeconds: json['rest_seconds'] as int? ?? 60,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

class AIWorkoutPlan {
  final int planId;
  final String planName;
  final int currentDay;
  final String focusArea;
  final int scheduledWorkoutId;
  final List<PlannedExercise> exercises;

  const AIWorkoutPlan({
    required this.planId,
    required this.planName,
    required this.currentDay,
    required this.focusArea,
    required this.scheduledWorkoutId,
    required this.exercises,
  });

  factory AIWorkoutPlan.fromJson(Map<String, dynamic> json) {
    return AIWorkoutPlan(
      planId: json['plan_id'] as int,
      planName: json['plan_name'] as String,
      currentDay: json['current_day'] as int,
      focusArea: json['focus_area'] as String,
      scheduledWorkoutId: json['scheduled_workout_id'] as int,
      exercises: (json['exercises'] as List<dynamic>)
          .map((exercise) => PlannedExercise.fromJson(
                exercise as Map<String, dynamic>,
              ))
          .toList(growable: false),
    );
  }

  PlannedExercise? get nextExercise {
    for (final exercise in exercises) {
      if (!exercise.isCompleted) return exercise;
    }
    return null;
  }
}

class AIWorkoutPlanRepository {
  final ApiClient _apiClient;

  AIWorkoutPlanRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AIWorkoutPlan> getTodayPlan() async {
    final response = await _apiClient.get('/workouts/plan/today');
    return AIWorkoutPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> adaptExercise(int plannedExerciseId) async {
    await _apiClient.post('/workouts/plan/adapt/$plannedExerciseId');
  }

  Future<void> completeExercise(int plannedExerciseId) async {
    await _apiClient.post(
      '/workouts/plan/exercises/$plannedExerciseId/complete',
    );
  }
}

final aiWorkoutPlanRepositoryProvider = Provider<AIWorkoutPlanRepository>(
  (ref) => AIWorkoutPlanRepository(),
);

final aiWorkoutPlanProvider = FutureProvider<AIWorkoutPlan>((ref) {
  return ref.watch(aiWorkoutPlanRepositoryProvider).getTodayPlan();
});
