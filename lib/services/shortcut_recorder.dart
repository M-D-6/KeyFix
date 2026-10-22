import 'package:flutter/foundation.dart';

import '../core/shortcut_definition.dart';
import '../core/shortcut_rules.dart';

class ShortcutRecorder extends ChangeNotifier {
  static const int virtualKeyAlt = 0x12;
  static const int virtualKeyCtrl = 0x11;
  static const int virtualKeyShift = 0x10;

  bool visible = false;
  bool recording = false;
  bool paused = false;
  bool hasMainKey = false;
  bool retryVisible = false;

  int modifiers = 0;
  int mainKey = 0;
  final List<int> modifierOrder = <int>[];

  String? helpKey;

  String helpSuffix = '';

  void toggleEditor() {
    if (visible) {
      close();
      return;
    }
    begin();
  }

  void close() {
    stop();
    visible = false;
    helpKey = null;
    helpSuffix = '';
    notifyListeners();
  }

  void begin() {
    _clearState();

    recording = true;
    paused = false;
    visible = true;
    retryVisible = false;
    helpKey = 'ShortcutHelp';
    helpSuffix = '';

    notifyListeners();
  }

  void onRecorderClicked() {
    if (!recording) {
      begin();
    }
  }

  void stop() {
    recording = false;
    paused = false;
    _clearState();
    retryVisible = false;
  }

  void pause() {
    if (!recording) {
      return;
    }

    recording = false;
    paused = true;
    retryVisible = true;
    helpKey = 'ShortcutRecordingStopped';
    helpSuffix = '';

    notifyListeners();
  }

  void reset(String messageKey) {
    _clearState();

    recording = true;
    paused = false;
    retryVisible = false;
    helpKey = messageKey;
    helpSuffix = '';

    notifyListeners();
  }

  void setHelp(String key, {String suffix = ''}) {
    helpKey = key;
    helpSuffix = suffix;
    notifyListeners();
  }

  void _clearState() {
    hasMainKey = false;
    modifierOnly = false;
    _heldModifiers = 0;
    _heldKeys.clear();
    modifiers = 0;
    mainKey = 0;
    modifierOrder.clear();
  }

  int _heldModifiers = 0;
  final Set<int> _heldKeys = <int>{};

  bool modifierOnly = false;

  bool get complete => hasMainKey || modifierOnly;

  void processKeyDown(int key) {
    if (!recording) {
      return;
    }

    _heldKeys.add(key);

    if (isModifierKey(key)) {
      final int modifier = modifierForKey(key);

      if (_heldModifiers == 0) {
        modifiers = 0;
        modifierOrder.clear();
      }

      _heldModifiers |= modifier;

      final bool alreadyRecorded = (modifiers & modifier) != 0;
      modifiers |= modifier;

      if (!alreadyRecorded) {
        modifierOrder.add(modifier);
      }

      retryVisible = true;
      helpKey = 'ShortcutHelp';
      helpSuffix = '';
      notifyListeners();
      return;
    }

    if (hasMainKey) {
      reset('ResetShortcut');
      return;
    }

    final int held = _heldModifiers;

    final String? problem = ShortcutRules.validate(held, key);
    if (problem != null) {
      final Set<int> stillHeld = Set<int>.of(_heldKeys);
      reset(problem);

      _heldKeys.addAll(stillHeld);
      _heldModifiers = held;
      return;
    }

    modifiers = held;
    modifierOrder.removeWhere((int m) => (held & m) == 0);
    mainKey = key;
    hasMainKey = true;

    recording = false;
    paused = false;
    retryVisible = true;

    helpKey = 'ValidShortcut';
    helpSuffix = '';

    notifyListeners();
  }

  void processKeyUp(int key) {
    if (!recording) {
      _heldKeys.remove(key);
      if (isModifierKey(key)) {
        _heldModifiers &= ~modifierForKey(key);
      }
      return;
    }

    final bool wasDown = _heldKeys.remove(key);

    if (!isModifierKey(key)) {
      if (!wasDown) {

        processKeyDown(key);
        _heldKeys.remove(key);
      }
      return;
    }

    _heldModifiers &= ~modifierForKey(key);

    if (_heldModifiers != 0 || hasMainKey) {
      return;
    }

    final String? problem = ShortcutRules.validate(modifiers, 0);

    if (problem == null) {
      modifierOnly = true;
      recording = false;
      paused = false;
      retryVisible = true;
      helpKey = 'ValidShortcut';
      helpSuffix = '';
      notifyListeners();
      return;
    }

    _clearState();
    retryVisible = false;
    helpKey = 'ShortcutHelp';
    helpSuffix = '';
    notifyListeners();
  }

  ShortcutDefinition? tryBuild() {
    if (!complete) {
      setHelp('InvalidShortcut');
      return null;
    }

    final int key = hasMainKey ? mainKey : 0;
    final String? problem = ShortcutRules.validate(modifiers, key);

    if (problem != null) {
      setHelp(problem);
      return null;
    }

    return ShortcutDefinition(modifiers, key);
  }

  String modifiersText() {
    final List<String> parts = <String>[];

    for (final int modifier in modifierOrder) {
      if (modifier == ShortcutDefinition.modControl) {
        parts.add('Ctrl');
      } else if (modifier == ShortcutDefinition.modAlt) {
        parts.add('Alt');
      } else if (modifier == ShortcutDefinition.modShift) {
        parts.add('Shift');
      }
    }

    return parts.join(' + ');
  }

  List<String> displayParts() {
    final List<String> parts = <String>[];

    for (final int modifier in modifierOrder) {
      if (modifier == ShortcutDefinition.modControl) {
        parts.add('Ctrl');
      } else if (modifier == ShortcutDefinition.modAlt) {
        parts.add('Alt');
      } else if (modifier == ShortcutDefinition.modShift) {
        parts.add('Shift');
      }
    }

    if (mainKey != 0) {
      parts.add(mainKeyDisplayText(mainKey));
    }

    return parts;
  }

  String recorderText(String placeholder) {
    if (mainKey == 0) {
      final String mods = modifiersText();
      return mods.isEmpty ? placeholder : mods;
    }

    final String mods = modifiersText();
    final String main = mainKeyDisplayText(mainKey);

    return mods.isEmpty ? main : '$mods + $main';
  }

  static String mainKeyDisplayText(int key) => ShortcutDefinition.keyName(key);

  static bool isModifierKey(int key) {
    return key == virtualKeyCtrl ||
        key == virtualKeyShift ||
        key == virtualKeyAlt;
  }

  static int modifierForKey(int key) {
    switch (key) {
      case virtualKeyCtrl:
        return ShortcutDefinition.modControl;
      case virtualKeyAlt:
        return ShortcutDefinition.modAlt;
      case virtualKeyShift:
        return ShortcutDefinition.modShift;
      default:
        return 0;
    }
  }
}
