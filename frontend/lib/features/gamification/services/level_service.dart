import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_stats.dart';
import '../logic/adaptive_intelligence.dart';

final levelServiceProvider = Provider((ref) => LevelService());

class LevelService {
  /// Calculate XP earned from a workout session
  int calculateXp(int reps, double accuracy, {double tempoScore = 0.0}) {
    return AdaptiveIntelligence.calculateXPGained(reps, accuracy, tempoScore);
  }
  
  /// Update user level and XP
  UserStats addXp(UserStats currentStats, int earnedXp) {
    int newXp = currentStats.xp + earnedXp;
    int currentLevel = currentStats.level;
    
    // Check for level up
    // XP needed for next level = Level * 100
    // e.g., Level 1 -> 2 needs 100 XP
    // Level 2 -> 3 needs 200 XP
    
    int xpForNextLevel = currentLevel * 100;
    
    while (newXp >= xpForNextLevel) {
      newXp -= xpForNextLevel;
      currentLevel++;
      xpForNextLevel = currentLevel * 100;
    }
    
    return currentStats.copyWith(
      level: currentLevel,
      xp: newXp,
    );
  }
}
