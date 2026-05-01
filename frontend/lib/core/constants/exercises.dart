/// Exercise angle thresholds and configuration
class ExerciseThresholds {
  // Push-up thresholds (elbow angle)
  static const double pushupDownAngle = 90.0; // Elbow bent at 90°
  static const double pushupUpAngle = 160.0; // Elbow almost straight

  // Squat thresholds (knee angle)
  static const double squatDownAngle = 90.0; // Knee bent at 90°
  static const double squatUpAngle = 170.0; // Knee almost straight

  // Plank thresholds (hip angle)
  static const double plankHipAngle = 180.0; // Straight line
  static const double plankTolerance = 15.0; // ±15° tolerance

  // Form accuracy thresholds
  static const double goodFormThreshold = 70.0;
  static const double excellentFormThreshold = 90.0;

  // Rep timing constraints
  static const int minRepDurationMs = 800; // Min time per rep (ms)
  static const int maxRepDurationMs = 5000; // Max time per rep (ms)

  // Detection confidence
  static const double minLandmarkConfidence = 0.5;

  // Angle tolerances for form checking
  static const double backStraightTolerance = 20.0; // Hip angle tolerance
  static const double armSymmetryTolerance = 15.0; // Left-right difference
}

/// Exercise metadata
class ExerciseData {
  final String id;
  final String name;
  final String description;
  final int defaultReps;
  final int defaultSets;
  final String difficulty;
  final List<String> muscleGroups;
  final ExerciseTempo idealTempo;
  final double baseIntensity; // Recommended reps per set
  final double caloriesPerRep;

  const ExerciseData({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultReps,
    required this.defaultSets,
    required this.difficulty,
    required this.muscleGroups,
    required this.idealTempo,
    required this.caloriesPerRep,
    this.baseIntensity = 10.0,
  });
}

/// ⏱️ Movement Tempo: Eccentric - Isometric - Concentric
class ExerciseTempo {
  final double eccentric; // Descent phase (seconds)
  final double isometric; // Pause/Hold (seconds)
  final double concentric; // Ascent phase (seconds)

  const ExerciseTempo({
    this.eccentric = 2.0,
    this.isometric = 0.0,
    this.concentric = 1.0,
  });

  double get totalDuration => eccentric + isometric + concentric;
}

/// Pre-defined exercises
class Exercises {
  static const pushup = ExerciseData(
    id: 'pushup',
    name: 'Push-Up',
    description:
        'Classic upper body exercise targeting chest, triceps, and shoulders',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['chest', 'triceps', 'shoulders', 'core'],
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.5,
    baseIntensity: 10.0,
  );

  static const squat = ExerciseData(
    id: 'squat',
    name: 'Squat',
    description: 'Fundamental lower body exercise for legs and glutes',
    defaultReps: 15,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['quads', 'glutes', 'hamstrings', 'core'],
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.2, concentric: 1.0),
    caloriesPerRep: 0.32,
    baseIntensity: 15.0,
  );

  static const plank = ExerciseData(
    id: 'plank',
    name: 'Plank',
    description: 'Isometric core strength and stability exercise',
    defaultReps: 1,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['core', 'shoulders', 'back'],
    idealTempo:
        ExerciseTempo(eccentric: 0, isometric: 30, concentric: 0), // Holds
    caloriesPerRep: 0.1, // Calorie per second of hold
    baseIntensity: 30.0, // Seconds
  );

  static List<ExerciseData> get allExercises => [pushup, squat, plank];

  static ExerciseData? getById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
