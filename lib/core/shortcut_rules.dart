import 'shortcut_definition.dart';

class ShortcutRules {
  ShortcutRules._();

  static const int _alt = ShortcutDefinition.modAlt;
  static const int _ctrl = ShortcutDefinition.modControl;
  static const int _shift = ShortcutDefinition.modShift;
  static const int _win = ShortcutDefinition.modWin;

  static int countModifiers(int modifiers) {
    int count = 0;
    if ((modifiers & _alt) != 0) count++;
    if ((modifiers & _ctrl) != 0) count++;
    if ((modifiers & _shift) != 0) count++;
    if ((modifiers & _win) != 0) count++;
    return count;
  }

  static String? validate(int modifiers, int virtualKey) {

    if (virtualKey == 0) {
      if ((modifiers & _win) != 0) {
        return 'InvalidShortcut';
      }
      if (countModifiers(modifiers) < 2) {
        return 'InvalidShortcut';
      }
      return null;
    }

    if (!isKnownKey(virtualKey)) {
      return 'InvalidMainKey';
    }

    if (isReserved(modifiers, virtualKey)) {
      return 'ShortcutReserved';
    }

    if (modifiers == 0) {
      return isStandaloneKey(virtualKey) ? null : 'LoneKeyNotAllowed';
    }

    if (modifiers == _shift && !isFunctionKey(virtualKey) &&
        !isStandaloneKey(virtualKey)) {
      return 'ShiftOnlyNotAllowed';
    }

    return null;
  }

  static bool isFunctionKey(int key) => key >= 0x70 && key <= 0x87;

  static bool isStandaloneKey(int key) {
    return isFunctionKey(key) ||
        key == 0x13 ||
        key == 0x91 ||
        key == 0x2C;
  }

  static bool isKnownKey(int key) {
    if (key >= 0x41 && key <= 0x5A) return true;
    if (key >= 0x30 && key <= 0x39) return true;
    if (key >= 0x60 && key <= 0x6F) return true;
    if (isFunctionKey(key)) return true;
    if (key >= 0xBA && key <= 0xC0) return true;
    if (key >= 0xDB && key <= 0xDF) return true;
    if (key == 0xE2) return true;
    if (key >= 0x21 && key <= 0x28) return true;
    switch (key) {
      case 0x08:
      case 0x09:
      case 0x0D:
      case 0x13:
      case 0x1B:
      case 0x20:
      case 0x2C:
      case 0x2D:
      case 0x2E:
      case 0x5D:
      case 0x90:
      case 0x91:
        return true;
    }
    return false;
  }

  static bool isReserved(int modifiers, int key) {
    if (modifiers == _alt) {
      if (key == 0x09 || key == 0x73 || key == 0x1B || key == 0x20) {
        return true;
      }
    }
    if (modifiers == _ctrl) {
      if (key == 0x1B) return true;
      if (key == 0x43 || key == 0x56 || key == 0x58) {
        return true;
      }
    }
    if (modifiers == (_ctrl | _shift) && key == 0x1B) {
      return true;
    }
    if (modifiers == (_ctrl | _alt) && key == 0x2E) {
      return true;
    }
    return false;
  }
}
