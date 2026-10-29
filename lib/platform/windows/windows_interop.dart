import 'dart:ffi';
import 'dart:io' show sleep;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../core/keyboard_layout_map.dart';
import '../../core/shortcut_definition.dart';
import '../platform_interop.dart';
import 'key_translator.dart';
import 'win32.dart' as w;

class _ClipboardEntry {
  _ClipboardEntry(this.format, this.bytes);

  final int format;
  final Uint8List bytes;
}

class _WindowsSnapshot implements ClipboardSnapshotHandle {
  _WindowsSnapshot({
    required this.entries,
    required this.wasEmpty,
    required this.canRestore,
  });

  final List<_ClipboardEntry> entries;
  final bool wasEmpty;

  @override
  final bool canRestore;

  @override
  bool get containsUnsupportedData => !canRestore && !wasEmpty;
}

class WindowsInterop implements PlatformInterop {
  WindowsInterop()
      : _english = WindowsKeyTranslator.forLayout('00000409'),
        _persian = WindowsKeyTranslator.forLayout('00000429');

  final WindowsKeyTranslator _english;
  final WindowsKeyTranslator _persian;

  int get englishTranslatorLayout => _english.layout;
  int get persianTranslatorLayout => _persian.layout;

  int get _englishLayout => _english.layout;
  int get _persianLayout => _persian.layout;

  bool get layoutsAvailable => _english.isLoaded && _persian.isLoaded;

  @override
  KeyTranslator get englishTranslator => _english.translate;

  @override
  KeyTranslator get persianTranslator => _persian.translate;

  @override
  int get pollIntervalMs => 5;

  @override
  bool get needsCopySentinel => false;

  @override
  String? get setupProblemKey => null;

  @override
  String? readSelectionDirect() => null;

  @override
  int foregroundWindow() => w.GetForegroundWindow();

  static bool _isKeyDown(int virtualKey) {
    return (w.GetAsyncKeyState(virtualKey) & 0x8000) != 0;
  }

  @override
  bool areShortcutKeysDown(ShortcutDefinition shortcut) {
    final int m = shortcut.modifiers;

    if ((m & ShortcutDefinition.modControl) != 0 && _isKeyDown(w.VK_CONTROL)) {
      return true;
    }
    if ((m & ShortcutDefinition.modAlt) != 0 && _isKeyDown(w.VK_MENU)) {
      return true;
    }
    if ((m & ShortcutDefinition.modShift) != 0 && _isKeyDown(w.VK_SHIFT)) {
      return true;
    }
    if ((m & ShortcutDefinition.modWin) != 0 &&
        (_isKeyDown(w.VK_LWIN) || _isKeyDown(w.VK_RWIN))) {
      return true;
    }
    if (shortcut.virtualKey != 0 && _isKeyDown(shortcut.virtualKey)) {
      return true;
    }
    return false;
  }

  @override
  bool sendCopy() => _sendKeyChord(w.VK_CONTROL, w.VK_C);

  @override
  bool sendPaste() => _sendKeyChord(w.VK_CONTROL, w.VK_V);

  static bool _sendKeyChord(int modifierVk, int mainVk) {
    const int count = 4;
    final int size = w.inputSize;

    final Pointer<Uint8> buffer = calloc<Uint8>(size * count);

    try {
      final ByteData view = ByteData.sublistView(
        buffer.asTypedList(size * count),
      );

      void write(int index, int vk, {required bool keyUp}) {
        final int base = index * size;
        view.setUint32(base, w.INPUT_KEYBOARD, Endian.little);
        final int kb = base + w.inputUnionOffset;
        view.setUint16(kb, vk, Endian.little);
        view.setUint16(kb + 2, 0, Endian.little);
        view.setUint32(kb + 4, keyUp ? w.KEYEVENTF_KEYUP : 0, Endian.little);
      }

      write(0, modifierVk, keyUp: false);
      write(1, mainVk, keyUp: false);
      write(2, mainVk, keyUp: true);
      write(3, modifierVk, keyUp: true);

      final int sent = w.SendInput(count, buffer.cast<Void>(), size);
      return sent == count;
    } finally {
      calloc.free(buffer);
    }
  }

  @override
  int clipboardSequenceNumber() => w.GetClipboardSequenceNumber();

  @override
  String? getClipboardText() {
    if (w.OpenClipboard(0) == 0) {
      return null;
    }

    try {
      final int handle = w.GetClipboardData(w.CF_UNICODETEXT);
      if (handle == 0) {
        return null;
      }

      final Pointer<Void> pointer = w.GlobalLock(handle);
      if (pointer == nullptr) {
        return null;
      }

      try {
        return pointer.cast<Utf16>().toDartString();
      } finally {
        w.GlobalUnlock(handle);
      }
    } finally {
      w.CloseClipboard();
    }
  }

