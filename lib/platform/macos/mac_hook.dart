import 'dart:ffi';
import 'dart:isolate';

import '../../core/shortcut_definition.dart';
import '../../core/shortcut_matcher.dart';
import '../isolate_hook.dart';
import '../key_tables.dart';
import '../shortcut_hook.dart';
import 'mac_bindings.dart';

const int _syntheticMagic = 0x4B465831;

class MacKeyboardHook {
  MacKeyboardHook._();

  static Future<ShortcutHook> start(ShortcutDefinition shortcut) {
    return IsolateShortcutHook.start(
      shortcut,
      _macHookMain,
      'KeyFix Keyboard Hook',
    );
  }
}

const Map<int, int> _deviceMasks = <int, int>{
  56: 0x2,
  60: 0x4,
  59: 0x1,
  62: 0x2000,
  58: 0x20,
  61: 0x40,
  55: 0x8,
  54: 0x10,
};

int _modifiersFromFlags(int flags) {
  int mods = 0;
  if ((flags & cgFlagShift) != 0) {
    mods |= ShortcutDefinition.modShift;
  }
  if ((flags & cgFlagControl) != 0) {
    mods |= ShortcutDefinition.modControl;
  }
  if ((flags & cgFlagOption) != 0) {
    mods |= ShortcutDefinition.modAlt;
  }
  if ((flags & cgFlagCommand) != 0) {
    mods |= ShortcutDefinition.modWin;
  }
  return mods;
}

SendPort? _out;
ShortcutMatcher? _matcher;
int _tap = 0;

int _tapCallback(int proxy, int type, int event, int refcon) {
  try {
    if (type == cgEventTapDisabledByTimeout ||
        type == cgEventTapDisabledByUserInput) {
      if (_tap != 0) {
        CGEventTapEnable(_tap, 1);
      }
      _matcher?.reset();
      return event;
    }

    final ShortcutMatcher? matcher = _matcher;
    if (matcher == null) {
      return event;
    }

    if (CGEventGetIntegerValueField(event, cgEventSourceUserData) ==
        _syntheticMagic) {
      return event;
    }

    final int keyCode = CGEventGetIntegerValueField(event, cgKeyboardEventKeycode);
    final int flags = CGEventGetFlags(event);
    final int mods = _modifiersFromFlags(flags);

    bool modifierEvent = false;
    bool down;

    if (type == cgEventFlagsChanged) {
      final int? mask = _deviceMasks[keyCode];
      if (mask == null) {
        return event;
      }
      modifierEvent = true;
      down = (flags & mask) != 0;
    } else {
      down = type == cgEventKeyDown;
    }

    final int vk = modifierEvent ? 0 : (macKeyCodeToVk[keyCode] ?? 0);

    final MatchDecision decision = matcher.handle(
      modifierEvent: modifierEvent,
      virtualKey: vk,
      down: down,
      mods: mods,
    );

    if (decision.fire) {
      _out?.send('pressed');
    }

    return decision.swallow ? 0 : event;
  } catch (_) {
    return event;
  }
}

void _macHookMain(List<Object?> args) {
  final SendPort out = args[0] as SendPort;
  final int modifiers = args[1] as int;
  final int key = args[2] as int;
  final Pointer<Int32> stop = Pointer<Int32>.fromAddress(args[3] as int);

  bool readySent = false;
  int source = 0;

  void ready(bool ok, int error) {
    if (!readySent) {
      readySent = true;
      out.send(<Object?>['ready', ok, error]);
    }
  }

  try {
    if ((AXIsProcessTrusted() & 0xFF) == 0) {
      ready(false, kHookPermissionDenied);
      return;
    }

    _out = out;
    _matcher = ShortcutMatcher(modifiers, key);

    const int mask = (1 << cgEventKeyDown) |
        (1 << cgEventKeyUp) |
        (1 << cgEventFlagsChanged);

    final Pointer<NativeFunction<TapCallbackNative>> callback =
        Pointer.fromFunction<TapCallbackNative>(_tapCallback, 0);

    _tap = CGEventTapCreate(
      cgSessionEventTap,
      cgHeadInsertEventTap,
      0,
      mask,
      callback,
      0,
    );

    if (_tap == 0) {
      ready(false, kHookPermissionDenied);
      return;
    }

    source = CFMachPortCreateRunLoopSource(0, _tap, 0);
    if (source == 0) {
      ready(false, kHookUnsupported);
      return;
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CGEventTapEnable(_tap, 1);

    ready(true, 0);

    while (stop.value == 0) {
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, 0);
    }
  } catch (e) {
    ready(false, kHookUnsupported);
    out.send(<Object?>['log', 'macOS keyboard hook failed: $e']);
  } finally {
    if (_tap != 0) {
      CGEventTapEnable(_tap, 0);
      CFMachPortInvalidate(_tap);
    }
    if (source != 0) {
      CFRelease(source);
    }
    if (_tap != 0) {
      CFRelease(_tap);
      _tap = 0;
    }
    _matcher = null;
    _out = null;
    out.send(<Object?>['exited']);
  }
}
