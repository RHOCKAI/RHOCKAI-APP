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
        'Excellent work!',
      ],
      'rest_start': (int sec) => 'Rest for $sec seconds.',
      'rest_30s': '30 seconds left.',
      'rest_10s': '10 seconds, get ready.',
      'rest_complete': 'Rest over. Next set begins now!',
      'rest_extended': (int sec) => 'Added $sec seconds to rest.',
      'corrections': {
        'back': 'Keep your back straight.',
        'depth': 'Go deeper.',
        'default': 'Check your form.',
      },
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
        '¡Excelente trabajo!',
      ],
      'rest_start': (int sec) => 'Descansa por $sec segundos.',
      'rest_30s': 'Quedan 30 segundos.',
      'rest_10s': '10 segundos, prepárate.',
      'rest_complete': '¡Fin del descanso! ¡Comienza la siguiente serie!',
      'rest_extended': (int sec) => 'Se agregaron $sec segundos al descanso.',
      'corrections': {
        'back': 'Mantén la espalda recta.',
        'depth': 'Baja más.',
        'default': 'Revisa tu técnica.',
      },
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
        'Du machst das großartig!',
        'Weiter kämpfen!',
        'Fast geschafft!',
        'Bleib stark!',
        'Ausgezeichnete Arbeit!',
      ],
      'rest_start': (int sec) => 'Pause für $sec Sekunden.',
      'rest_30s': 'Noch 30 Sekunden.',
      'rest_10s': '10 Sekunden, mach dich bereit.',
      'rest_complete': 'Pause vorbei. Der nächste Satz beginnt!',
      'rest_extended': (int sec) => '$sec Sekunden zur Pause hinzugefügt.',
      'corrections': {
        'back': 'Halte deinen Rücken gerade.',
        'depth': 'Tiefer gehen.',
        'default': 'Achte auf deine Form.',
      },
    },
    'fr': {
      'excellent': 'Forme excellente!',
      'good_job': 'Bon travail, continuez!',
      'warning': 'Attention',
      'workout_complete': (int reps, int acc) =>
          'Entraînement terminé! $reps répétitions avec $acc% de précision',
      'rep_milestone': 'répétitions complétées. Continuez!',
      'rep_count': 'répétitions!',
      'session_complete': 'Session terminée. Excellent travail!',
      'session_start': '3, 2, 1, Partez!',
      'encouragement': [
        'Vous faites du super travail!',
        'Continuez!',
        'Presque terminé!',
        'Restez fort!',
        'Excellent travail!',
      ],
      'rest_start': (int sec) => 'Reposez-vous pendant $sec secondes.',
      'rest_30s': '30 secondes restantes.',
      'rest_10s': '10 secondes, préparez-vous.',
      'rest_complete': 'Repos terminé. La prochaine série commence!',
      'rest_extended': (int sec) => '$sec secondes ajoutées au repos.',
      'corrections': {
        'back': 'Gardez le dos droit.',
        'depth': 'Allez plus bas.',
        'default': 'Vérifiez votre posture.',
      },
    },
    'ar': {
      'excellent': 'شكل ممتاز!',
      'good_job': 'عمل رائع، استمر!',
      'warning': 'تحذير',
      'workout_complete': (int reps, int acc) =>
          'اكتمل التمرين! $reps تكرار بدقة $acc%',
      'rep_milestone': 'تكرار مكتمل. استمر!',
      'rep_count': 'تكرار!',
      'session_complete': 'اكتملت جلسة التمرين. عمل رائع!',
      'session_start': '3، 2، 1، ابدأ!',
      'encouragement': [
        'أنت تؤدي بشكل رائع!',
        'استمر في الدفع!',
        'اقتربت من الهدف!',
        'ابق قوياً!',
        'عمل ممتاز!',
      ],
      'rest_start': (int sec) => 'استرح لمدة $sec ثانية.',
      'rest_30s': 'بقي 30 ثانية.',
      'rest_10s': '10 ثوانٍ، استعد.',
      'rest_complete': 'انتهت الاستراحة. تبدأ المجموعة التالية الآن!',
      'rest_extended': (int sec) => 'تمت إضافة $sec ثانية للاستراحة.',
      'corrections': {
        'back': 'حافظ على استقامة ظهرك.',
        'depth': 'انزل أكثر.',
        'default': 'تحقق من شكلك.',
      },
    },
    'pt': {
      'excellent': 'Forma excelente!',
      'good_job': 'Bom trabalho, continue assim!',
      'warning': 'Atenção',
      'workout_complete': (int reps, int acc) =>
          'Treino completo! $reps repetições com $acc% de precisão',
      'rep_milestone': 'repetições completas. Continue assim!',
      'rep_count': 'repetições!',
      'session_complete': 'Sessão de treino completa. Ótimo trabalho!',
      'session_start': '3, 2, 1, Vai!',
      'encouragement': [
        'Você está indo muito bem!',
        'Continue empurrando!',
        'Quase lá!',
        'Fique forte!',
        'Excelente trabalho!',
      ],
      'rest_start': (int sec) => 'Descanse por $sec segundos.',
      'rest_30s': '30 segundos restantes.',
      'rest_10s': '10 segundos, prepare-se.',
      'rest_complete': 'Descanso finalizado. Próxima série começa agora!',
      'rest_extended': (int sec) => '$sec segundos adicionados ao descanso.',
      'corrections': {
        'back': 'Mantenha as costas retas.',
        'depth': 'Desça mais.',
        'default': 'Verifique sua forma.',
      },
    },
    'ja': {
      'excellent': '素晴らしいフォームです！',
      'good_job': 'よくできました、続けて！',
      'warning': '警告',
      'workout_complete': (int reps, int acc) =>
          'トレーニング完了！$repsレップ、精度$acc%',
      'rep_milestone': 'レップ完了。続けて！',
      'rep_count': 'レップ！',
      'session_complete': 'セッション完了。よくできました！',
      'session_start': '3、2、1、スタート！',
      'encouragement': [
        'よくやっています！',
        '頑張って！',
        'もう少し！',
        '強くいて！',
        '素晴らしい！',
      ],
      'rest_start': (int sec) => '$sec秒間休憩してください。',
      'rest_30s': '残り30秒です。',
      'rest_10s': '残り10秒、準備してください。',
      'rest_complete': '休憩終了です。次のセットを始めましょう！',
      'rest_extended': (int sec) => '休憩を$sec秒追加しました。',
      'corrections': {
        'back': '背中をまっすぐに保ってください。',
        'depth': 'もっと深く。',
        'default': 'フォームを確認してください。',
      },
    },
  };

  static Map<String, dynamic> _getLang(String locale) =>
      _translations[locale] ?? _translations['en']!;

  static String _get(String locale, String key) {
    final lang = _getLang(locale);
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
    final lang = _getLang(locale);
    final func = lang['workout_complete'] as Function;
    return func(reps, acc) as String;
  }

  static String getFormCorrection(
      String locale, String criterion, VoicePersonality personality) {
    final lang = _getLang(locale);
    final corrections = lang['corrections'] as Map<String, String>;
    if (criterion.contains('back')) {
      return corrections['back']!;
    }
    if (criterion.contains('depth')) {
      return corrections['depth']!;
    }
    return corrections['default']!;
  }

  static String getRepMilestone5(String locale, VoicePersonality personality) =>
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
    final lang = _getLang(locale);
    return lang['encouragement'] as List<String>;
  }

  static String getRestStart(String locale, int seconds) {
    final lang = _getLang(locale);
    final func = lang['rest_start'] as Function;
    return func(seconds) as String;
  }

  static String getRest30s(String locale) => _get(locale, 'rest_30s');

  static String getRest10s(String locale) => _get(locale, 'rest_10s');

  static String getRestComplete(String locale) => _get(locale, 'rest_complete');

  static String getRestExtended(String locale, int seconds) {
    final lang = _getLang(locale);
    final func = lang['rest_extended'] as Function;
    return func(seconds) as String;
  }

  /// Localized voice announcement for auto-detected exercises in 7 languages
  static String getDetectedExercise(String locale, String exerciseName) {
    switch (locale) {
      case 'es':
        return 'Detectado: $exerciseName';
      case 'de':
        return 'Erkannt: $exerciseName';
      case 'fr':
        return 'Détecté: $exerciseName';
      case 'ar':
        return 'تم رصد: $exerciseName';
      case 'pt':
        return 'Detectado: $exerciseName';
      case 'ja':
        return '$exerciseNameを検出しました';
      case 'en':
      default:
        return 'Detected $exerciseName';
    }
  }
}
