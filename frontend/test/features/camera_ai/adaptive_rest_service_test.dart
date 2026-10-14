import 'package:flutter_test/flutter_test.dart';
import 'package:rhockai/core/config/feature_flags.dart';
import 'package:rhockai/features/camera_ai/services/adaptive_rest_service.dart';

void main() {
  setUp(() {
    FeatureFlags.resetToDefault();
  });

  group('AdaptiveRestService Calculations', () {
    test('Calculates base rest duration accurately per exercise type', () {
      expect(AdaptiveRestService.getBaseRestForExercise('squat'), equals(90));
      expect(AdaptiveRestService.getBaseRestForExercise('pushup'), equals(60));
      expect(AdaptiveRestService.getBaseRestForExercise('plank'), equals(45));
    });

    test('Increases rest when accuracy is below 75%', () {
      const perf = SetPerformanceData(
        averageAccuracy: 65.0,
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'pushup',
        performance: perf,
      );
      // Base (60) + 25 = 85s
      expect(rest, equals(85));
    });

    test('Increases rest when form drops more than 15% from previous set', () {
      const perf = SetPerformanceData(
        averageAccuracy: 78.0,
        previousSetAccuracy: 95.0, // 95 - 78 = 17% drop
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'pushup',
        performance: perf,
      );
      // Base (60) + 15 = 75s
      expect(rest, equals(75));
    });

    test('Increases rest when rep tempo was rushed', () {
      const perf = SetPerformanceData(
        averageAccuracy: 85.0,
        tempoTooFast: true,
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'squat',
        performance: perf,
      );
      // Base (90) + 10 = 100s
      expect(rest, equals(100));
    });

    test('Cumulatively stacks fatigue penalties and clamps at maximum 180s', () {
      const severeFatigue = SetPerformanceData(
        averageAccuracy: 50.0, // +25
        previousSetAccuracy: 90.0, // +15 (40% drop)
        tempoScore: 40.0, // +10
        tempoTooFast: true,
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'squat',
        performance: severeFatigue,
      );
      // Base (90) + 25 + 15 + 10 = 140s
      expect(rest, equals(140));
    });

    test('Respects minimum clamp of 45s', () {
      const highPerformance = SetPerformanceData(
        averageAccuracy: 98.0,
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'plank',
        performance: highPerformance,
      );
      expect(rest, equals(45));
    });

    test('Falls back to base/stored rest when feature flag is disabled', () {
      FeatureFlags.setFlag('adaptive_rest', false);
      const lowAccuracy = SetPerformanceData(
        averageAccuracy: 50.0,
      );
      final rest = AdaptiveRestService.calculateAdaptiveRest(
        exerciseType: 'pushup',
        performance: lowAccuracy,
        storedLastRest: 60,
      );
      expect(rest, equals(60));
    });
  });
}
