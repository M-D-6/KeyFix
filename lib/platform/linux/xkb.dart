// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../key_tables.dart';

DynamicLibrary? _tryOpen() {
  for (final String name in const <String>[
    'libxkbcommon.so.0',
    'libxkbcommon.so',
  ]) {
    try {
      return DynamicLibrary.open(name);
    } catch (_) {}
  }
  return null;
}

final DynamicLibrary? _xkb = _tryOpen();

class _XkbApi {
  _XkbApi(DynamicLibrary lib)
      : contextNew = lib.lookupFunction<IntPtr Function(Int32),
            int Function(int)>('xkb_context_new'),
        contextUnref = lib.lookupFunction<Void Function(IntPtr),
            void Function(int)>('xkb_context_unref'),
        keymapNewFromNames = lib.lookupFunction<
            IntPtr Function(IntPtr, Pointer<IntPtr>, Int32),
            int Function(int, Pointer<IntPtr>, int)>(
          'xkb_keymap_new_from_names',
        ),
        keymapUnref = lib.lookupFunction<Void Function(IntPtr),
            void Function(int)>('xkb_keymap_unref'),
        stateNew = lib.lookupFunction<IntPtr Function(IntPtr),
            int Function(int)>('xkb_state_new'),
        stateUnref = lib.lookupFunction<Void Function(IntPtr),
            void Function(int)>('xkb_state_unref'),
        modGetIndex = lib.lookupFunction<
            Uint32 Function(IntPtr, Pointer<Utf8>),
            int Function(int, Pointer<Utf8>)>('xkb_keymap_mod_get_index'),
        stateUpdateMask = lib.lookupFunction<
            Int32 Function(IntPtr, Uint32, Uint32, Uint32, Uint32, Uint32,
                Uint32),
            int Function(int, int, int, int, int, int, int)>(
          'xkb_state_update_mask',
        ),
        keyGetUtf8 = lib.lookupFunction<
            Int32 Function(IntPtr, Uint32, Pointer<Utf8>, IntPtr),
            int Function(int, int, Pointer<Utf8>, int)>(
          'xkb_state_key_get_utf8',
        );

  final int Function(int) contextNew;
  final void Function(int) contextUnref;
  final int Function(int, Pointer<IntPtr>, int) keymapNewFromNames;
  final void Function(int) keymapUnref;
  final int Function(int) stateNew;
  final void Function(int) stateUnref;
  final int Function(int, Pointer<Utf8>) modGetIndex;
  final int Function(int, int, int, int, int, int, int) stateUpdateMask;
  final int Function(int, int, Pointer<Utf8>, int) keyGetUtf8;
}

_XkbApi? _loadApi() {
  final DynamicLibrary? lib = _xkb;
  if (lib == null) {
    return null;
  }
  try {
    return _XkbApi(lib);
  } catch (_) {
    return null;
  }
}

final _XkbApi? _api = _loadApi();

int _context = 0;

int _sharedContext() {
  if (_context == 0) {
    _context = _api!.contextNew(0);
  }
  return _context;
}

class LinuxKeyTranslator {
  LinuxKeyTranslator._(this.layout, this._keymap, this._state, this._shift,
      this._lock);

  factory LinuxKeyTranslator.forLayout(String layout) {
    final _XkbApi? api = _api;
    if (api == null) {
      return LinuxKeyTranslator._(layout, 0, 0, 0xFFFFFFFF, 0xFFFFFFFF);
    }

    final int context = _sharedContext();
    if (context == 0) {
      return LinuxKeyTranslator._(layout, 0, 0, 0xFFFFFFFF, 0xFFFFFFFF);
    }

    final Pointer<IntPtr> names = calloc<IntPtr>(5);
    final Pointer<Utf8> layoutName = layout.toNativeUtf8();

    try {
      names[2] = layoutName.address;
      final int keymap = api.keymapNewFromNames(context, names, 0);
      if (keymap == 0) {
        return LinuxKeyTranslator._(layout, 0, 0, 0xFFFFFFFF, 0xFFFFFFFF);
      }

      final int state = api.stateNew(keymap);
      if (state == 0) {
        api.keymapUnref(keymap);
        return LinuxKeyTranslator._(layout, 0, 0, 0xFFFFFFFF, 0xFFFFFFFF);
      }

      final Pointer<Utf8> shiftName = 'Shift'.toNativeUtf8();
      final Pointer<Utf8> lockName = 'Lock'.toNativeUtf8();
      final int shift = api.modGetIndex(keymap, shiftName);
      final int lock = api.modGetIndex(keymap, lockName);
      calloc.free(shiftName);
      calloc.free(lockName);

      return LinuxKeyTranslator._(layout, keymap, state, shift, lock);
    } finally {
      calloc.free(names);
      calloc.free(layoutName);
    }
  }

  final String layout;
  final int _keymap;
  final int _state;
  final int _shift;
  final int _lock;

  static const int _invalidMod = 0xFFFFFFFF;

  bool get isLoaded => _state != 0;

  void dispose() {
    final _XkbApi? api = _api;
    if (api == null) {
      return;
    }
    if (_state != 0) {
      api.stateUnref(_state);
    }
    if (_keymap != 0) {
      api.keymapUnref(_keymap);
    }
  }

  String translate(int virtualKey, bool shift, bool capsLock) {
    final _XkbApi? api = _api;
    final int? evdev = vkToEvdev[virtualKey];
    if (api == null || _state == 0 || evdev == null) {
      return '';
    }

    int depressed = 0;
    int locked = 0;
    if (shift && _shift != _invalidMod) {
      depressed = 1 << _shift;
    }
    if (capsLock && _lock != _invalidMod) {
      locked = 1 << _lock;
    }

    api.stateUpdateMask(_state, depressed, 0, locked, 0, 0, 0);

    final Pointer<Utf8> buffer = calloc<Uint8>(32).cast<Utf8>();
    try {
      final int length = api.keyGetUtf8(_state, evdev + 8, buffer, 32);
      if (length <= 0) {
        return '';
      }
      return buffer.toDartString(length: length);
    } finally {
      calloc.free(buffer);
    }
  }
}
