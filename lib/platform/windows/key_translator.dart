import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'win32.dart' as w;

class WindowsKeyTranslator {
  WindowsKeyTranslator._(this.klid, this.layout);

  factory WindowsKeyTranslator.forLayout(String klid) {
    final Pointer<Utf16> name = klid.toNativeUtf16();
    try {

      return WindowsKeyTranslator._(klid, w.LoadKeyboardLayoutW(name, 0));
    } finally {
      calloc.free(name);
    }
  }

  final String klid;

  final int layout;

  bool get isLoaded => layout != 0;

  static const int _vkShift = 0x10;
  static const int _vkCapital = 0x14;

  static const int _doNotChangeState = 0x4;

  String translate(int virtualKey, bool shift, bool capsLock) {
    if (layout == 0) {
      return '';
    }

    final int scanCode =
        w.MapVirtualKeyExW(virtualKey, w.MAPVK_VK_TO_VSC, layout);
    if (scanCode == 0) {
      return '';
    }

    final Pointer<Uint8> state = calloc<Uint8>(256);
    final Pointer<Uint16> buffer = calloc<Uint16>(16);

    try {
      if (shift) {
        state[_vkShift] = 0x80;
      }
      if (capsLock) {
        state[_vkCapital] = 0x01;
      }

      final int count = w.ToUnicodeEx(
        virtualKey,
        scanCode,
        state,
        buffer,
        16,
        _doNotChangeState,
        layout,
      );

      if (count <= 0) {

        return '';
      }

      return String.fromCharCodes(
        List<int>.generate(count, (int i) => buffer[i]),
      );
    } finally {
      calloc.free(state);
      calloc.free(buffer);
    }
  }
}
