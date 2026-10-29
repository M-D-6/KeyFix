import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../key_tables.dart';
import 'mac_bindings.dart';

const List<String> kMacEnglishLayouts = <String>[
  'com.apple.keylayout.ABC',
  'com.apple.keylayout.US',
  'com.apple.keylayout.USExtended',
];

const List<String> kMacPersianLayouts = <String>[
  'com.apple.keylayout.Persian',
  'com.apple.keylayout.Persian-ISIRI2901',
  'com.apple.keylayout.Persian-QWERTY',
];

class MacKeyTranslator {
  MacKeyTranslator._(this._source, this._layout, this._list);

  factory MacKeyTranslator.forLayouts(List<String> ids) {
    for (final String id in ids) {
      final MacKeyTranslator? found = _find(id);
      if (found != null) {
        return found;
      }
    }
    return MacKeyTranslator._(0, 0, 0);
  }

  final int _source;
  final int _layout;
  final int _list;

  bool get isLoaded => _layout != 0;

  static MacKeyTranslator? _find(String id) {
    return withAutoreleasePool<MacKeyTranslator?>(() {
      final Pointer<IntPtr> keys = calloc<IntPtr>();
      final Pointer<IntPtr> values = calloc<IntPtr>();
      try {
        keys[0] = kTISPropertyInputSourceID;
        values[0] = nsString(id);

        final int filter = CFDictionaryCreate(
          0,
          keys,
          values,
          1,
          cfTypeDictionaryKeyCallBacks,
          cfTypeDictionaryValueCallBacks,
        );
        if (filter == 0) {
          return null;
        }

        final int list = TISCreateInputSourceList(filter, 1);
        CFRelease(filter);
        if (list == 0) {
          return null;
        }

        if (CFArrayGetCount(list) < 1) {
          CFRelease(list);
          return null;
        }

        final int source = CFArrayGetValueAtIndex(list, 0);
        final int data =
            TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData);
        final int layout = data == 0 ? 0 : CFDataGetBytePtr(data);

        if (layout == 0) {
          CFRelease(list);
          return null;
        }

        return MacKeyTranslator._(source, layout, list);
      } finally {
        calloc.free(keys);
        calloc.free(values);
      }
    });
  }

  bool select() {
    if (_source == 0) {
      return false;
    }
    return TISSelectInputSource(_source) == 0;
  }

  void dispose() {
    if (_list != 0) {
      CFRelease(_list);
    }
  }

  String translate(int virtualKey, bool shift, bool capsLock) {
    final int? keyCode = vkToMacKeyCode[virtualKey];
    if (_layout == 0 || keyCode == null) {
      return '';
    }

    final int modifierState = (shift ? 2 : 0) | (capsLock ? 4 : 0);

    final Pointer<Uint32> dead = calloc<Uint32>();
    final Pointer<IntPtr> length = calloc<IntPtr>();
    final Pointer<Uint16> chars = calloc<Uint16>(8);

    try {
      final int status = UCKeyTranslate(
        _layout,
        keyCode,
        0,
        modifierState,
        LMGetKbdType(),
        1,
        dead,
        8,
        length,
        chars,
      );

      if (status != 0 || length.value <= 0 || length.value > 8) {
        return '';
      }

      final List<int> units = <int>[
        for (int i = 0; i < length.value; i++) chars[i],
      ];
      return String.fromCharCodes(units);
    } finally {
      calloc.free(dead);
      calloc.free(length);
      calloc.free(chars);
    }
  }
}
