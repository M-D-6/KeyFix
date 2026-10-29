import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../core/shortcut_definition.dart';
import '../shortcut_hook.dart';
import 'win32.dart' as w;

class KeyboardHook implements ShortcutHook {
  KeyboardHook._(
    this.shortcut,
    this._port,
    this._isolate,
    this._threadId,
    this.installed,
    this.errorCode,
  );

  @override
  final ShortcutDefinition shortcut;
  final ReceivePort _port;
  final Isolate? _isolate;
  final int _threadId;
  bool _disposed = false;

  @override
  final bool installed;

  @override
  final int errorCode;

  final StreamController<void> _pressed = StreamController<void>.broadcast();

  @override
  Stream<void> get pressed => _pressed.stream;

  static void Function(String line)? onLog;

  static Future<KeyboardHook> start(ShortcutDefinition shortcut) async {
    final ReceivePort port = ReceivePort();
    final Completer<List<Object?>> ready = Completer<List<Object?>>();
    StreamController<void>? forward;

    final Isolate isolate = await Isolate.spawn<List<Object?>>(
      _hookIsolateMain,
      <Object?>[port.sendPort, shortcut.modifiers, shortcut.virtualKey],
      debugName: 'KeyFix Keyboard Hook',
    );

    port.listen((dynamic message) {
      if (message is List && message.isNotEmpty) {
        if (message[0] == 'ready') {
          if (!ready.isCompleted) {
            ready.complete(message.cast<Object?>());
          }
        } else if (message[0] == 'log') {
          onLog?.call(message[1] as String);
        }
        return;
      }

      if (message == 'pressed') {
        final StreamController<void>? sink = forward;
        if (sink != null && !sink.isClosed) {
          sink.add(null);
        }
      }
    });

    final List<Object?> info = await ready.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => <Object?>['ready', 0, false, -1],
    );

    final KeyboardHook hook = KeyboardHook._(
      shortcut,
      port,
      isolate,
      info[1] as int,
      info[2] as bool,
      info[3] as int,
    );
    forward = hook._pressed;

    if (!hook.installed) {
      hook.dispose();
    }

    return hook;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;

    if (_threadId != 0) {

      w.PostThreadMessageW(_threadId, w.WM_QUIT, 0, 0);
    }

    Timer(const Duration(milliseconds: 300), () {
      _isolate?.kill(priority: Isolate.immediate);
      _port.close();
    });

    _pressed.close();
  }
}

SendPort? _out;
int _wantedModifiers = 0;
int _wantedKey = 0;
int _hookHandle = 0;

bool _chordArmed = false;
bool _chordTainted = false;

bool _swallowing = false;

const int _vkLShift = 0xA0, _vkRShift = 0xA1;
const int _vkLCtrl = 0xA2, _vkRCtrl = 0xA3;
const int _vkLAlt = 0xA4, _vkRAlt = 0xA5;

bool _isModifierVk(int vk) {
  return vk == w.VK_SHIFT ||
      vk == w.VK_CONTROL ||
      vk == w.VK_MENU ||
      (vk >= _vkLShift && vk <= _vkRAlt) ||
      vk == w.VK_LWIN ||
      vk == w.VK_RWIN;
}

int _modifierBit(int vk) {
  switch (vk) {
    case w.VK_SHIFT:
    case _vkLShift:
    case _vkRShift:
      return ShortcutDefinition.modShift;
    case w.VK_CONTROL:
    case _vkLCtrl:
    case _vkRCtrl:
      return ShortcutDefinition.modControl;
    case w.VK_MENU:
    case _vkLAlt:
    case _vkRAlt:
      return ShortcutDefinition.modAlt;
    case w.VK_LWIN:
    case w.VK_RWIN:
      return ShortcutDefinition.modWin;
    default:
      return 0;
  }
}

bool _down(int vk) => (w.GetAsyncKeyState(vk) & 0x8000) != 0;

int _heldModifiers(int eventVk, bool eventDown) {
  int mods = 0;

  final int eventBit = _modifierBit(eventVk);

  bool group(int bit, List<int> keys) {
    if (eventBit == bit) {

      if (eventDown) return true;
      for (final int k in keys) {
        if (k != eventVk && _down(k)) return true;
      }
      return false;
    }
    for (final int k in keys) {
      if (_down(k)) return true;
    }
    return false;
  }

  if (group(ShortcutDefinition.modShift, <int>[_vkLShift, _vkRShift])) {
    mods |= ShortcutDefinition.modShift;
  }
  if (group(ShortcutDefinition.modControl, <int>[_vkLCtrl, _vkRCtrl])) {
    mods |= ShortcutDefinition.modControl;
  }
  if (group(ShortcutDefinition.modAlt, <int>[_vkLAlt, _vkRAlt])) {
    mods |= ShortcutDefinition.modAlt;
  }
  if (group(ShortcutDefinition.modWin, <int>[w.VK_LWIN, w.VK_RWIN])) {
    mods |= ShortcutDefinition.modWin;
  }

  return mods;
}

