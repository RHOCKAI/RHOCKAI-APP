class FitnessRatingUpdateResponse {
  final int previousRating;
  final int newRating;
  final bool levelChanged;
  final String newLevel;

  FitnessRatingUpdateResponse({
    required this.previousRating,
    required this.newRating,
    required this.levelChanged,
    required this.newLevel,
  });

  factory FitnessRatingUpdateResponse.fromJson(Map<String, dynamic> json) {
    return FitnessRatingUpdateResponse(
      previousRating: json['previous_rating'] as int,
      newRating: json['new_rating'] as int,
      levelChanged: json['level_changed'] as bool,
      newLevel: json['new_level'] as String,
    );
  }
}
