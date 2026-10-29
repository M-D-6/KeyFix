import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../../core/keyboard_layout_map.dart';
import '../../core/shortcut_definition.dart';
import '../key_tables.dart';
import '../platform_interop.dart';
import 'linux_clipboard.dart';
import 'x11.dart' as x;
import 'xkb.dart';

class _LinuxSnapshot implements ClipboardSnapshotHandle {
  _LinuxSnapshot(this.text, this.canRestore);

  final String? text;

  @override
  final bool canRestore;
}

const Set<String> _terminalClasses = <String>{
  'gnome-terminal',
  'gnome-terminal-server',
  'org.gnome.terminal',
  'org.gnome.console',
  'kgx',
  'konsole',
  'xterm',
  'uxterm',
  'kitty',
  'alacritty',
  'tilix',
  'xfce4-terminal',
  'terminator',
  'st',
  'st-256color',
  'urxvt',
  'rxvt',
  'foot',
  'footclient',
  'wezterm',
  'wezterm-gui',
  'ptyxis',
  'lxterminal',
  'mate-terminal',
  'qterminal',
  'sakura',
  'terminology',
  'guake',
  'yakuake',
  'deepin-terminal',
  'io.elementary.terminal',
  'blackbox',
  'contour',
  'ghostty',
  'cool-retro-term',
};

const int _keyCtrl = 37;
const int _keyShift = 50;
const int _keyShiftR = 62;
const int _keyCtrlR = 105;
const int _keyAlt = 64;
const int _keyAltR = 108;
const int _keyMeta = 133;
const int _keyMetaR = 134;

class LinuxInterop implements PlatformInterop {
  LinuxInterop()
      : _english = LinuxKeyTranslator.forLayout('us'),
        _persian = LinuxKeyTranslator.forLayout('ir'),
        _clipboard = LinuxClipboard.detect();

  final LinuxKeyTranslator _english;
  final LinuxKeyTranslator _persian;
  final LinuxClipboard _clipboard;

  int _display = 0;
  bool _displayTried = false;
  final Map<String, int> _atoms = <String, int>{};

  bool get layoutsAvailable => _english.isLoaded && _persian.isLoaded;

  @override
  KeyTranslator get englishTranslator => _english.translate;

  @override
  KeyTranslator get persianTranslator => _persian.translate;

  @override
  int get pollIntervalMs => 20;

  @override
  bool get needsCopySentinel => true;

  @override
  String? get setupProblemKey {
    if (!_clipboard.available) {
      return 'LinuxClipboardToolMissing';
    }
    if (!layoutsAvailable) {
      return 'LinuxLayoutsUnavailable';
    }
    final Map<String, String> env = Platform.environment;
    if ((env['XDG_SESSION_TYPE'] ?? '').toLowerCase() == 'wayland') {
      return 'LinuxWaylandLimited';
    }
    return null;
  }

  int get _dpy {
    if (!_displayTried) {
      _displayTried = true;
      try {
        _display = x.XOpenDisplay(nullptr);
      } catch (_) {
        _display = 0;
      }
    }
    return _display;
  }

  int _atom(int display, String name) {
    final int? cached = _atoms[name];
    if (cached != null) {
      return cached;
    }
    final Pointer<Utf8> native = name.toNativeUtf8();
    try {
      final int atom = x.XInternAtom(display, native, 0);
      _atoms[name] = atom;
      return atom;
    } finally {
      calloc.free(native);
    }
  }

  int _activeWindow(int display) {
    final int root = x.XDefaultRootWindow(display);
    final Pointer<IntPtr> slots = calloc<IntPtr>(5);
    final Pointer<Int32> format = calloc<Int32>();

    try {
      int window = 0;

      x.withoutXErrors<void>(display, () {
        final int status = x.XGetWindowProperty(
          display,
          root,
          _atom(display, '_NET_ACTIVE_WINDOW'),
          0,
          1,
          0,
          33,
          slots,
          format,
          x.offsetPointer(slots, 8),
          x.offsetPointer(slots, 16),
          x.offsetPointer(slots, 24),
        );

        final int items = x.offsetPointer(slots, 8).value;
        final int data = x.offsetPointer(slots, 24).value;

        if (status == 0 && items > 0 && data != 0) {
          window = Pointer<IntPtr>.fromAddress(data).value;
        }
        if (data != 0) {
          x.XFree(data);
        }
      });

      if (window > 1) {
        return window;
      }

      final Pointer<IntPtr> focus = calloc<IntPtr>();
      final Pointer<Int32> revert = calloc<Int32>();
      try {
        x.XGetInputFocus(display, focus, revert);
        return focus.value;
      } finally {
        calloc.free(focus);
        calloc.free(revert);
      }
    } finally {
      calloc.free(slots);
      calloc.free(format);
    }
  }

