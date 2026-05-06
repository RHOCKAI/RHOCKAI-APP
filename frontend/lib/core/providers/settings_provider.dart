import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoicePersonality {
  natural,
  sergeant,
  zen,
  hype,
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String unitSystem; // 'metric' or 'imperial'
  final bool voiceEnabled;
  final VoicePersonality voicePersonality;
  final Color energyColor;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.unitSystem = 'metric',
    this.voiceEnabled = true,
    this.voicePersonality = VoicePersonality.natural,
    this.energyColor = const Color(0xFF00D9FF), // Default Neon Blue
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? unitSystem,
    bool? voiceEnabled,
    VoicePersonality? voicePersonality,
    Color? energyColor,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      unitSystem: unitSystem ?? this.unitSystem,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voicePersonality: voicePersonality ?? this.voicePersonality,
      energyColor: energyColor ?? this.energyColor,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  static const _themeKey = 'theme_mode';
  static const _notifKey = 'notifications_enabled';
  static const _unitKey = 'unit_system';
  static const _voiceKey = 'voice_enabled';
  static const _personalityKey = 'voice_personality';
  static const _energyColorKey = 'energy_color';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final notificationsEnabled = prefs.getBool(_notifKey) ?? true;
    final unitSystem = prefs.getString(_unitKey) ?? 'metric';
    final voiceEnabled = prefs.getBool(_voiceKey) ?? true;

    state = SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      notificationsEnabled: notificationsEnabled,
      unitSystem: unitSystem,
      voiceEnabled: voiceEnabled,
      voicePersonality: VoicePersonality.values[prefs.getInt(_personalityKey) ?? VoicePersonality.natural.index],
      energyColor: Color(prefs.getInt(_energyColorKey) ?? 0xFF00D9FF),
    );
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, enabled);
  }

  Future<void> setUnitSystem(String system) async {
    state = state.copyWith(unitSystem: system);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, system);
  }
  
  Future<void> setVoiceEnabled(bool enabled) async {
    state = state.copyWith(voiceEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceKey, enabled);
  }

  Future<void> setVoicePersonality(VoicePersonality personality) async {
    state = state.copyWith(voicePersonality: personality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_personalityKey, personality.index);
  }

  Future<void> setEnergyColor(Color color) async {
    state = state.copyWith(energyColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_energyColorKey, color.toARGB32());
  }
}
