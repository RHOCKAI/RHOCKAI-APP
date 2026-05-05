import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_stats.dart';
import '../data/models/leaderboard_entry.dart';
import '../data/repositories/gamification_repository.dart';
import '../../../core/providers/api_client_provider.dart';

final gamificationRepositoryProvider = Provider((ref) => GamificationRepository());

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getUserStats();
});

final dailyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return repo.getDailyLeaderboard(apiClient);
});
