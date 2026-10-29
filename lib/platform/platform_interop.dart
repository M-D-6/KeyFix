import 'dart:async';

import '../core/keyboard_layout_map.dart';
import '../core/shortcut_definition.dart';

abstract class ClipboardSnapshotHandle {
  bool get canRestore;

  bool get containsUnsupportedData => false;
}

abstract class PlatformInterop {
  KeyTranslator get englishTranslator;
  KeyTranslator get persianTranslator;

  int get pollIntervalMs;

  bool get needsCopySentinel;

  String? get setupProblemKey;

  int foregroundWindow();

  bool areShortcutKeysDown(ShortcutDefinition shortcut);

  FutureOr<String?> readSelectionDirect();

  bool sendCopy();
  bool sendPaste();

  FutureOr<int> clipboardSequenceNumber();

  FutureOr<String?> getClipboardText();
  FutureOr<bool> setClipboardText(String text);

  FutureOr<ClipboardSnapshotHandle> saveClipboard();
  FutureOr<bool> restoreClipboard(ClipboardSnapshotHandle snapshot);
  void disposeSnapshot(ClipboardSnapshotHandle snapshot);

  FutureOr<void> setForegroundLanguage({required bool persian});
}
