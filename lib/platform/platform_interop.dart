import '../core/keyboard_layout_map.dart';
import '../core/shortcut_definition.dart';

abstract class ClipboardSnapshotHandle {
  bool get canRestore;
}

abstract class PlatformInterop {
  KeyTranslator get englishTranslator;
  KeyTranslator get persianTranslator;

  int get pollIntervalMs;

  bool get needsCopySentinel;

  String? get setupProblemKey;

  int foregroundWindow();

  bool areShortcutKeysDown(ShortcutDefinition shortcut);

  String? readSelectionDirect();

  bool sendCopy();
  bool sendPaste();

  int clipboardSequenceNumber();

  String? getClipboardText();
  bool setClipboardText(String text);

  ClipboardSnapshotHandle saveClipboard();
  bool restoreClipboard(ClipboardSnapshotHandle snapshot);
  void disposeSnapshot(ClipboardSnapshotHandle snapshot);

  void setForegroundLanguage({required bool persian});
}
