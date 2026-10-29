import 'dart:io';

import 'linux/linux_interop.dart';
import 'macos/mac_bindings.dart';
import 'macos/mac_interop.dart';
import 'platform_interop.dart';
import 'windows/windows_interop.dart';
import 'windows/windows_registry.dart';

const int _defaultAccent = 0xFF0078D4;

PlatformInterop createInterop() {
  if (Platform.isWindows) {
    return WindowsInterop();
  }
  if (Platform.isMacOS) {
    return MacInterop();
  }
  return LinuxInterop();
}

bool accessibilityTrusted() {
  if (!Platform.isMacOS) {
    return true;
  }
  try {
    return (AXIsProcessTrusted() & 0xFF) != 0;
  } catch (_) {
    return false;
  }
}

void promptAccessibility() {
  if (!Platform.isMacOS) {
    return;
  }
  try {
    requestAccessibilityPrompt();
  } catch (_) {}
}

int readAccentColor() {
  try {
    if (Platform.isWindows) {
      final int? abgr = WindowsRegistry.readDword(
        r'Software\Microsoft\Windows\DWM',
        'AccentColor',
      );
      if (abgr != null) {
        final int r = abgr & 0xFF;
        final int g = (abgr >> 8) & 0xFF;
        final int b = (abgr >> 16) & 0xFF;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
      }
    } else if (Platform.isMacOS) {
      final ProcessResult result = Process.runSync(
        'defaults',
        <String>['read', '-g', 'AppleAccentColor'],
      );
      if (result.exitCode != 0) {
        return 0xFF0A84FF;
      }
      switch (int.tryParse(result.stdout.toString().trim())) {
        case -1:
          return 0xFF8E8E93;
        case 0:
          return 0xFFFF453A;
        case 1:
          return 0xFFFF9F0A;
        case 2:
          return 0xFFFFD60A;
        case 3:
          return 0xFF32D74B;
        case 5:
          return 0xFFBF5AF2;
        case 6:
          return 0xFFFF375F;
        default:
          return 0xFF0A84FF;
      }
    }
  } catch (_) {}
  return _defaultAccent;
}
