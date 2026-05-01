class ExerciseThresholds {
  // Push-up thresholds
  static const double pushupDownAngle = 90.0;  // Elbow at 90°
  static const double pushupUpAngle = 160.0;   // Elbow almost straight
  
  // Squat thresholds
  static const double squatDownAngle = 90.0;   // Knee at 90°
  static const double squatUpAngle = 170.0;    // Knee almost straight
  
  // Plank thresholds
  static const double plankHipAngle = 180.0;   // Straight line
  static const double plankTolerance = 10.0;   // ±10° tolerance
  
  // Form accuracy thresholds
  static const double goodFormThreshold = 80.0;
  static const double excellentFormThreshold = 90.0;
  
  // Rep timing
  static const Duration minRepDuration = Duration(milliseconds: 800);
  static const Duration maxRepDuration = Duration(seconds: 5);
}
