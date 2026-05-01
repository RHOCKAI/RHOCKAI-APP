import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_stats.dart';
import '../data/repositories/gamification_repository.dart';

final gamificationRepositoryProvider = Provider((ref) => GamificationRepository());

final streakServiceProvider = Provider((ref) {
  return StreakService(ref.watch(gamificationRepositoryProvider));
});

class StreakService {
  final GamificationRepository _repository;

  StreakService(this._repository);

  /// Check if streak should be updated based on new workout
  Future<UserStats> updateStreakAfterWorkout(UserStats currentStats) async {
    final now = DateTime.now();
    final lastWorkout = currentStats.lastWorkoutDate;
    
    int newStreak = currentStats.currentStreak;
    
    if (lastWorkout == null) {
      // First ever workout
      newStreak = 1;
    } else {
      final difference = _daysBetween(lastWorkout, now);
      
      if (difference == 0) {
        // Same day, streak doesn't change
        newStreak = currentStats.currentStreak;
      } else if (difference == 1) {
        // Consecutive day, increment streak
        newStreak = currentStats.currentStreak + 1;
      } else {
        // Missed a day or more, reset streak to 1 (today counts)
        newStreak = 1;
      }
    }
    
    // Update longest streak
    final newLongest = newStreak > currentStats.longestStreak 
        ? newStreak 
        : currentStats.longestStreak;
        
    final newStats = currentStats.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastWorkoutDate: now,
      totalWorkouts: currentStats.totalWorkouts + 1,
    );
    
    await _repository.saveUserStats(newStats);
    return newStats;
  }
  
  /// Calculate days between two dates, ignoring time
  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}