void _firePressed() {
  try {
    _out?.send('pressed');
  } catch (_) {}
}

void _sendMask() {
  final int size = w.inputSize;
  final Pointer<Uint8> buffer = calloc<Uint8>(size * 2);
  try {
    final ByteData view = ByteData.sublistView(buffer.asTypedList(size * 2));
    for (int i = 0; i < 2; i++) {
      final int base = i * size;
      view.setUint32(base, w.INPUT_KEYBOARD, Endian.little);
      final int kb = base + w.inputUnionOffset;
      view.setUint16(kb, w.VK_MASK, Endian.little);
      view.setUint32(kb + 4, i == 0 ? 0 : w.KEYEVENTF_KEYUP, Endian.little);
    }
    w.SendInput(2, buffer.cast<Void>(), size);
  } finally {
    calloc.free(buffer);
  }
}

bool get _maskNeeded =>
    (_wantedModifiers & (ShortcutDefinition.modAlt | ShortcutDefinition.modWin)) !=
    0;

bool _handle(int message, int vk, bool down, int mods) {
  final bool modifierEvent = _isModifierVk(vk);

  if (_wantedKey == 0) {
    if (!modifierEvent) {
      if (down) {

        _chordTainted = mods != 0;
        if (mods != 0) {
          _chordArmed = false;
        }
      }
      return false;
    }

    if (down) {
      if ((mods & ~_wantedModifiers) != 0) {

        _chordTainted = true;
        _chordArmed = false;
      } else if (mods == _wantedModifiers && !_chordArmed && !_chordTainted) {
        _chordArmed = true;

        _sendMask();
      }
      return false;
    }

    final bool fire = _chordArmed && !_chordTainted;
    _chordArmed = false;

    if (mods == 0) {
      _chordTainted = false;
    }

    if (fire) {
      _firePressed();
    }
    return false;
  }

  if (modifierEvent) {
    return false;
  }

  if (vk != _wantedKey) {

    if (down) {
      _swallowing = false;
    }
    return false;
  }

  if (down) {
    if (_swallowing) {
      return true;
    }

    if (mods != _wantedModifiers) {
      return false;
    }

    _swallowing = true;
    if (_maskNeeded) {
      _sendMask();
    }
    _firePressed();
    return true;
  }

  if (_swallowing) {
    _swallowing = false;
    return true;
  }
  return false;
}

int _hookProc(int nCode, int wParam, int lParam) {
  try {
    if (nCode == w.HC_ACTION) {

      final Pointer<Uint32> data = Pointer<Uint32>.fromAddress(lParam);
      final int vk = data[0];
      final int flags = data[2];

      if ((flags & w.LLKHF_INJECTED) == 0) {
        final bool down =
            wParam == w.WM_KEYDOWN || wParam == w.WM_SYSKEYDOWN;
        final bool up = wParam == w.WM_KEYUP || wParam == w.WM_SYSKEYUP;

        if (down || up) {
          if (_wantedKey == 0 || vk == _wantedKey) {
            final int mods = _heldModifiers(vk, down);
            if (_handle(wParam, vk, down, mods)) {
              return 1;
            }
          } else if (down && !_isModifierVk(vk)) {
            _swallowing = false;
          }
        }
      }
    }
  } catch (_) {

  }

  return w.CallNextHookEx(0, nCode, wParam, lParam);
}

void _hookIsolateMain(List<Object?> args) {
  _out = args[0] as SendPort;
  _wantedModifiers = args[1] as int;
  _wantedKey = args[2] as int;

  final Pointer<Void> msg = calloc<Uint8>(w.msgSize).cast<Void>();

  try {

    w.PeekMessageW(msg, 0, 0, 0, 0);

    final int threadId = w.GetCurrentThreadId();

    final Pointer<NativeFunction<w.HookProcNative>> callback =
        Pointer.fromFunction<w.HookProcNative>(_hookProc, 0);

    _hookHandle = w.SetWindowsHookExW(
      w.WH_KEYBOARD_LL,
      callback,
      w.GetModuleHandleW(nullptr),
      0,
    );

    final bool ok = _hookHandle != 0;
    final int error = ok ? 0 : w.GetLastError();

    _out!.send(<Object?>['ready', threadId, ok, error]);

    if (!ok) {
      return;
    }

    while (true) {
      final int result = w.GetMessageW(msg, 0, 0, 0);
      if (result == -1 || result == 0) {
        break;
      }
    }

    w.UnhookWindowsHookEx(_hookHandle);
    _hookHandle = 0;
  } finally {
    calloc.free(msg);
  }
}
