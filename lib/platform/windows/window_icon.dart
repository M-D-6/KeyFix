import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'win32.dart' as w;

void applyWindowIcon() {
  try {
    final String exeDir = File(Platform.resolvedExecutable).parent.path;
    final String icon =
        '$exeDir\\data\\flutter_assets\\assets\\KeyFix.ico';
    if (!File(icon).existsSync()) {
      return;
    }

    final Pointer<Utf16> className =
        'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
    final Pointer<Utf16> path = icon.toNativeUtf16();

    try {
      final int window = w.FindWindowW(className, nullptr);
      if (window == 0) {
        return;
      }

      const int wmSetIcon = 0x0080;
      const int imageIcon = 1;
      const int loadFromFile = 0x0010;

      final int small = w.LoadImageW(0, path, imageIcon, 16, 16, loadFromFile);
      final int big = w.LoadImageW(0, path, imageIcon, 32, 32, loadFromFile);

      if (small != 0) {
        w.SendMessageW(window, wmSetIcon, 0, small);
      }
      if (big != 0) {
        w.SendMessageW(window, wmSetIcon, 1, big);
      }
    } finally {
      calloc.free(className);
      calloc.free(path);
    }
  } catch (_) {}
}
