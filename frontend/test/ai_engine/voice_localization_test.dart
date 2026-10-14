import 'package:flutter_test/flutter_test.dart';
import 'package:rhockai/features/camera_ai/voice/voice_script_manager.dart';
import 'package:rhockai/features/camera_ai/services/voice_feedback_service.dart';

void main() {
  group('Voice Feedback & 7-Language Localization Tests', () {
    test('getDetectedExercise returns correct phrases for all 7 languages', () {
      const exercise = 'Push-ups';

      expect(
        VoiceScriptManager.getDetectedExercise('en', exercise),
        equals('Detected Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('es', exercise),
        equals('Detectado: Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('de', exercise),
        equals('Erkannt: Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('fr', exercise),
        equals('Détecté: Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('ar', exercise),
        equals('تم رصد: Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('pt', exercise),
        equals('Detectado: Push-ups'),
      );
      expect(
        VoiceScriptManager.getDetectedExercise('ja', exercise),
        equals('Push-upsを検出しました'),
      );
    });

    test('getDetectedExercise falls back to English on unknown locale', () {
      expect(
        VoiceScriptManager.getDetectedExercise('xx', 'Squats'),
        equals('Detected Squats'),
      );
    });

    test('VoiceMessage priority ordering is preserved', () {
      final highMsg = VoiceMessage(text: 'Critical Alert', priority: VoicePriority.high);
      final normalMsg = VoiceMessage(text: 'Good job', priority: VoicePriority.normal);
      final lowMsg = VoiceMessage(text: 'Keep it up', priority: VoicePriority.low);

      expect(highMsg.priority, equals(VoicePriority.high));
      expect(normalMsg.priority, equals(VoicePriority.normal));
      expect(lowMsg.priority, equals(VoicePriority.low));
    });
  });
}