  bool _isTerminal(int display, int window) {
    if (window <= 1) {
      return false;
    }

    final Pointer<IntPtr> hint = calloc<IntPtr>(2);
    try {
      String name = '';
      String className = '';

      x.withoutXErrors<void>(display, () {
        if (x.XGetClassHint(display, window, hint) != 0) {
          if (hint[0] != 0) {
            name = Pointer<Utf8>.fromAddress(hint[0]).toDartString();
            x.XFree(hint[0]);
          }
          if (hint[1] != 0) {
            className = Pointer<Utf8>.fromAddress(hint[1]).toDartString();
            x.XFree(hint[1]);
          }
        }
      });

      return _terminalClasses.contains(name.toLowerCase()) ||
          _terminalClasses.contains(className.toLowerCase());
    } finally {
      calloc.free(hint);
    }
  }

  bool _terminalFocused() {
    final int display = _dpy;
    if (display == 0) {
      return false;
    }
    return _isTerminal(display, _activeWindow(display));
  }

  @override
  int foregroundWindow() {
    final int display = _dpy;
    if (display == 0) {
      return 1;
    }
    final int window = _activeWindow(display);
    return window > 1 ? window : 1;
  }

  @override
  bool areShortcutKeysDown(ShortcutDefinition shortcut) {
    final int display = _dpy;
    if (display == 0) {
      return false;
    }

    final Pointer<Uint8> keymap = calloc<Uint8>(32);
    try {
      x.XQueryKeymap(display, keymap);

      bool down(int a, int b) =>
          x.keymapBit(keymap, a) || x.keymapBit(keymap, b);

      final int m = shortcut.modifiers;
      if ((m & ShortcutDefinition.modControl) != 0 &&
          down(_keyCtrl, _keyCtrlR)) {
        return true;
      }
      if ((m & ShortcutDefinition.modAlt) != 0 && down(_keyAlt, _keyAltR)) {
        return true;
      }
      if ((m & ShortcutDefinition.modShift) != 0 &&
          down(_keyShift, _keyShiftR)) {
        return true;
      }
      if ((m & ShortcutDefinition.modWin) != 0 && down(_keyMeta, _keyMetaR)) {
        return true;
      }

      final int? evdev = vkToEvdev[shortcut.virtualKey];
      if (evdev != null && x.keymapBit(keymap, evdev + 8)) {
        return true;
      }
      return false;
    } finally {
      calloc.free(keymap);
    }
  }

  @override
  String? readSelectionDirect() {
    if (!_terminalFocused()) {
      return null;
    }
    return _clipboard.read(primary: true) ?? '';
  }

  bool _sendKeys(List<int> modifiers, int keycode) {
    final int display = _dpy;
    if (display == 0) {
      return false;
    }

    try {
      for (final int key in modifiers) {
        x.XTestFakeKeyEvent(display, key, 1, 0);
      }
      x.XTestFakeKeyEvent(display, keycode, 1, 0);
      x.XTestFakeKeyEvent(display, keycode, 0, 0);
      for (final int key in modifiers.reversed) {
        x.XTestFakeKeyEvent(display, key, 0, 0);
      }
      x.XFlush(display);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool sendCopy() {
    final int? evdev = vkToEvdev[0x43];
    return evdev != null && _sendKeys(<int>[_keyCtrl], evdev + 8);
  }

  @override
  bool sendPaste() {
    final int? evdev = vkToEvdev[0x56];
    if (evdev == null) {
      return false;
    }
    final List<int> modifiers =
        _terminalFocused() ? <int>[_keyCtrl, _keyShift] : <int>[_keyCtrl];
    return _sendKeys(modifiers, evdev + 8);
  }

  @override
  int clipboardSequenceNumber() {
    final String? text = _clipboard.read();
    return text == null ? 0 : text.hashCode;
  }

  @override
  String? getClipboardText() => _clipboard.read();

  @override
  bool setClipboardText(String text) => _clipboard.write(text);

  @override
  ClipboardSnapshotHandle saveClipboard() {
    return _LinuxSnapshot(_clipboard.read(), _clipboard.available);
  }

  @override
  bool restoreClipboard(ClipboardSnapshotHandle snapshot) {
    final _LinuxSnapshot s = snapshot as _LinuxSnapshot;
    return _clipboard.write(s.text ?? '');
  }

  @override
  void disposeSnapshot(ClipboardSnapshotHandle snapshot) {}

  @override
  void setForegroundLanguage({required bool persian}) {
    final int display = _dpy;
    if (display == 0) {
      return;
    }

    try {
      final ProcessResult result =
          Process.runSync('setxkbmap', <String>['-query']);
      if (result.exitCode != 0) {
        return;
      }

      String layouts = '';
      for (final String line in result.stdout.toString().split('\n')) {
        if (line.startsWith('layout:')) {
          layouts = line.substring('layout:'.length).trim();
        }
      }
      if (layouts.isEmpty) {
        return;
      }

      final List<String> groups = layouts.split(',');
      int target = -1;
      for (int i = 0; i < groups.length; i++) {
        final bool isPersian = groups[i].trim() == 'ir';
        if (isPersian == persian) {
          target = i;
          break;
        }
      }
      if (target < 0) {
        return;
      }

      x.XkbLockGroup(display, x.xUseCoreKeyboard, target);
      x.XFlush(display);
    } catch (_) {}
  }
}
