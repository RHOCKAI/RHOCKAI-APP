class VoiceScriptManager {
  static String? getFormCorrection(String locale, String criterion) {
    if (criterion.contains('back')) {
      return 'Keep your back straight.';
    }
    if (criterion.contains('depth')) {
      return 'Go deeper.';
    }
    if (criterion.contains('elbow')) {
      return 'Tuck your elbows in.';
    }
    return 'Check your form.';
  }

  static String getRepMilestone5(String locale) =>
      'reps completed. Keep it up!';
  static String getRepComplete(String locale) => 'reps!';
  static String getSessionComplete(String locale) =>
      'Workout session complete. Great job!';
  static String getSessionStart(String locale) => '3, 2, 1, Go!';

  static String? getTempoFeedback(String locale, String feedback) {
    return feedback;
  }

  static List<String> getEncouragement(String locale) {
    return [
      'You are doing great!',
      'Keep pushing!',
      'Almost there!',
      'Stay strong!',
      'Excellent work!'
    ];
  }
}
