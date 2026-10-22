import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'localization.dart';
import 'shortcut_definition.dart';
import 'shortcut_rules.dart';

class KeyFixSettings {
  int shortcutModifiers = ShortcutDefinition.modAlt | ShortcutDefinition.modShift;
  int shortcutVirtualKey = 0;
  bool detectCapsLockInMixedCaseEnglish = true;
  bool autoSwitchKeyboardLanguage = true;
  bool ignoreShiftPersianToEnglish = false;
  bool ignoreShiftEnglishToPersian = false;
  bool isEnabled = true;
  bool startWithWindows = true;
  bool keepRunningInBackground = true;
  bool showTrayIcon = true;
  bool statusNotifications = true;
  String language = 'fa';

  Map<String, Object?> toJson() => <String, Object?>{
        'ShortcutModifiers': shortcutModifiers,
        'ShortcutVirtualKey': shortcutVirtualKey,
        'DetectCapsLockInMixedCaseEnglish': detectCapsLockInMixedCaseEnglish,
        'AutoSwitchKeyboardLanguage': autoSwitchKeyboardLanguage,
        'IgnoreShiftPersianToEnglish': ignoreShiftPersianToEnglish,
        'IgnoreShiftEnglishToPersian': ignoreShiftEnglishToPersian,
        'IsEnabled': isEnabled,
        'StartWithWindows': startWithWindows,
        'KeepRunningInBackground': keepRunningInBackground,
        'ShowTrayIcon': showTrayIcon,
        'StatusNotifications': statusNotifications,
        'Language': language,
      };

  static KeyFixSettings fromJson(Map<String, dynamic> json) {
    final KeyFixSettings s = KeyFixSettings();

    int? asInt(Object? v) => v is num ? v.toInt() : null;
    bool? asBool(Object? v) => v is bool ? v : null;

    s.shortcutModifiers = asInt(json['ShortcutModifiers']) ?? s.shortcutModifiers;
    s.shortcutVirtualKey =
        asInt(json['ShortcutVirtualKey']) ?? s.shortcutVirtualKey;
    s.detectCapsLockInMixedCaseEnglish =
        asBool(json['DetectCapsLockInMixedCaseEnglish']) ??
            s.detectCapsLockInMixedCaseEnglish;
    s.autoSwitchKeyboardLanguage = asBool(json['AutoSwitchKeyboardLanguage']) ??
        s.autoSwitchKeyboardLanguage;
    s.ignoreShiftPersianToEnglish =
        asBool(json['IgnoreShiftPersianToEnglish']) ??
            s.ignoreShiftPersianToEnglish;
    s.ignoreShiftEnglishToPersian =
        asBool(json['IgnoreShiftEnglishToPersian']) ??
            s.ignoreShiftEnglishToPersian;
    s.isEnabled = asBool(json['IsEnabled']) ?? s.isEnabled;
    s.startWithWindows = asBool(json['StartWithWindows']) ?? s.startWithWindows;
    s.keepRunningInBackground =
        asBool(json['KeepRunningInBackground']) ?? s.keepRunningInBackground;
    s.showTrayIcon = asBool(json['ShowTrayIcon']) ?? s.showTrayIcon;
    s.statusNotifications =
        asBool(json['StatusNotifications']) ?? s.statusNotifications;
    final Object? lang = json['Language'];
    if (lang is String) {
      s.language = lang;
    }
    return s;
  }
}

class SettingsManager {
  SettingsManager._(this._settingsPath, this.settings);

  final String _settingsPath;
  final KeyFixSettings settings;

  Timer? _debounce;

  static Future<SettingsManager> create({String? initialLanguage}) async {
    final Directory folder = await _settingsFolder();
    await folder.create(recursive: true);

    final String path = '${folder.path}${Platform.pathSeparator}Settings.json';
    final bool existed = await File(path).exists();
    final KeyFixSettings loaded = await _load(path);

    final SettingsManager manager = SettingsManager._(path, loaded);

    if (!existed &&
        (initialLanguage == 'fa' || initialLanguage == 'en')) {
      loaded.language = initialLanguage!;
      manager.flushPendingSaves();
    }

    return manager;
  }

