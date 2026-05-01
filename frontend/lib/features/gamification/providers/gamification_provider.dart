import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_stats.dart';
import '../data/repositories/gamification_repository.dart';

final gamificationRepositoryProvider = Provider((ref) => GamificationRepository());

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getUserStats();
});
