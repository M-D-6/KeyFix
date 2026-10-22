class KeyStroke {
  const KeyStroke(this.virtualKey, this.shift, this.capsLock);

  final int virtualKey;
  final bool shift;
  final bool capsLock;

  KeyStroke copyWith({bool? shift, bool? capsLock}) {
    return KeyStroke(
      virtualKey,
      shift ?? this.shift,
      capsLock ?? this.capsLock,
    );
  }

  int get packed =>
      virtualKey | (shift ? 0x100 : 0) | (capsLock ? 0x200 : 0);

  static KeyStroke unpack(int value) {
    return KeyStroke(
      value & 0xFF,
      (value & 0x100) != 0,
      (value & 0x200) != 0,
    );
  }
}

const List<int> kVirtualKeyOrder = <int>[

  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,

  0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C,
  0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
  0x59, 0x5A,

  0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF,
  0xE2,

  0x20,
];

typedef KeyTranslator = String Function(
  int virtualKey,
  bool shift,
  bool capsLock,
);

class KeyboardLayoutMap {
  KeyboardLayoutMap(KeyTranslator translate) {
    for (final int virtualKey in kVirtualKeyOrder) {

      for (final bool shift in const <bool>[false, true]) {
        for (final bool capsLock in const <bool>[false, true]) {
          final String text = translate(virtualKey, shift, capsLock);
          if (text.isEmpty) {
            continue;
          }

          final KeyStroke stroke = KeyStroke(virtualKey, shift, capsLock);
          _keyToText[stroke.packed] = text;

          if (!_textToKey.containsKey(text)) {
            _textToKey[text] = stroke.packed;
          }
        }
      }
    }
  }

  final Map<int, String> _keyToText = <int, String>{};
  final Map<String, int> _textToKey = <String, int>{};

  String? textFor(KeyStroke stroke) => _keyToText[stroke.packed];

  KeyStroke? keyFor(String text) {
    final int? packed = _textToKey[text];
    return packed == null ? null : KeyStroke.unpack(packed);
  }
}
