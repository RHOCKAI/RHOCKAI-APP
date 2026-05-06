import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../shared/widgets/language_selector.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          const LanguageSelector(),
          const Divider(),

          // Upgrade to Premium
          ListTile(
            title: Text(l10n.upgradeToPremium,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.amber)),
            subtitle: Text(l10n.unlockFullPotential),
            leading: const Icon(Icons.star, color: Colors.amber),
            onTap: () {
              Navigator.pushNamed(context, '/premium');
            },
          ),
          const Divider(),

          // Energy Aura (Accent Color)
          ListTile(
            title: const Text('Energy Aura'),
            subtitle: const Text('Change the app\'s energy vibe'),
            leading: Icon(Icons.auto_awesome, color: settings.energyColor),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Energy Aura'),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorPicker(context, settingsNotifier, const Color(0xFF00D9FF), 'Blue'),
                      _colorPicker(context, settingsNotifier, const Color(0xFF00FF88), 'Green'),
                      _colorPicker(context, settingsNotifier, const Color(0xFFFF6B35), 'Orange'),
                      _colorPicker(context, settingsNotifier, const Color(0xFF9C27FF), 'Purple'),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Theme Selection
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            leading: const Icon(Icons.palette_outlined),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ThemeMode.values.map((mode) {
                      final isSelected = settings.themeMode == mode;
                      return ListTile(
                        title: Text(mode.name.toUpperCase(), 
                          style: TextStyle(
                            color: isSelected ? settings.energyColor : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? settings.energyColor : Colors.white54,
                        ),
                        onTap: () {
                          settingsNotifier.toggleTheme(mode);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Notifications toggle
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable daily reminders'),
            secondary: const Icon(Icons.notifications_outlined),
            value: settings.notificationsEnabled,
            onChanged: (value) =>
                settingsNotifier.setNotificationsEnabled(value),
          ),
          const Divider(),

          // Voice Agent toggle
          SwitchListTile(
            title: const Text('Voice Agent'),
            subtitle: const Text('AI coaching and form feedback'),
            secondary: const Icon(Icons.record_voice_over_outlined),
            value: settings.voiceEnabled,
            onChanged: (value) => settingsNotifier.setVoiceEnabled(value),
          ),
          
          if (settings.voiceEnabled)
            ListTile(
              title: const Text('Coach Personality'),
              subtitle: Text(settings.voicePersonality.name.toUpperCase()),
              leading: const Icon(Icons.person_outline),
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Personality'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: VoicePersonality.values.map((p) {
                        final isSelected = settings.voicePersonality == p;
                        return ListTile(
                          title: Text(p.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? settings.energyColor : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? settings.energyColor : Colors.white54,
                          ),
                          onTap: () {
                            settingsNotifier.setVoicePersonality(p);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

          const Divider(),

          // Unit System toggle
          ListTile(
            title: const Text('Unit System'),
            subtitle: Text(settings.unitSystem == 'metric'
                ? 'Metric (kg, cm)'
                : 'Imperial (lb, in)'),
            leading: const Icon(Icons.straighten_outlined),
            onTap: () {
              final newSystem =
                  settings.unitSystem == 'metric' ? 'imperial' : 'metric';
              settingsNotifier.setUnitSystem(newSystem);
            },
          ),

          const Divider(),

          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Rhockai',
                applicationVersion: '2.0.0',
                applicationIcon: const Icon(Icons.fitness_center, size: 48),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _colorPicker(BuildContext context, SettingsNotifier notifier, Color color, String label) {
    return GestureDetector(
      onTap: () {
        notifier.setEnergyColor(color);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
