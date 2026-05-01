
class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final int totalReps;
  final int level;
  final int xp;
  final DateTime? lastWorkoutDate;

  const UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.totalReps = 0,
    this.level = 1,
    this.xp = 0,
    this.lastWorkoutDate,
  });

  UserStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    int? totalReps,
    int? level,
    int? xp,
    DateTime? lastWorkoutDate,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalReps: totalReps ?? this.totalReps,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWorkouts': totalWorkouts,
      'totalReps': totalReps,
      'level': level,
      'xp': xp,
      'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalWorkouts: json['totalWorkouts'] ?? 0,
      totalReps: json['totalReps'] ?? 0,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      lastWorkoutDate: json['lastWorkoutDate'] != null
          ? DateTime.parse(json['lastWorkoutDate'])
          : null,
    );
  }

  // Helper method to calculate XP needed for next level
  // Formula: Base (100) * Level
  int get xpToNextLevel => level * 100;
  
  double get levelProgress => xp / xpToNextLevel;
}