  @override
  bool setClipboardText(String text) {
    if (w.OpenClipboard(0) == 0) {
      return false;
    }

    int memory = 0;

    try {
      if (w.EmptyClipboard() == 0) {
        return false;
      }

      final Pointer<Utf16> native = text.toNativeUtf16();
      try {
        final int bytes = (text.length + 1) * 2;
        memory = w.GlobalAlloc(w.GMEM_MOVEABLE, bytes);
        if (memory == 0) {
          return false;
        }

        final Pointer<Void> target = w.GlobalLock(memory);
        if (target == nullptr) {
          return false;
        }

        try {
          target
              .cast<Uint8>()
              .asTypedList(bytes)
              .setAll(0, native.cast<Uint8>().asTypedList(bytes));
        } finally {
          w.GlobalUnlock(memory);
        }
      } finally {
        calloc.free(native);
      }

      if (w.SetClipboardData(w.CF_UNICODETEXT, memory) == 0) {
        return false;
      }

      memory = 0;
      return true;
    } finally {
      if (memory != 0) {
        w.GlobalFree(memory);
      }
      w.CloseClipboard();
    }
  }

  static bool _skipFormat(int f) {
    if (f == 2 || f == 3 || f == 9 || f == 14) {
      return true;
    }
    if (f >= 0x0080 && f <= 0x00BF) {
      return true;
    }
    if (f >= 0x0300 && f <= 0x03FF) {
      return true;
    }
    return false;
  }

  static const int _maxEntryBytes = 64 * 1024 * 1024;

  @override
  ClipboardSnapshotHandle saveClipboard() {
    const int attempts = 5;

    for (int attempt = 0; attempt < attempts; attempt++) {
      if (w.OpenClipboard(0) == 0) {
        _sleep(5);
        continue;
      }

      final List<_ClipboardEntry> entries = <_ClipboardEntry>[];
      bool wasEmpty = false;

      try {
        int format = w.EnumClipboardFormats(0);
        if (format == 0) {
          wasEmpty = true;
        }

        while (format != 0) {
          if (!_skipFormat(format)) {
            final _ClipboardEntry? entry = _copyFormat(format);
            if (entry != null) {
              entries.add(entry);
            }
          }
          format = w.EnumClipboardFormats(format);
        }
      } finally {
        w.CloseClipboard();
      }

      if (wasEmpty) {
        return _WindowsSnapshot(
          entries: <_ClipboardEntry>[],
          wasEmpty: true,
          canRestore: true,
        );
      }

      if (entries.isNotEmpty) {
        return _WindowsSnapshot(
          entries: entries,
          wasEmpty: false,
          canRestore: true,
        );
      }

      _sleep(5);
    }

    return _WindowsSnapshot(
      entries: <_ClipboardEntry>[],
      wasEmpty: false,
      canRestore: false,
    );
  }

  static _ClipboardEntry? _copyFormat(int format) {
    try {
      final int handle = w.GetClipboardData(format);
      if (handle == 0) {
        return null;
      }

      final int size = w.GlobalSize(handle);
      if (size <= 0 || size > _maxEntryBytes) {
        return null;
      }

      final Pointer<Void> pointer = w.GlobalLock(handle);
      if (pointer == nullptr) {
        return null;
      }

      try {
        final Uint8List copy =
            Uint8List.fromList(pointer.cast<Uint8>().asTypedList(size));
        return _ClipboardEntry(format, copy);
      } finally {
        w.GlobalUnlock(handle);
      }
    } catch (_) {
      return null;
    }
  }

  @override
  bool restoreClipboard(ClipboardSnapshotHandle snapshot) {
    final _WindowsSnapshot s = snapshot as _WindowsSnapshot;

    const int attempts = 5;

    for (int attempt = 0; attempt < attempts; attempt++) {
      if (w.OpenClipboard(0) == 0) {
        _sleep(5);
        continue;
      }

      try {
        if (w.EmptyClipboard() == 0) {
          return false;
        }

        if (s.wasEmpty) {
          return true;
        }

        bool any = false;

        for (final _ClipboardEntry entry in s.entries) {
          final int memory = w.GlobalAlloc(w.GMEM_MOVEABLE, entry.bytes.length);
          if (memory == 0) {
            continue;
          }

          final Pointer<Void> target = w.GlobalLock(memory);
          if (target == nullptr) {
            w.GlobalFree(memory);
            continue;
          }

          target.cast<Uint8>().asTypedList(entry.bytes.length).setAll(
                0,
                entry.bytes,
              );
          w.GlobalUnlock(memory);

          if (w.SetClipboardData(entry.format, memory) == 0) {
            w.GlobalFree(memory);
          } else {
            any = true;
          }
        }

        return any;
      } finally {
        w.CloseClipboard();
      }
    }

    return false;
  }

  @override
  void disposeSnapshot(ClipboardSnapshotHandle snapshot) {
    (snapshot as _WindowsSnapshot).entries.clear();
  }

  @override
  void setForegroundLanguage({required bool persian}) {
    final int layout = persian ? _persianLayout : _englishLayout;
    if (layout == 0) {
      return;
    }

    final int foreground = w.GetForegroundWindow();
    if (foreground == 0) {
      return;
    }

    w.PostMessageW(foreground, w.WM_INPUTLANGCHANGEREQUEST, 0, layout);
  }

  static void _sleep(int milliseconds) {
    sleep(Duration(milliseconds: milliseconds));
  }
}
