class ShortcutDefinition {
  const ShortcutDefinition(this.modifiers, this.virtualKey);

  final int modifiers;

  final int virtualKey;

  bool get isModifierOnly => virtualKey == 0;

  static const int modAlt = 0x0001;
  static const int modControl = 0x0002;
  static const int modShift = 0x0004;
  static const int modWin = 0x0008;

  List<String> get parts {
    final List<String> result = <String>[];

    if ((modifiers & modControl) != 0) {
      result.add('Ctrl');
    }
    if ((modifiers & modAlt) != 0) {
      result.add('Alt');
    }
    if ((modifiers & modShift) != 0) {
      result.add('Shift');
    }
    if ((modifiers & modWin) != 0) {
      result.add('Win');
    }
    if (virtualKey != 0) {
      result.add(keyName(virtualKey));
    }

    return result;
  }

  @override
  String toString() => parts.join(' + ');

  static String keyName(int key) {
    if (key >= 0x41 && key <= 0x5A) {
      return String.fromCharCode(key);
    }

    if (key >= 0x30 && key <= 0x39) {
      return String.fromCharCode(key);
    }

    if (key >= 0x70 && key <= 0x87) {
      return 'F${key - 0x6F}';
    }

    if (key >= 0x60 && key <= 0x69) {
      return 'Num ${key - 0x60}';
    }

    switch (key) {
      case 0x20:
        return 'Space';
      case 0x09:
        return 'Tab';
      case 0x0D:
        return 'Enter';
      case 0x2D:
        return 'Insert';
      case 0x2E:
        return 'Delete';
      case 0x24:
        return 'Home';
      case 0x23:
        return 'End';
      case 0x21:
        return 'Page Up';
      case 0x22:
        return 'Page Down';
      case 0x25:
        return 'Left';
      case 0x26:
        return 'Up';
      case 0x27:
        return 'Right';
      case 0x28:
        return 'Down';
      case 0x13:
        return 'Pause';
      case 0x91:
        return 'Scroll Lock';
      case 0x2C:
        return 'Print Screen';
      case 0x90:
        return 'Num Lock';
      case 0x1B:
        return 'Esc';
      case 0x08:
        return 'Backspace';
      case 0x5D:
        return 'Menu';
      case 0x6A:
        return 'Num *';
      case 0x6B:
        return 'Num +';
      case 0x6C:
        return 'Num Sep';
      case 0x6D:
        return 'Num -';
      case 0x6E:
        return 'Num .';
      case 0x6F:
        return 'Num /';
      case 0xBA:
        return ';';
      case 0xBB:
        return '=';
      case 0xBC:
        return ',';
      case 0xBD:
        return '-';
      case 0xBE:
        return '.';
      case 0xBF:
        return '/';
      case 0xC0:
        return '`';
      case 0xDB:
        return '[';
      case 0xDC:
        return r'\';
      case 0xDD:
        return ']';
      case 0xDE:
        return "'";
      default:
        return 'VK 0x${key.toRadixString(16).toUpperCase().padLeft(2, '0')}';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is ShortcutDefinition &&
        other.modifiers == modifiers &&
        other.virtualKey == virtualKey;
  }

  @override
  int get hashCode => Object.hash(modifiers, virtualKey);
}
