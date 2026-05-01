class AppLocales {
  static const String en = 'en';
  static const String es = 'es';
  static const String fr = 'fr';
  static const String de = 'de';

  static const List<String> supportedLocales = [en, es, fr, de];

  static const Map<String, String> localeNames = {
    en: 'English',
    es: 'Español',
    fr: 'Français',
    de: 'Deutsch',
  };

  static String getLocaleName(String locale) {
    return localeNames[locale] ?? 'Unknown';
  }
}
