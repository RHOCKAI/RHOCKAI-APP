/// Exercise angle thresholds for AI pose detection
class ExerciseThresholds {
  // Push-up thresholds (elbow angle)
  static const double pushupDownAngle = 90.0;
  static const double pushupUpAngle = 160.0;

  // Squat thresholds (knee angle)
  static const double squatDownAngle = 90.0;
  static const double squatUpAngle = 170.0;

  // Plank thresholds (hip angle)
  static const double plankHipAngle = 180.0;
  static const double plankTolerance = 15.0;

  // Form accuracy thresholds
  static const double goodFormThreshold = 70.0;
  static const double excellentFormThreshold = 90.0;

  // Rep timing constraints
  static const int minRepDurationMs = 800;
  static const int maxRepDurationMs = 5000;

  // Detection confidence
  static const double minLandmarkConfidence = 0.5;

  // Angle tolerances for form checking
  static const double backStraightTolerance = 20.0;
  static const double armSymmetryTolerance = 15.0;
}

/// Exercise metadata
class ExerciseData {
  final String id;
  final String name;
  final String description;
  final String coachingCue;       // Single best coaching tip
  final String angleTracked;      // Which joint angle the AI tracks
  final int defaultReps;
  final int defaultSets;
  final String difficulty;        // 'beginner' | 'intermediate' | 'advanced'
  final List<String> muscleGroups;
  final String category;          // 'upper_body' | 'lower_body' | 'core' | 'full_body'
  final ExerciseTempo idealTempo;
  final double baseIntensity;
  final double caloriesPerRep;
  final String emoji;
  final String imageUrl;

  const ExerciseData({
    required this.id,
    required this.name,
    required this.description,
    required this.coachingCue,
    required this.angleTracked,
    required this.defaultReps,
    required this.defaultSets,
    required this.difficulty,
    required this.muscleGroups,
    required this.category,
    required this.idealTempo,
    required this.caloriesPerRep,
    required this.emoji,
    required this.imageUrl,
    this.baseIntensity = 10.0,
  });
}

/// ⏱️ Movement Tempo: Eccentric - Isometric - Concentric
class ExerciseTempo {
  final double eccentric;
  final double isometric;
  final double concentric;

  const ExerciseTempo({
    this.eccentric = 2.0,
    this.isometric = 0.0,
    this.concentric = 1.0,
  });

  double get totalDuration => eccentric + isometric + concentric;
}

/// All angle-trackable, no-equipment home exercises
class Exercises {
  // ─────────────────────────────────────────────
  // BEGINNER
  // ─────────────────────────────────────────────

