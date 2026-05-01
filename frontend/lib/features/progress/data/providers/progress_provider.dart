import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';

final progressRepositoryProvider = Provider((ref) => ProgressRepository());

final statsProvider =
    FutureProvider.family<SessionStats, int>((ref, days) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getStats(days: days);
});

final progressChartProvider =
    FutureProvider.family<List<ProgressData>, int>((ref, days) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getProgress(days: days);
});
