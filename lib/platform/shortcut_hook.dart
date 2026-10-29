import 'dart:io';

import '../core/shortcut_definition.dart';
import 'linux/linux_hook.dart';
import 'macos/mac_hook.dart';
import 'windows/keyboard_hook.dart';

const int kHookPermissionDenied = -2;
const int kHookNoDisplay = -10;
const int kHookUnsupported = -11;
const int kHookGrabFailed = -12;

abstract class ShortcutHook {
  ShortcutDefinition get shortcut;
  bool get installed;
  int get errorCode;
  Stream<void> get pressed;
  void dispose();
}

Future<ShortcutHook> startShortcutHook(ShortcutDefinition shortcut) {
  if (Platform.isWindows) {
    return KeyboardHook.start(shortcut);
  }
  if (Platform.isMacOS) {
    return MacKeyboardHook.start(shortcut);
  }
  return LinuxKeyboardHook.start(shortcut);
}
