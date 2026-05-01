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
            title: Text(l10n.upgradeToPremium, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
            subtitle: Text(l10n.unlockFullPotential),
            leading: const Icon(Icons.star, color: Colors.amber),
            onTap: () {
              Navigator.pushNamed(context, '/premium');
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
                      return RadioListTile<ThemeMode>(
                        title: Text(mode.name.toUpperCase()),
                        value: mode,
                        // ignore: deprecated_member_use
                        groupValue: settings.themeMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            settingsNotifier.toggleTheme(value);
                            Navigator.pop(context);
                          }
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
}
