import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../camera_ai/session/session_model.dart';
import '../repositories/session_repository.dart';

final sessionRepositoryProvider = Provider((ref) => SessionRepository());

final workoutHistoryProvider =
    FutureProvider.family<List<WorkoutSession>, int>((ref, limit) async {
  final repository = ref.watch(sessionRepositoryProvider);
  return repository.getSessions(limit: limit);
});
