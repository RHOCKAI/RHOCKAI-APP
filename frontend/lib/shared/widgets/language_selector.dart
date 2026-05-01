import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import '../../features/camera_ai/services/voice_feedback_service.dart';
import '../../features/camera_ai/models/voice_settings.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(l10n.language),
      subtitle: Text(_getLanguageName(currentLocale.languageCode)),
      leading: const Icon(Icons.language),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _LanguagePicker(currentLocale: currentLocale),
        );
      },
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'ar':
        return 'العربية';
      case 'de':
        return 'Deutsch';
      case 'ja':
        return '日本語';
      case 'en':
      default:
        return 'English';
    }
  }
}

class _LanguagePicker extends ConsumerWidget {
  final Locale currentLocale;

  const _LanguagePicker({required this.currentLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.selectLanguage,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _buildLanguageOption(context, ref, 'en', 'English', '🇺🇸'),
          _buildLanguageOption(context, ref, 'de', 'Deutsch', '🇩🇪'),
          _buildLanguageOption(context, ref, 'ja', '日本語', '🇯🇵'),
          _buildLanguageOption(context, ref, 'fr', 'Français', '🇫🇷'),
          _buildLanguageOption(context, ref, 'es', 'Español', '🇪🇸'),
          _buildLanguageOption(context, ref, 'pt', 'Português', '🇧🇷'),
          _buildLanguageOption(context, ref, 'ar', 'العربية', '🇦🇪'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String code,
    String name,
    String flag,
  ) {
    final isSelected = currentLocale.languageCode == code;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        // Update app locale
        await ref.read(localeProvider.notifier).setLocale(Locale(code));
        
        // Update voice settings
        final voiceService = VoiceFeedbackService();
        final currentSettings = await VoiceSettings.load();
        
        // Map locale to TTS language
        final ttsLanguage = _getTtsLanguage(code);
        
        await voiceService.setVoice(language: ttsLanguage);
        await currentSettings.copyWith(
          language: ttsLanguage,
          locale: code,
        ).save();
        
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
  
  String _getTtsLanguage(String locale) {
    switch (locale) {
      case 'fr': return 'fr-FR';
      case 'es': return 'es-ES';
      case 'pt': return 'pt-BR';
      case 'ar': return 'ar-AE';
      case 'de': return 'de-DE';
      case 'ja': return 'ja-JP';
      case 'en':
      default: return 'en-US';
    }
  }
}
