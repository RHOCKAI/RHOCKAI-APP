import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String unitSystem; // 'metric' or 'imperial'

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.unitSystem = 'metric',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? unitSystem,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      unitSystem: unitSystem ?? this.unitSystem,
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final notificationsEnabled = prefs.getBool(_notifKey) ?? true;
    final unitSystem = prefs.getString(_unitKey) ?? 'metric';

    state = SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      notificationsEnabled: notificationsEnabled,
      unitSystem: unitSystem,
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
}