  static const pushup = ExerciseData(
    id: 'pushup',
    name: 'Push-Up',
    emoji: '🤲',
    description: 'Classic upper body exercise targeting chest, triceps, and shoulders.',
    coachingCue: 'Keep your body in a straight line from head to heels.',
    angleTracked: 'Elbow angle (90° down → 160° up)',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['chest', 'triceps', 'shoulders', 'core'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.50,
    imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80',
  );

  static const squat = ExerciseData(
    id: 'squat',
    name: 'Bodyweight Squat',
    emoji: '🦵',
    description: 'Fundamental lower body exercise for quads, glutes and hamstrings.',
    coachingCue: 'Push your knees out and keep your chest proud.',
    angleTracked: 'Knee angle (170° up → 90° down)',
    defaultReps: 15,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['quads', 'glutes', 'hamstrings', 'core'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.32,
    imageUrl: 'https://images.unsplash.com/photo-1574680096141-1cddd32e04ca?auto=format&fit=crop&q=80',
  );

  static const plank = ExerciseData(
    id: 'plank',
    name: 'Plank Hold',
    emoji: '🧱',
    description: 'Isometric core stability exercise that also strengthens shoulders and back.',
    coachingCue: 'Squeeze your glutes and breathe steadily — no sagging hips.',
    angleTracked: 'Hip angle (straight 180° ± 15°)',
    defaultReps: 1,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['core', 'shoulders', 'back', 'glutes'],
    category: 'core',
    idealTempo: ExerciseTempo(eccentric: 0, isometric: 30, concentric: 0),
    caloriesPerRep: 0.10,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
  );

  static const gluteBridge = ExerciseData(
    id: 'glute_bridge',
    name: 'Glute Bridge',
    emoji: '🍑',
    description: 'Lying hip extension that activates glutes and strengthens the posterior chain.',
    coachingCue: 'Drive through your heels and squeeze at the top for 1 second.',
    angleTracked: 'Hip extension angle (90° up → 150° extended)',
    defaultReps: 15,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['glutes', 'hamstrings', 'lower back', 'core'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 1.0, concentric: 1.0),
    caloriesPerRep: 0.28,
    imageUrl: 'https://images.unsplash.com/photo-1544367567056-41c2cb2df638?auto=format&fit=crop&q=80',
  );

  static const inchworm = ExerciseData(
    id: 'inchworm',
    name: 'Inchworm',
    emoji: '🐛',
    description: 'Full-body warm-up that improves hamstring flexibility and shoulder stability.',
    coachingCue: 'Walk your hands out slowly, keeping legs as straight as possible.',
    angleTracked: 'Hip hinge angle throughout movement',
    defaultReps: 10,
    defaultSets: 2,
    difficulty: 'beginner',
    muscleGroups: ['hamstrings', 'shoulders', 'core', 'chest'],
    category: 'full_body',
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 0.5, concentric: 2.0),
    caloriesPerRep: 0.40,
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-69b125028f8f?auto=format&fit=crop&q=80',
  );

  static const standingMarchHigh = ExerciseData(
    id: 'high_knees',
    name: 'High Knees',
    emoji: '🏃',
    description: 'Standing cardio drill that elevates heart rate and improves hip flexor strength.',
    coachingCue: 'Drive your knee to hip height with each step — stay tall.',
    angleTracked: 'Hip flexion angle (knee height relative to hip)',
    defaultReps: 20,
    defaultSets: 3,
    difficulty: 'beginner',
    muscleGroups: ['hip flexors', 'quads', 'calves', 'core'],
    category: 'full_body',
    idealTempo: ExerciseTempo(eccentric: 0.3, isometric: 0, concentric: 0.3),
    caloriesPerRep: 0.20,
    imageUrl: 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&q=80',
  );

  // ─────────────────────────────────────────────
  // INTERMEDIATE
  // ─────────────────────────────────────────────

  static const lunges = ExerciseData(
    id: 'lunge',
    name: 'Forward Lunge',
    emoji: '🚶',
    description: 'Unilateral lower body exercise that improves balance, strength, and hip mobility.',
    coachingCue: 'Front knee stays over ankle — rear knee hovers 2 cm off the floor.',
    angleTracked: 'Front knee angle (170° → 90° down)',
    defaultReps: 12,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['quads', 'glutes', 'hamstrings', 'balance'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.5, concentric: 1.5),
    caloriesPerRep: 0.38,
    imageUrl: 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?auto=format&fit=crop&q=80',
  );

  static const tricepDip = ExerciseData(
    id: 'tricep_dip',
    name: 'Tricep Dip',
    emoji: '💪',
    description: 'Using a chair or floor, targets the triceps and posterior deltoids.',
    coachingCue: 'Keep your back close to the surface and elbows pointing backward.',
    angleTracked: 'Elbow angle (160° up → 90° dipped)',
    defaultReps: 12,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['triceps', 'chest', 'shoulders'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.45,
    imageUrl: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?auto=format&fit=crop&q=80',
  );

  static const mountainClimber = ExerciseData(
    id: 'mountain_climber',
    name: 'Mountain Climber',
    emoji: '🧗',
    description: 'Dynamic core and cardio movement in a plank position.',
    coachingCue: 'Keep hips level — don\'t let them rise or drop as you alternate legs.',
    angleTracked: 'Hip and knee angle throughout drive phase',
    defaultReps: 20,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['core', 'hip flexors', 'shoulders', 'quads'],
    category: 'full_body',
    idealTempo: ExerciseTempo(eccentric: 0.5, isometric: 0, concentric: 0.5),
    caloriesPerRep: 0.30,
    imageUrl: 'https://images.unsplash.com/photo-1571019615399-f2e1dfd490c6?auto=format&fit=crop&q=80',
  );

  static const sidePlank = ExerciseData(
    id: 'side_plank',
    name: 'Side Plank',
    emoji: '🪵',
    description: 'Lateral core stability exercise targeting the obliques and hip abductors.',
    coachingCue: 'Stack your feet, lift your hips high and hold perfectly still.',
    angleTracked: 'Lateral hip angle (spine alignment)',
    defaultReps: 1,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['obliques', 'hip abductors', 'shoulders', 'core'],
    category: 'core',
    idealTempo: ExerciseTempo(eccentric: 0, isometric: 30, concentric: 0),
    caloriesPerRep: 0.10,
    imageUrl: 'https://images.unsplash.com/photo-1518398092300-56ac591e0a29?auto=format&fit=crop&q=80',
  );

  static const reverseLunge = ExerciseData(
    id: 'reverse_lunge',
    name: 'Reverse Lunge',
    emoji: '↩️',
    description: 'A knee-friendly lunge variation that emphasizes glutes and hip stability.',
    coachingCue: 'Step backward slowly — control the descent with your front quad.',
    angleTracked: 'Front knee angle (170° → 90°)',
    defaultReps: 12,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['glutes', 'quads', 'hamstrings', 'core'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.5, concentric: 1.5),
    caloriesPerRep: 0.36,
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80',
  );

  static const pikePushup = ExerciseData(
    id: 'pike_pushup',
    name: 'Pike Push-Up',
    emoji: '🔺',
    description: 'An elevated push-up variation that shifts load to the shoulders and upper chest.',
    coachingCue: 'Form an inverted V — lower the top of your head toward the floor.',
    angleTracked: 'Elbow angle and shoulder angle during descent',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['shoulders', 'triceps', 'upper chest'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.55,
    imageUrl: 'https://images.unsplash.com/photo-1541534741627-52d80d2109ba?auto=format&fit=crop&q=80',
  );

  static const sumoSquat = ExerciseData(
    id: 'sumo_squat',
    name: 'Sumo Squat',
    emoji: '🤼',
    description: 'Wide-stance squat variation that targets inner thighs and glutes more directly.',
    coachingCue: 'Turn toes out 45° and push knees outward throughout the movement.',
    angleTracked: 'Knee angle and hip abduction angle',
    defaultReps: 15,
    defaultSets: 3,
    difficulty: 'intermediate',
    muscleGroups: ['inner thighs', 'glutes', 'quads', 'hamstrings'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 1.0, concentric: 1.0),
    caloriesPerRep: 0.35,
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-69b125028f8f?auto=format&fit=crop&q=80',
  );

  // ─────────────────────────────────────────────
  // ADVANCED
  // ─────────────────────────────────────────────

  static const pistolSquat = ExerciseData(
    id: 'pistol_squat',
    name: 'Pistol Squat',
    emoji: '🔫',
    description: 'Single-leg squat requiring extreme balance, mobility, and strength.',
    coachingCue: 'Extend your free leg forward and sit to parallel — control the return.',
    angleTracked: 'Single knee angle (170° → 80°) + hip stability',
    defaultReps: 8,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['quads', 'glutes', 'balance', 'ankles', 'core'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 3.0, isometric: 1.0, concentric: 2.0),
    caloriesPerRep: 0.60,
    imageUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&q=80',
  );

  static const diamondPushup = ExerciseData(
    id: 'diamond_pushup',
    name: 'Diamond Push-Up',
    emoji: '💎',
    description: 'Close-grip push-up with hands forming a diamond — maximum tricep isolation.',
    coachingCue: 'Touch thumbs and forefingers to form a diamond, elbows track back.',
    angleTracked: 'Elbow angle (160° → 70°)',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['triceps', 'chest', 'shoulders'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 2.5, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.65,
    imageUrl: 'https://images.unsplash.com/photo-1583454155184-870a1f63aebc?auto=format&fit=crop&q=80',
  );

  static const archerPushup = ExerciseData(
    id: 'archer_pushup',
    name: 'Archer Push-Up',
    emoji: '🏹',
    description: 'One arm bears most of the load — a stepping stone to one-arm push-ups.',
    coachingCue: 'Slide to one side while the other arm stays extended for support.',
    angleTracked: 'Primary elbow angle + shoulder abduction',
    defaultReps: 8,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['chest', 'triceps', 'shoulders', 'core'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 3.0, isometric: 0.5, concentric: 1.5),
    caloriesPerRep: 0.70,
    imageUrl: 'https://images.unsplash.com/photo-1599058917200-a6cb82dbbcbd?auto=format&fit=crop&q=80',
  );

  static const jumpSquat = ExerciseData(
    id: 'jump_squat',
    name: 'Jump Squat',
    emoji: '💥',
    description: 'Explosive plyometric squat that builds power, speed, and cardiovascular fitness.',
    coachingCue: 'Land softly with bent knees — don\'t let knees cave inward.',
    angleTracked: 'Knee angle pre-jump and on landing',
    defaultReps: 12,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['quads', 'glutes', 'calves', 'core'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 1.5, isometric: 0, concentric: 0.5),
    caloriesPerRep: 0.55,
    imageUrl: 'https://images.unsplash.com/photo-1552674605-b04b9015c92c?auto=format&fit=crop&q=80',
  );

  static const burpee = ExerciseData(
    id: 'burpee',
    name: 'Burpee',
    emoji: '🌪️',
    description: 'The ultimate total-body conditioning exercise combining squat, plank, and jump.',
    coachingCue: 'Control every phase — speed without form is wasted effort.',
    angleTracked: 'Hip and knee angle through squat and plank phases',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['full body', 'chest', 'legs', 'core', 'cardio'],
    category: 'full_body',
    idealTempo: ExerciseTempo(eccentric: 1.0, isometric: 0, concentric: 1.0),
    caloriesPerRep: 0.80,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
  );

  static const singleLegDeadlift = ExerciseData(
    id: 'single_leg_deadlift',
    name: 'Single-Leg Deadlift',
    emoji: '🦩',
    description: 'Unilateral hip hinge that targets hamstrings, glutes, and balance simultaneously.',
    coachingCue: 'Hinge at the hip, not the waist — keep your back flat throughout.',
    angleTracked: 'Hip hinge angle + spine alignment',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['hamstrings', 'glutes', 'lower back', 'balance'],
    category: 'lower_body',
    idealTempo: ExerciseTempo(eccentric: 3.0, isometric: 0.5, concentric: 2.0),
    caloriesPerRep: 0.45,
    imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&q=80',
  );

  static const spiderManPushup = ExerciseData(
    id: 'spiderman_pushup',
    name: 'Spider-Man Push-Up',
    emoji: '🕷️',
    description: 'Push-up with alternating knee-to-elbow drive for core and hip flexor activation.',
    coachingCue: 'Bring your knee outside your elbow at the bottom of each rep.',
    angleTracked: 'Elbow angle + knee elevation angle',
    defaultReps: 10,
    defaultSets: 3,
    difficulty: 'advanced',
    muscleGroups: ['chest', 'triceps', 'core', 'hip flexors'],
    category: 'upper_body',
    idealTempo: ExerciseTempo(eccentric: 2.0, isometric: 0.5, concentric: 1.0),
    caloriesPerRep: 0.68,
    imageUrl: 'https://images.unsplash.com/photo-1571019615399-f2e1dfd490c6?auto=format&fit=crop&q=80',
  );

  // ─────────────────────────────────────────────
  // COLLECTIONS
  // ─────────────────────────────────────────────

  static List<ExerciseData> get allExercises => [
        // Beginner
        pushup, squat, plank, gluteBridge, inchworm, standingMarchHigh,
        // Intermediate
        lunges, tricepDip, mountainClimber, sidePlank, reverseLunge,
        pikePushup, sumoSquat,
        // Advanced
        pistolSquat, diamondPushup, archerPushup, jumpSquat, burpee,
        singleLegDeadlift, spiderManPushup,
      ];

  static List<ExerciseData> get beginnerExercises =>
      allExercises.where((e) => e.difficulty == 'beginner').toList();

  static List<ExerciseData> get intermediateExercises =>
      allExercises.where((e) => e.difficulty == 'intermediate').toList();

  static List<ExerciseData> get advancedExercises =>
      allExercises.where((e) => e.difficulty == 'advanced').toList();

  static ExerciseData? getById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
