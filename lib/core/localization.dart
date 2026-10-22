import 'localization_strings.dart';

enum AppLanguage { persian, english }

class Localization {
  const Localization._();

  static AppLanguage parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'en':
        return AppLanguage.english;
      case 'fa':
      default:
        return AppLanguage.persian;
    }
  }

  static String toCode(AppLanguage language) {
    return language == AppLanguage.english ? 'en' : 'fa';
  }

  static bool isPersian(AppLanguage language) {
    return language == AppLanguage.persian;
  }

  static String get(AppLanguage language, String key) {
    final Map<String, String> table =
        language == AppLanguage.english ? kEnglishStrings : kPersianStrings;
    return table[key] ?? key;
  }
}
