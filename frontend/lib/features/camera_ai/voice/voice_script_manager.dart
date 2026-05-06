import '../../../core/providers/settings_provider.dart';

class VoiceScriptManager {
  static final Map<String, Map<String, dynamic>> _translations = {
    'en': {
      'excellent': 'Excellent form!',
      'good_job': 'Good job, keep it up!',
      'warning': 'Warning',
      'workout_complete': (int reps, int acc) =>
          'Workout complete! $reps reps with $acc% accuracy',
      'rep_milestone': 'reps completed. Keep it up!',
      'rep_count': 'reps!',
      'session_complete': 'Workout session complete. Great job!',
      'session_start': '3, 2, 1, Go!',
      'encouragement': [
        'You are doing great!',
        'Keep pushing!',
        'Almost there!',
        'Stay strong!',
        'Excellent work!'
      ],
    },
    'es': {
      'excellent': '¡Forma excelente!',
      'good_job': '¡Buen trabajo, sigue así!',
      'warning': 'Advertencia',
      'workout_complete': (int reps, int acc) =>
          '¡Entrenamiento completado! $reps repeticiones con $acc% de precisión',
      'rep_milestone': 'repeticiones completadas. ¡Sigue así!',
      'rep_count': 'repeticiones!',
      'session_complete': 'Sesión de entrenamiento completada. ¡Buen trabajo!',
      'session_start': '3, 2, 1, ¡Ya!',
      'encouragement': [
        '¡Lo estás haciendo genial!',
        '¡Sigue así!',
        '¡Ya casi terminas!',
        '¡Mantente fuerte!',
        '¡Excelente trabajo!'
      ],
    },
    'de': {
      'excellent': 'Hervorragende Form!',
      'good_job': 'Gute Arbeit, mach weiter so!',
      'warning': 'Warnung',
      'workout_complete': (int reps, int acc) =>
          'Training abgeschlossen! $reps Wiederholungen mit $acc% Genauigkeit',
      'rep_milestone': 'Wiederholungen geschafft. Weiter so!',
      'rep_count': 'Wiederholungen!',
      'session_complete': 'Trainingseinheit abgeschlossen. Super gemacht!',
      'session_start': '3, 2, 1, Los!',
      'encouragement': [
        'Du machst das super!',
        'Bleib dran!',
        'Fast geschafft!',
        'Bleib stark!',
        'Ausgezeichnete Arbeit!'
      ],
    },
  };

  static String _get(String locale, String key) {
    final lang = _translations[locale] ?? _translations['en']!;
    return lang[key] as String;
  }

  static String getExcellentForm(String locale, VoicePersonality personality) =>
      _get(locale, 'excellent');
  static String getGoodJob(String locale, VoicePersonality personality) =>
      _get(locale, 'good_job');
  static String getWarningPrefix(String locale, VoicePersonality personality) =>
      _get(locale, 'warning');

  static String getWorkoutCompleteSummary(
      String locale, VoicePersonality personality, int reps, int acc) {
    final lang = _translations[locale] ?? _translations['en']!;
    final func = lang['workout_complete'] as Function;
    return func(reps, acc) as String;
  }

  static String getFormCorrection(
      String locale, String criterion, VoicePersonality personality) {
    if (locale == 'es') {
      if (criterion.contains('back')) {
        return 'Mantén la espalda recta.';
      }
      if (criterion.contains('depth')) {
        return 'Baja más.';
      }
      return 'Revisa tu técnica.';
    }
    if (locale == 'de') {
      if (criterion.contains('back')) {
        return 'Rücken gerade halten.';
      }
      if (criterion.contains('depth')) {
        return 'Tiefer gehen.';
      }
      return 'Achte auf deine Form.';
    }

    if (criterion.contains('back')) {
      return 'Keep your back straight.';
    }
    if (criterion.contains('depth')) {
      return 'Go deeper.';
    }
    return 'Check your form.';
  }

  static String getRepMilestone5(
          String locale, VoicePersonality personality) =>
      _get(locale, 'rep_milestone');
  static String getRepComplete(String locale, VoicePersonality personality) =>
      _get(locale, 'rep_count');
  static String getSessionComplete(
          String locale, VoicePersonality personality) =>
      _get(locale, 'session_complete');
  static String getSessionStart(String locale, VoicePersonality personality) =>
      _get(locale, 'session_start');

  static String? getTempoFeedback(
          String locale, String feedback, VoicePersonality personality) =>
      feedback;

  static List<String> getEncouragement(
      String locale, VoicePersonality personality) {
    final lang = _translations[locale] ?? _translations['en']!;
    return lang['encouragement'] as List<String>;
  }
}
