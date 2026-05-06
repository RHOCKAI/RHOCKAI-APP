import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../camera_ai/session/session_provider.dart';
import '../../../core/constants/exercises.dart';

final fatigueProvider = Provider<Map<String, double>>((ref) {
  final sessionsAsync = ref.watch(allSessionsProvider);

  return sessionsAsync.maybeWhen(
    data: (sessions) {
      final Map<String, double> fatigue = {};
      final now = DateTime.now();

      for (final session in sessions) {
        final hoursAgo = now.difference(session.startTime).inHours;

        // Only count last 24h for "active" fatigue
        if (hoursAgo >= 24) {
          continue;
        }

        final exercise = Exercises.getById(session.exerciseType);
        if (exercise == null) {
          continue;
        }

        // Decay factor: Fatigue is 100% at 0h ago, and decays to 0% at 24h ago
        final decay = (24 - hoursAgo) / 24.0;

        // A "standard" set of 10-15 reps adds about 0.2 (20%) fatigue to targeted muscles
        final repIntensity = 0.015;

        for (final muscle in exercise.muscleGroups) {
          final m = muscle.toLowerCase();
          final contribution = (session.totalReps * repIntensity) * decay;
          fatigue[m] = (fatigue[m] ?? 0.0) + contribution;
        }
      }

      // Normalize and cap at 1.0
      fatigue.updateAll((key, value) => value > 1.0 ? 1.0 : value);

      // Mapping some exercise specific terms to common heatmap groups
      if (fatigue.containsKey('abs')) {
        fatigue['core'] = (fatigue['core'] ?? 0.0) + (fatigue['abs'] ?? 0.0);
      }
      if (fatigue.containsKey('inner thighs')) {
        fatigue['quads'] =
            (fatigue['quads'] ?? 0.0) + (fatigue['inner thighs'] ?? 0.0);
      }

      return fatigue;
    },
    orElse: () => {},
  );
});