  static Future<Directory> _settingsFolder() async {
    final Map<String, String> env = Platform.environment;

    if (Platform.isWindows) {
      final String? local = env['LOCALAPPDATA'];
      if (local != null && local.isNotEmpty) {
        return Directory('$local\\KeyFix');
      }
      final String? profile = env['USERPROFILE'];
      return Directory('${profile ?? '.'}\\AppData\\Local\\KeyFix');
    }

    final String home = env['HOME'] ?? '.';
    if (Platform.isMacOS) {
      return Directory('$home/Library/Application Support/KeyFix');
    }

    final String? xdg = env['XDG_CONFIG_HOME'];
    return Directory('${xdg ?? '$home/.config'}/KeyFix');
  }

  static Future<KeyFixSettings> _load(String path) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        return KeyFixSettings();
      }

      final String text = await file.readAsString();
      final Object? decoded = jsonDecode(
        text.startsWith('﻿') ? text.substring(1) : text,
      );

      if (decoded is! Map<String, dynamic>) {
        return KeyFixSettings();
      }

      return _validate(KeyFixSettings.fromJson(decoded));
    } catch (_) {
      return KeyFixSettings();
    }
  }

  static KeyFixSettings _validate(KeyFixSettings s) {
    final KeyFixSettings defaults = KeyFixSettings();

    const int allowedModifierMask = 0x0001 | 0x0002 | 0x0004 | 0x0008;

    if ((s.shortcutModifiers & ~allowedModifierMask) != 0) {
      s.shortcutModifiers = defaults.shortcutModifiers;
    }

    if (s.shortcutVirtualKey < 0 || s.shortcutVirtualKey > 0xFE ||
        ShortcutRules.validate(s.shortcutModifiers, s.shortcutVirtualKey) !=
            null) {
      s.shortcutModifiers = defaults.shortcutModifiers;
      s.shortcutVirtualKey = defaults.shortcutVirtualKey;
    }

    if (s.language != 'fa' && s.language != 'en') {
      s.language = defaults.language;
    }

    return s;
  }

  void save() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _writeNow);
  }

  void flushPendingSaves() {
    _debounce?.cancel();
    _debounce = null;
    _writeNowSync();
  }

  Future<void> _writeNow() async {
    try {
      await File(_settingsPath).writeAsString(_encode());
    } catch (e) {
      debugPrint('KeyFix: could not save settings: $e');
    }
  }

  void _writeNowSync() {
    try {
      File(_settingsPath).writeAsStringSync(_encode());
    } catch (e) {
      debugPrint('KeyFix: could not save settings: $e');
    }
  }

  String _encode() =>
      const JsonEncoder.withIndent('  ').convert(settings.toJson());

  ShortcutDefinition getShortcut() => ShortcutDefinition(
        settings.shortcutModifiers,
        settings.shortcutVirtualKey,
      );

  void setShortcut(ShortcutDefinition shortcut) {
    settings.shortcutModifiers = shortcut.modifiers;
    settings.shortcutVirtualKey = shortcut.virtualKey;
    save();
  }

  void setDetectCapsLock(bool v) {
    settings.detectCapsLockInMixedCaseEnglish = v;
    save();
  }

  void setAutoSwitchKeyboardLanguage(bool v) {
    settings.autoSwitchKeyboardLanguage = v;
    save();
  }

  void setIgnoreShiftPersianToEnglish(bool v) {
    settings.ignoreShiftPersianToEnglish = v;
    save();
  }

  void setIgnoreShiftEnglishToPersian(bool v) {
    settings.ignoreShiftEnglishToPersian = v;
    save();
  }

  void setEnabled(bool v) {
    settings.isEnabled = v;
    save();
  }

  void setStartWithWindows(bool v) {
    settings.startWithWindows = v;
    save();
  }

  void setKeepRunningInBackground(bool v) {
    settings.keepRunningInBackground = v;
    save();
  }

  void setShowTrayIcon(bool v) {
    settings.showTrayIcon = v;
    save();
  }

  void setStatusNotifications(bool v) {
    settings.statusNotifications = v;
    save();
  }

  void setLanguage(AppLanguage language) {
    settings.language = Localization.toCode(language);
    save();
  }

  AppLanguage getLanguage() => Localization.parse(settings.language);
}
