import '../../core/keyboard_layout_map.dart';
import '../../core/shortcut_definition.dart';
import '../key_tables.dart';
import '../platform_interop.dart';
import 'mac_bindings.dart';
import 'mac_pasteboard.dart';
import 'mac_translator.dart';

const int kMacSyntheticMagic = 0x4B465831;

const int _keyC = 8;
const int _keyV = 9;
const int _keyCommand = 55;

class MacInterop implements PlatformInterop {
  MacInterop()
      : _english = MacKeyTranslator.forLayouts(kMacEnglishLayouts),
        _persian = MacKeyTranslator.forLayouts(kMacPersianLayouts);

  final MacKeyTranslator _english;
  final MacKeyTranslator _persian;

  @override
  KeyTranslator get englishTranslator => _english.translate;

  @override
  KeyTranslator get persianTranslator => _persian.translate;

  @override
  int get pollIntervalMs => 10;

  @override
  bool get needsCopySentinel => false;

  @override
  String? get setupProblemKey {
    if (!_english.isLoaded || !_persian.isLoaded) {
      return 'MacLayoutsUnavailable';
    }
    return null;
  }

  @override
  int foregroundWindow() {
    return withAutoreleasePool<int>(() {
      final int workspace =
          msg0(objcClass('NSWorkspace'), objcSel('sharedWorkspace'));
      if (workspace == 0) {
        return 1;
      }
      final int app = msg0(workspace, objcSel('frontmostApplication'));
      if (app == 0) {
        return 1;
      }
      final int pid = msg0(app, objcSel('processIdentifier')) & 0xFFFFFFFF;
      return pid == 0 ? 1 : pid;
    });
  }

  @override
  bool areShortcutKeysDown(ShortcutDefinition shortcut) {
    final int flags = CGEventSourceFlagsState(cgSourceStateCombined);
    final int m = shortcut.modifiers;

    if ((m & ShortcutDefinition.modControl) != 0 &&
        (flags & cgFlagControl) != 0) {
      return true;
    }
    if ((m & ShortcutDefinition.modAlt) != 0 && (flags & cgFlagOption) != 0) {
      return true;
    }
    if ((m & ShortcutDefinition.modShift) != 0 && (flags & cgFlagShift) != 0) {
      return true;
    }
    if ((m & ShortcutDefinition.modWin) != 0 && (flags & cgFlagCommand) != 0) {
      return true;
    }

    final int? code = vkToMacKeyCode[shortcut.virtualKey];
    if (code != null &&
        (CGEventSourceKeyState(cgSourceStateCombined, code) & 0xFF) != 0) {
      return true;
    }
    return false;
  }

  @override
  String? readSelectionDirect() => null;

  bool _sendCommandKey(int keyCode) {
    final int source = CGEventSourceCreate(cgSourceStatePrivate);
    if (source == 0) {
      return false;
    }

    try {
      void post(int code, bool down, int flags) {
        final int event = CGEventCreateKeyboardEvent(source, code, down ? 1 : 0);
        if (event == 0) {
          return;
        }
        CGEventSetFlags(event, flags);
        CGEventSetIntegerValueField(
          event,
          cgEventSourceUserData,
          kMacSyntheticMagic,
        );
        CGEventPost(cgHidEventTap, event);
        CFRelease(event);
      }

      post(_keyCommand, true, cgFlagCommand);
      post(keyCode, true, cgFlagCommand);
      post(keyCode, false, cgFlagCommand);
      post(_keyCommand, false, 0);
      return true;
    } finally {
      CFRelease(source);
    }
  }

  @override
  bool sendCopy() => _sendCommandKey(_keyC);

  @override
  bool sendPaste() => _sendCommandKey(_keyV);

  @override
  int clipboardSequenceNumber() => MacPasteboard.changeCount();

  @override
  String? getClipboardText() => MacPasteboard.readText();

  @override
  bool setClipboardText(String text) => MacPasteboard.writeText(text);

  @override
  ClipboardSnapshotHandle saveClipboard() => MacPasteboard.snapshot();

  @override
  bool restoreClipboard(ClipboardSnapshotHandle snapshot) {
    return MacPasteboard.restore(snapshot as MacPasteboardSnapshot);
  }

  @override
  void disposeSnapshot(ClipboardSnapshotHandle snapshot) {}

  @override
  void setForegroundLanguage({required bool persian}) {
    if (persian) {
      _persian.select();
    } else {
      _english.select();
    }
  }
}
