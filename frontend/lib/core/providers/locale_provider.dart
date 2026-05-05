import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/camera_ai/services/voice_feedback_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      state = Locale(languageCode);
      _updateVoiceService(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    _updateVoiceService(locale.languageCode);
  }

  void _updateVoiceService(String languageCode) {
    // Map short locale codes to TTS language codes
    final Map<String, String> ttsLanguages = {
      'en': 'en-US',
      'de': 'de-DE',
      'ja': 'ja-JP',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'pt': 'pt-BR',
      'ar': 'ar-SA',
    };
    
    final ttsCode = ttsLanguages[languageCode] ?? 'en-US';
    VoiceFeedbackService().setVoice(language: ttsCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
