import 'dart:io';

import 'linux/linux_autostart.dart';
import 'macos/mac_autostart.dart';
import 'windows/windows_registry.dart';

abstract class AutoStart {
  bool isEnabled();
  bool setEnabled(bool enabled);
  void refreshCurrentPath();
}

AutoStart createAutoStart() {
  if (Platform.isWindows) {
    return AutoStartManager();
  }
  if (Platform.isMacOS) {
    return MacAutoStart();
  }
  return LinuxAutoStart();
}
