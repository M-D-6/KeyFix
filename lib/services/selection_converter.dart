import 'dart:async';
import 'dart:io';

import '../core/conversion_result.dart';
import '../core/keyboard_converter.dart';
import '../core/shortcut_definition.dart';
import '../platform/platform_interop.dart';

enum _ReleaseResult { released, focusChanged, timedOut }

enum _ClipboardWait { changed, focusChanged, timedOut }

class SelectionConverter {
  SelectionConverter(this._converter, this._shortcut, this._os);

  final KeyboardConverter _converter;
  final PlatformInterop _os;

  ShortcutDefinition _shortcut;

  bool autoSwitchKeyboardLanguage = true;

  bool _running = false;

  void updateShortcut(ShortcutDefinition shortcut) {
    _shortcut = shortcut;
  }

  static Future<void> _delay(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  bool _stillForeground(int target) {
    return target != 0 && _os.foregroundWindow() == target;
  }

  Future<ConversionResult> convertSelectedText() async {

    if (_running) {
      return ConversionResult.focusChanged;
    }
    _running = true;

    ClipboardSnapshotHandle? snapshot;
    bool clipboardDirty = false;

    try {
      final int target = _os.foregroundWindow();
      if (target == 0) {
        return ConversionResult.focusChanged;
      }

      final _ReleaseResult release = await _waitForHotKeyRelease(target);
      if (release == _ReleaseResult.focusChanged) {
        return ConversionResult.focusChanged;
      }
      if (release == _ReleaseResult.timedOut) {
        return ConversionResult.inputInjectionFailed;
      }

      if (!_stillForeground(target)) {
        return ConversionResult.focusChanged;
      }

      snapshot = await _os.saveClipboard();
      if (snapshot.containsUnsupportedData) {
        return ConversionResult.clipboardError;
      }

      if (!_stillForeground(target)) {
        return ConversionResult.focusChanged;
      }

      String? selectedText = await _os.readSelectionDirect();

      if (selectedText == null) {
        String? sentinel;

        if (_os.needsCopySentinel && snapshot.canRestore) {
          sentinel = '\u200B${DateTime.now().microsecondsSinceEpoch}';
          clipboardDirty = true;
          if (!await _os.setClipboardText(sentinel)) {
            return ConversionResult.clipboardError;
          }
        }

        final int sequenceBeforeCopy = await _os.clipboardSequenceNumber();

        if (!_stillForeground(target) || !_os.sendCopy()) {
          return ConversionResult.inputInjectionFailed;
        }

        final _ClipboardWait wait =
            await _waitForClipboardChange(sequenceBeforeCopy, target, 500);

        if (wait == _ClipboardWait.focusChanged) {
          return ConversionResult.focusChanged;
        }
        if (wait == _ClipboardWait.timedOut) {
          return ConversionResult.noSelectionFound;
        }

        selectedText = await _waitForClipboardText(target, 300);

        if (sentinel != null && selectedText == sentinel) {
          selectedText = null;
        }
      }

      if (selectedText == null || selectedText.isEmpty) {
        return ConversionResult.noSelectionFound;
      }

      if (!_stillForeground(target)) {
        return ConversionResult.focusChanged;
      }

      final String converted = _converter.convertAutomatically(selectedText);

      if (converted.isEmpty || converted == selectedText) {
        return ConversionResult.nothingToConvert;
      }

      if (!_stillForeground(target)) {
        return ConversionResult.focusChanged;
      }

      clipboardDirty = true;
      final bool clipboardSet =
          await _setClipboardTextWithRetry(converted, target, 250);

      if (!clipboardSet) {
        return ConversionResult.clipboardError;
      }

      final int sequenceAfterOurSet = await _os.clipboardSequenceNumber();

      if (!_stillForeground(target) || !_os.sendPaste()) {
        return ConversionResult.inputInjectionFailed;
      }

      await _delay(Platform.isWindows ? 80 : 200);

      if (_stillForeground(target) &&
          (await _os.clipboardSequenceNumber()) != sequenceAfterOurSet) {
        clipboardDirty = false;
      }

      if (autoSwitchKeyboardLanguage && _stillForeground(target)) {
        await _setKeyboardLanguageFromLastLetter(target, converted);
      }

      return ConversionResult.success;
    } catch (_) {
      return ConversionResult.clipboardError;
    } finally {
      if (snapshot != null) {
        if (clipboardDirty && snapshot.canRestore) {
          try {
            await _os.restoreClipboard(snapshot);
          } catch (_) {}
        }
        _os.disposeSnapshot(snapshot);
      }
      _running = false;
    }
  }

  Future<void> _setKeyboardLanguageFromLastLetter(int target, String text) async {
    if (target == 0 || text.isEmpty) {
      return;
    }

    if (_os.foregroundWindow() != target) {
      return;
    }

    for (int i = text.length - 1; i >= 0; i--) {
      final int unit = text.codeUnitAt(i);

      if (KeyboardConverter.isPersianCharacter(unit)) {
        await _os.setForegroundLanguage(persian: true);
        return;
      }

      if (KeyboardConverter.isEnglishLetter(unit)) {
        await _os.setForegroundLanguage(persian: false);
        return;
      }
    }
  }

  Future<_ReleaseResult> _waitForHotKeyRelease(int target) async {
    const int timeout = 1200;
    final int poll = _os.pollIntervalMs;

    int elapsed = 0;

    while (elapsed < timeout) {
      if (!_stillForeground(target)) {
        return _ReleaseResult.focusChanged;
      }

      if (!_os.areShortcutKeysDown(_shortcut)) {
        return _ReleaseResult.released;
      }

      await _delay(poll);
      elapsed += poll;
    }

    return _ReleaseResult.timedOut;
  }

  Future<_ClipboardWait> _waitForClipboardChange(
    int previousSequence,
    int target,
    int timeoutMs,
  ) async {
    final int poll = _os.pollIntervalMs;
    int elapsed = 0;

    while (elapsed < timeoutMs) {
      if (!_stillForeground(target)) {
        return _ClipboardWait.focusChanged;
      }

      if ((await _os.clipboardSequenceNumber()) != previousSequence) {
        return _ClipboardWait.changed;
      }

      await _delay(poll);
      elapsed += poll;
    }

    if (!_stillForeground(target)) {
      return _ClipboardWait.focusChanged;
    }

    return _ClipboardWait.timedOut;
  }

  Future<String?> _waitForClipboardText(int target, int timeoutMs) async {
    final int poll = _os.pollIntervalMs;
    int elapsed = 0;

    while (elapsed < timeoutMs) {
      if (!_stillForeground(target)) {
        return null;
      }

      final String? text = await _os.getClipboardText();
      if (text != null && text.isNotEmpty) {
        return text;
      }

      await _delay(poll);
      elapsed += poll;
    }

    return null;
  }

  Future<bool> _setClipboardTextWithRetry(
    String text,
    int target,
    int timeoutMs,
  ) async {
    final int retry = _os.pollIntervalMs;
    int elapsed = 0;

    while (elapsed < timeoutMs) {
      if (!_stillForeground(target)) {
        return false;
      }

      if (await _os.setClipboardText(text)) {
        return true;
      }

      await _delay(retry);
      elapsed += retry;
    }

    return false;
  }
}
