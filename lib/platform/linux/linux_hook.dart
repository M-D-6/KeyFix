import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../../core/shortcut_definition.dart';
import '../../core/shortcut_matcher.dart';
import '../isolate_hook.dart';
import '../key_tables.dart';
import '../shortcut_hook.dart';
import 'x11.dart' as x;

class LinuxKeyboardHook {
  LinuxKeyboardHook._();

  static Future<ShortcutHook> start(ShortcutDefinition shortcut) {
    return IsolateShortcutHook.start(
      shortcut,
      _linuxHookMain,
      'KeyFix Keyboard Hook',
    );
  }
}

const int _keyShiftL = 50;
const int _keyShiftR = 62;
const int _keyCtrlL = 37;
const int _keyCtrlR = 105;
const int _keyAltL = 64;
const int _keyAltR = 108;
const int _keyMetaL = 133;
const int _keyMetaR = 134;

int _modifierBitFor(int keycode) {
  switch (keycode) {
    case _keyShiftL:
    case _keyShiftR:
      return ShortcutDefinition.modShift;
    case _keyCtrlL:
    case _keyCtrlR:
      return ShortcutDefinition.modControl;
    case _keyAltL:
    case _keyAltR:
      return ShortcutDefinition.modAlt;
    case _keyMetaL:
    case _keyMetaR:
      return ShortcutDefinition.modWin;
    default:
      return 0;
  }
}

bool _held(Pointer<Uint8> keymap, int first, int second, int eventKey, bool eventDown) {
  bool state(int keycode) {
    if (keycode == eventKey) {
      return eventDown;
    }
    return x.keymapBit(keymap, keycode);
  }

  return state(first) || state(second);
}

int _modifiersFromKeymap(Pointer<Uint8> keymap, int eventKey, bool eventDown) {
  int mods = 0;
  if (_held(keymap, _keyShiftL, _keyShiftR, eventKey, eventDown)) {
    mods |= ShortcutDefinition.modShift;
  }
  if (_held(keymap, _keyCtrlL, _keyCtrlR, eventKey, eventDown)) {
    mods |= ShortcutDefinition.modControl;
  }
  if (_held(keymap, _keyAltL, _keyAltR, eventKey, eventDown)) {
    mods |= ShortcutDefinition.modAlt;
  }
  if (_held(keymap, _keyMetaL, _keyMetaR, eventKey, eventDown)) {
    mods |= ShortcutDefinition.modWin;
  }
  return mods;
}

int _x11ModifierMask(int modifiers) {
  int mask = 0;
  if ((modifiers & ShortcutDefinition.modShift) != 0) {
    mask |= x.xShiftMask;
  }
  if ((modifiers & ShortcutDefinition.modControl) != 0) {
    mask |= x.xControlMask;
  }
  if ((modifiers & ShortcutDefinition.modAlt) != 0) {
    mask |= x.xMod1Mask;
  }
  if ((modifiers & ShortcutDefinition.modWin) != 0) {
    mask |= x.xMod4Mask;
  }
  return mask;
}

int _setupGrabs(int display, int root, int modifiers, int keycode) {
  final int mask = _x11ModifierMask(modifiers);
  bool failed = false;

  x.withoutXErrors<void>(
    display,
    () {
      for (final int lock in const <int>[
        0,
        x.xLockMask,
        x.xMod2Mask,
        x.xLockMask | x.xMod2Mask,
      ]) {
        x.XGrabKey(display, keycode, mask | lock, root, 1, 1, 1);
      }
    },
    onError: () => failed = true,
  );

  if (failed) {
    return kHookGrabFailed;
  }

  x.XkbSetDetectableAutoRepeat(display, 1, nullptr);
  return 0;
}

int _inputOpcode = 0;

int _setupRaw(int display, int root) {
  final Pointer<Int32> info = calloc<Int32>(3);
  final Pointer<Utf8> name = 'XInputExtension'.toNativeUtf8();
  final Pointer<Uint8> mask = calloc<Uint8>(x.xiMaskLength);
  final Pointer<Uint8> eventMask = calloc<Uint8>(16);

  try {
    final int present = x.XQueryExtension(
      display,
      name,
      info,
      x.offsetPointer(info, 4),
      x.offsetPointer(info, 8),
    );
    if (present == 0) {
      return kHookUnsupported;
    }
    _inputOpcode = info[0];

    info[1] = 2;
    info[2] = 0;
    if (x.XIQueryVersion(display, x.offsetPointer(info, 4), x.offsetPointer(info, 8)) != 0) {
      return kHookUnsupported;
    }

    mask[1] = 0x60;
    eventMask.cast<Int32>()[0] = x.xiAllMasterDevices;
    eventMask.cast<Int32>()[1] = x.xiMaskLength;
    eventMask.cast<IntPtr>()[1] = mask.address;

    bool failed = false;
    x.withoutXErrors<void>(
      display,
      () => x.XISelectEvents(display, root, eventMask, 1),
      onError: () => failed = true,
    );

    return failed ? kHookUnsupported : 0;
  } finally {
    calloc.free(info);
    calloc.free(name);
    calloc.free(mask);
    calloc.free(eventMask);
  }
}

