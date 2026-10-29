import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyfix/core/localization.dart';
import 'package:keyfix/core/localization_strings.dart';
import 'package:keyfix/core/settings_manager.dart';
import 'package:keyfix/core/shortcut_definition.dart';

void main() {
  test('settings defaults', () {
    final KeyFixSettings s = KeyFixSettings();
    expect(s.shortcutModifiers, 0x0005);
    expect(s.shortcutVirtualKey, 0);
    expect(s.detectCapsLockInMixedCaseEnglish, isTrue);
    expect(s.autoSwitchKeyboardLanguage, isTrue);
    expect(s.ignoreShiftPersianToEnglish, isFalse);
    expect(s.ignoreShiftEnglishToPersian, isFalse);
    expect(s.isEnabled, isTrue);
    expect(s.startWithWindows, isTrue);
    expect(s.keepRunningInBackground, isTrue);
    expect(s.showTrayIcon, isTrue);
    expect(s.statusNotifications, isTrue);
    expect(s.language, 'fa');
  });

  test('reads a Settings.json written by the WinUI version', () {
    const String csharpJson = '''
{
  "ShortcutModifiers": 6,
  "ShortcutVirtualKey": 74,
  "DetectCapsLockInMixedCaseEnglish": false,
  "AutoSwitchKeyboardLanguage": true,
  "IgnoreShiftPersianToEnglish": true,
  "IgnoreShiftEnglishToPersian": false,
  "IsEnabled": false,
  "StartWithWindows": false,
  "KeepRunningInBackground": true,
  "ShowTrayIcon": false,
  "StatusNotifications": true,
  "Language": "en"
}''';

    final KeyFixSettings s = KeyFixSettings.fromJson(
      jsonDecode(csharpJson) as Map<String, dynamic>,
    );

    expect(s.shortcutModifiers, 6);
    expect(s.shortcutVirtualKey, 74);
    expect(s.detectCapsLockInMixedCaseEnglish, isFalse);
    expect(s.ignoreShiftPersianToEnglish, isTrue);
    expect(s.isEnabled, isFalse);
    expect(s.showTrayIcon, isFalse);
    expect(s.language, 'en');
    expect(
      const ShortcutDefinition(6, 74).toString(),
      'Ctrl + Shift + J',
    );
  });

  test('JSON keys round-trip', () {
    final Map<String, Object?> json = KeyFixSettings().toJson();
    expect(json.keys, containsAll(<String>[
      'ShortcutModifiers',
      'ShortcutVirtualKey',
      'DetectCapsLockInMixedCaseEnglish',
      'AutoSwitchKeyboardLanguage',
      'IgnoreShiftPersianToEnglish',
      'IgnoreShiftEnglishToPersian',
      'IsEnabled',
      'StartWithWindows',
      'KeepRunningInBackground',
      'ShowTrayIcon',
      'StatusNotifications',
      'Language',
    ]));
  });

  test('both language tables have identical keys (82 entries)', () {
    expect(kEnglishStrings.length, 82);
    expect(kPersianStrings.keys.toSet(), kEnglishStrings.keys.toSet());
  });

  test('localization lookups', () {
    expect(Localization.get(AppLanguage.english, 'Save'), 'Save');
    expect(Localization.get(AppLanguage.persian, 'Save'), 'ذخیره');
    expect(Localization.get(AppLanguage.english, 'NoSuchKey'), 'NoSuchKey');
    expect(Localization.parse('en'), AppLanguage.english);
    expect(Localization.parse('xx'), AppLanguage.persian);
  });
}
