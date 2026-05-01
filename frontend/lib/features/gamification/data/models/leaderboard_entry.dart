class LeaderboardEntry {
  final int userId;
  final String? fullName;
  final double totalScore;
  final int sessionsCompleted;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    this.fullName,
    required this.totalScore,
    required this.sessionsCompleted,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String?,
      totalScore: (json['total_score'] as num).toDouble(),
      sessionsCompleted: json['sessions_completed'] as int,
      rank: json['rank'] as int,
    );
  }
}