void _linuxHookMain(List<Object?> args) {
  final SendPort out = args[0] as SendPort;
  final int modifiers = args[1] as int;
  final int key = args[2] as int;
  final Pointer<Int32> stop = Pointer<Int32>.fromAddress(args[3] as int);

  bool readySent = false;
  int display = 0;
  Pointer<Uint8>? event;
  Pointer<Uint8>? keymap;
  Pointer<Uint8>? pollFd;

  void ready(bool ok, int error) {
    if (!readySent) {
      readySent = true;
      out.send(<Object?>['ready', ok, error]);
    }
  }

  try {
    display = x.XOpenDisplay(nullptr);
    if (display == 0) {
      ready(false, kHookNoDisplay);
      return;
    }

    final int root = x.XDefaultRootWindow(display);
    final bool grabMode = key != 0;
    final int? evdev = vkToEvdev[key];
    final int wantedKeycode = evdev == null ? 0 : evdev + 8;

    if (grabMode && evdev == null) {
      ready(false, kHookUnsupported);
      return;
    }

    final int error = grabMode
        ? _setupGrabs(display, root, modifiers, wantedKeycode)
        : _setupRaw(display, root);

    if (error != 0) {
      ready(false, error);
      return;
    }

    event = calloc<Uint8>(x.xEventSize);
    keymap = calloc<Uint8>(32);
    pollFd = calloc<Uint8>(8);
    pollFd.cast<Int32>().value = x.XConnectionNumber(display);
    pollFd.cast<Int16>()[2] = 1;

    final ShortcutMatcher matcher = ShortcutMatcher(modifiers, key);
    bool keyDown = false;

    ready(true, 0);

    while (stop.value == 0) {
      while (x.XPending(display) > 0) {
        x.XNextEvent(display, event);
        final int type = event.cast<Int32>().value;

        if (grabMode) {
          if (type == x.xKeyPress) {
            if (!keyDown) {
              keyDown = true;
              out.send('pressed');
            }
          } else if (type == x.xKeyRelease) {
            keyDown = false;
          }
          continue;
        }

        if (type != x.xGenericEvent) {
          continue;
        }
        if (x.readInt32At(event, 32) != _inputOpcode) {
          continue;
        }
        if (x.XGetEventData(display, event) == 0) {
          continue;
        }

        try {
          final int evtype = x.readInt32At(event, 36);
          final int data = x.readIntPtrAt(event, 48);
          if (data == 0) {
            continue;
          }

          final Pointer<Uint8> raw = Pointer<Uint8>.fromAddress(data);
          final int keycode = x.readInt32At(raw, 56);
          final int flags = x.readInt32At(raw, 60);
          final bool down = evtype == x.xiRawKeyPress;

          if (evtype != x.xiRawKeyPress && evtype != x.xiRawKeyRelease) {
            continue;
          }
          if (down && (flags & x.xiKeyRepeatFlag) != 0) {
            continue;
          }

          x.XQueryKeymap(display, keymap);
          final int mods = _modifiersFromKeymap(keymap, keycode, down);
          final bool modifierEvent = _modifierBitFor(keycode) != 0;
          final int vk = evdevToVk[keycode - 8] ?? 0;

          final MatchDecision decision = matcher.handle(
            modifierEvent: modifierEvent,
            virtualKey: vk,
            down: down,
            mods: mods,
          );
          if (decision.fire) {
            out.send('pressed');
          }
        } finally {
          x.XFreeEventData(display, event);
        }
      }

      x.poll(pollFd, 1, 250);
    }
  } catch (e) {
    ready(false, kHookUnsupported);
    out.send(<Object?>['log', 'Linux keyboard hook failed: $e']);
  } finally {
    if (event != null) {
      calloc.free(event);
    }
    if (keymap != null) {
      calloc.free(keymap);
    }
    if (pollFd != null) {
      calloc.free(pollFd);
    }
    if (display != 0) {
      x.XCloseDisplay(display);
    }
    out.send(<Object?>['exited']);
  }
}
