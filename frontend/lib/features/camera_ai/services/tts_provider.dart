import 'dart:async';

/// Base interface for Text-to-Speech providers
abstract class TTSProvider {
  /// Initialize the TTS engine
  Future<void> initialize();

  /// Speak a piece of text
  Future<void> speak(String text);

  /// Stop current speech
  Future<void> stop();

  /// Set voice settings (language, pitch, rate, volume)
  Future<void> setSettings({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
  });

  /// Dispose resources
  Future<void> dispose();
}
