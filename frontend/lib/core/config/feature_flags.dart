/// 🚩 Feature Flags System
///
/// Enables zero-overhead toggle of experimental and progressive features.
class FeatureFlags {
  static final Map<String, bool> _flags = {
    'adaptive_rest': true,
    'session_summary_prs': true,
    'asymmetry_alerts': true,
    'auto_exercise_detection': false,
    'form_fatigue_warning': true,
    'voice_set_logging': true,
    'offline_first_mode': true,
    'gamification_streaks': true,
    'tflite_classifier': true,
  };

  /// Check whether a given feature is enabled
  static bool isEnabled(String featureKey) {
    return _flags[featureKey] ?? false;
  }

  /// Override flag at runtime (e.g. for testing or remote config)
  static void setFlag(String featureKey, bool isEnabled) {
    _flags[featureKey] = isEnabled;
  }

  /// Reset all flags to defaults
  static void resetToDefault() {
    _flags['adaptive_rest'] = true;
    _flags['session_summary_prs'] = true;
    _flags['asymmetry_alerts'] = true;
    _flags['auto_exercise_detection'] = false;
    _flags['form_fatigue_warning'] = true;
    _flags['voice_set_logging'] = true;
    _flags['offline_first_mode'] = true;
    _flags['gamification_streaks'] = true;
    _flags['tflite_classifier'] = true;
  }
}
