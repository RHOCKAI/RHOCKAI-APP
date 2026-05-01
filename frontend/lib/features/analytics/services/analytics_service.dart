import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/analytics_models.dart';

/// 📊 Analytics Service
/// Tracks app usage, screens, features and errors
class AnalyticsService {
  final ApiClient _apiClient;
  String? _currentSessionId;
  DateTime? _sessionStart;
  String? _lastScreenName;
  DateTime? _screenStartTime;
  String? _currentScreen;

  AnalyticsService(this._apiClient);

  String? get currentSessionId => _currentSessionId;

  // ─────────────────────────────────────────────
  // SESSION TRACKING
  // ─────────────────────────────────────────────

  /// Start a new tracking session
  Future<void> startSession({
    required String appVersion,
    String? deviceType,
    String? deviceModel,
    String? osName,
    String? osVersion,
  }) async {
    final request = TrackSessionRequest.generate(
      appVersion: appVersion,
      deviceType: deviceType ?? _getDeviceType(),
      deviceModel: deviceModel ?? await _getDeviceModel(),
      osName: osName ?? (kIsWeb ? 'web' : Platform.operatingSystem),
      osVersion: osVersion ?? (kIsWeb ? 'unknown' : Platform.operatingSystemVersion),
    );
    
    _currentSessionId = request.sessionId;
    _sessionStart = DateTime.now();

    try {
      await _apiClient.post('/track/session/start', data: request.toJson());
      debugPrint('Analytics: Session started - $_currentSessionId');
    } catch (e) {
      debugPrint('Analytics Error: Failed to start session - $e');
    }
  }

  /// End the current session
  Future<void> endSession() async {
    if (_currentSessionId == null || _sessionStart == null) {
      return;
    }

    final duration = DateTime.now().difference(_sessionStart!).inSeconds;

    try {
      await _apiClient.post('/track/session/end', data: {
        'session_id': _currentSessionId,
        'duration_seconds': duration,
      });
      debugPrint('Analytics: Session ended - $_currentSessionId');
      _currentSessionId = null;
      _sessionStart = null;
    } catch (e) {
      debugPrint('Analytics Error: Failed to end session - $e');
    }
  }

  // ─────────────────────────────────────────────
  // SCREEN TRACKING
  // ─────────────────────────────────────────────

  /// Track a screen view
  Future<void> trackScreen(String screenName, {Map<String, dynamic>? extraData}) async {
    if (_currentSessionId == null) {
      return;
    }

    int? timeOnPreviousScreen;
    if (_screenStartTime != null && _currentScreen != null) {
      timeOnPreviousScreen = DateTime.now().difference(_screenStartTime!).inSeconds;
    }

    final request = TrackScreenRequest(
      sessionId: _currentSessionId!,
      screenName: screenName,
      previousScreen: _lastScreenName,
      timeOnScreen: timeOnPreviousScreen,
      extraData: extraData,
    );

    _lastScreenName = _currentScreen;
    _currentScreen = screenName;
    _screenStartTime = DateTime.now();

    try {
      await _apiClient.post('/track/screen', data: request.toJson());
      debugPrint('Analytics: Screen view - $screenName');
    } catch (e) {
      debugPrint('Analytics Error: Failed to track screen - $e');
    }
  }

  // ─────────────────────────────────────────────
  // FEATURE TRACKING
  // ─────────────────────────────────────────────

  /// Track a feature usage
  Future<void> trackFeature(String featureName, String action, {Map<String, dynamic>? extraData}) async {
    final request = TrackFeatureRequest(
      featureName: featureName,
      action: action,
      extraData: extraData,
    );

    try {
      await _apiClient.post('/track/feature', data: request.toJson());
      debugPrint('Analytics: Feature usage - $featureName ($action)');
    } catch (e) {
      debugPrint('Analytics Error: Failed to track feature - $e');
    }
  }

  // ─────────────────────────────────────────────
  // DEMOGRAPHIC TRACKING
  // ─────────────────────────────────────────────

  /// Update user demographic information (call during onboarding)
  Future<void> updateDemographic({
    String? ageRange,
    String? gender,
    String? fitnessLevel,
    String? fitnessGoal,
    String? howFoundApp,
  }) async {
    try {
      await _apiClient.post('/track/demographic', data: {
        if (ageRange != null) 'age_range': ageRange,
        if (gender != null) 'gender': gender,
        if (fitnessLevel != null) 'fitness_level': fitnessLevel,
        if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
        if (howFoundApp != null) 'how_found_app': howFoundApp,
      });
      debugPrint('Analytics: Demographics updated');
    } catch (e) {
      debugPrint('Analytics Error: Failed to update demographics - $e');
    }
  }

  // ─────────────────────────────────────────────
  // ERROR TRACKING
  // ─────────────────────────────────────────────

  /// Track an error
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? screen,
    String? appVersion,
  }) async {
    final request = TrackErrorRequest(
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      screen: screen ?? _currentScreen,
      appVersion: appVersion,
      osName: kIsWeb ? 'web' : Platform.operatingSystem,
      osVersion: kIsWeb ? 'unknown' : Platform.operatingSystemVersion,
    );

    try {
      await _apiClient.post('/track/error', data: request.toJson());
      debugPrint('Analytics: Error tracked - $errorType');
    } catch (e) {
      debugPrint('Analytics Error: Failed to track error - $e');
    }
  }

  // ─────────────────────────────────────────────
  // PREDEFINED EVENTS (use these throughout app)
  // ─────────────────────────────────────────────

  // Workout events
  Future<void> trackWorkoutStarted(String exerciseType) =>
      trackFeature('workout', 'started', extraData: {'exercise': exerciseType});

  Future<void> trackWorkoutCompleted(String exerciseType, int reps, double accuracy) =>
      trackFeature('workout', 'completed', extraData: {
        'exercise': exerciseType,
        'reps': reps,
        'accuracy': accuracy,
      });

  Future<void> trackWorkoutAbandoned(String exerciseType, int repsCompleted) =>
      trackFeature('workout', 'abandoned', extraData: {
        'exercise': exerciseType,
        'reps_completed': repsCompleted,
      });

  // Paywall events
  Future<void> trackPaywallViewed(String source) =>
      trackFeature('paywall', 'viewed', extraData: {'source': source});

  Future<void> trackPlanSelected(String plan) =>
      trackFeature('paywall', 'plan_selected', extraData: {'plan': plan});

  Future<void> trackSubscriptionStarted(String plan) =>
      trackFeature('subscription', 'started', extraData: {'plan': plan});

  // Onboarding events
  Future<void> trackOnboardingStep(int step, String stepName) =>
      trackFeature('onboarding', 'step_completed', extraData: {
        'step': step,
        'step_name': stepName,
      });

  Future<void> trackOnboardingCompleted() =>
      trackFeature('onboarding', 'completed');

  // ─────────────────────────────────────────────
  // DEVICE HELPERS
  // ─────────────────────────────────────────────

  String _getDeviceType() {
    if (kIsWeb) {
      return 'browser';
    }
    return 'mobile';
  }

  Future<String> _getDeviceModel() async {
    if (kIsWeb) {
      return 'Web Browser';
    }
    if (Platform.isIOS) {
      return 'iPhone';
    }
    if (Platform.isAndroid) {
      return 'Android Device';
    }
    return 'Unknown';
  }
}
