library;

import 'package:keyfix/core/keyboard_layout_map.dart';

class LayoutKey {
  const LayoutKey(
    this.virtualKey,
    this.normal,
    this.shifted, {
    this.capsLockAffects = false,
  });

  final int virtualKey;

  final String normal;

  final String shifted;

  final bool capsLockAffects;
}

const List<LayoutKey> kUsEnglishLayout = <LayoutKey>[
  LayoutKey(0x30, '0', ')'),
  LayoutKey(0x31, '1', '!'),
  LayoutKey(0x32, '2', '@'),
  LayoutKey(0x33, '3', '#'),
  LayoutKey(0x34, '4', r'$'),
  LayoutKey(0x35, '5', '%'),
  LayoutKey(0x36, '6', '^'),
  LayoutKey(0x37, '7', '&'),
  LayoutKey(0x38, '8', '*'),
  LayoutKey(0x39, '9', '('),
  LayoutKey(0x41, 'a', 'A', capsLockAffects: true),
  LayoutKey(0x42, 'b', 'B', capsLockAffects: true),
  LayoutKey(0x43, 'c', 'C', capsLockAffects: true),
  LayoutKey(0x44, 'd', 'D', capsLockAffects: true),
  LayoutKey(0x45, 'e', 'E', capsLockAffects: true),
  LayoutKey(0x46, 'f', 'F', capsLockAffects: true),
  LayoutKey(0x47, 'g', 'G', capsLockAffects: true),
  LayoutKey(0x48, 'h', 'H', capsLockAffects: true),
  LayoutKey(0x49, 'i', 'I', capsLockAffects: true),
  LayoutKey(0x4A, 'j', 'J', capsLockAffects: true),
  LayoutKey(0x4B, 'k', 'K', capsLockAffects: true),
  LayoutKey(0x4C, 'l', 'L', capsLockAffects: true),
  LayoutKey(0x4D, 'm', 'M', capsLockAffects: true),
  LayoutKey(0x4E, 'n', 'N', capsLockAffects: true),
  LayoutKey(0x4F, 'o', 'O', capsLockAffects: true),
  LayoutKey(0x50, 'p', 'P', capsLockAffects: true),
  LayoutKey(0x51, 'q', 'Q', capsLockAffects: true),
  LayoutKey(0x52, 'r', 'R', capsLockAffects: true),
  LayoutKey(0x53, 's', 'S', capsLockAffects: true),
  LayoutKey(0x54, 't', 'T', capsLockAffects: true),
  LayoutKey(0x55, 'u', 'U', capsLockAffects: true),
  LayoutKey(0x56, 'v', 'V', capsLockAffects: true),
  LayoutKey(0x57, 'w', 'W', capsLockAffects: true),
  LayoutKey(0x58, 'x', 'X', capsLockAffects: true),
  LayoutKey(0x59, 'y', 'Y', capsLockAffects: true),
  LayoutKey(0x5A, 'z', 'Z', capsLockAffects: true),
  LayoutKey(0xBA, ';', ':'),
  LayoutKey(0xBB, '=', '+'),
  LayoutKey(0xBC, ',', '<'),
  LayoutKey(0xBD, '-', '_'),
  LayoutKey(0xBE, '.', '>'),
  LayoutKey(0xBF, '/', '?'),
  LayoutKey(0xC0, '`', '~'),
  LayoutKey(0xDB, '[', '{'),
  LayoutKey(0xDC, r'\', '|'),
  LayoutKey(0xDD, ']', '}'),
  LayoutKey(0xDE, "'", '"'),

  LayoutKey(0xE2, r'\', '|'),
  LayoutKey(0x20, ' ', ' '),
];

const List<LayoutKey> kPersianLayout = <LayoutKey>[

  LayoutKey(0x30, '0', '('),
  LayoutKey(0x31, '1', '!'),
  LayoutKey(0x32, '2', '@'),
  LayoutKey(0x33, '3', '#'),
  LayoutKey(0x34, '4', r'$'),
  LayoutKey(0x35, '5', '%'),
  LayoutKey(0x36, '6', '^'),
  LayoutKey(0x37, '7', '&'),
  LayoutKey(0x38, '8', '*'),
  LayoutKey(0x39, '9', ')'),

  LayoutKey(0x51, 'ض', 'ً'),
  LayoutKey(0x57, 'ص', 'ٌ'),
  LayoutKey(0x45, 'ث', 'ٍ'),

  LayoutKey(0x52, 'ق', 'ريال'),
  LayoutKey(0x54, 'ف', '،'),
  LayoutKey(0x59, 'غ', '؛'),
  LayoutKey(0x55, 'ع', ','),
  LayoutKey(0x49, 'ه', ']'),
  LayoutKey(0x4F, 'خ', '['),
  LayoutKey(0x50, 'ح', r'\'),

  LayoutKey(0x41, 'ش', 'َ'),
  LayoutKey(0x53, 'س', 'ُ'),
  LayoutKey(0x44, 'ی', 'ِ'),
  LayoutKey(0x46, 'ب', 'ّ'),
  LayoutKey(0x47, 'ل', 'ۀ'),
  LayoutKey(0x48, 'ا', 'آ'),
  LayoutKey(0x4A, 'ت', 'ـ'),
  LayoutKey(0x4B, 'ن', '«'),
  LayoutKey(0x4C, 'م', '»'),

  LayoutKey(0x5A, 'ظ', 'ة'),
  LayoutKey(0x58, 'ط', 'ي'),
  LayoutKey(0x43, 'ز', 'ژ'),
  LayoutKey(0x56, 'ر', 'ؤ'),
  LayoutKey(0x42, 'ذ', 'إ'),
  LayoutKey(0x4E, 'د', 'أ'),
  LayoutKey(0x4D, 'ئ', 'ء'),

  LayoutKey(0xBA, 'ک', ':'),
  LayoutKey(0xBB, '=', '+'),
  LayoutKey(0xBC, 'و', '<'),
  LayoutKey(0xBD, '-', '_'),
  LayoutKey(0xBE, '.', '>'),
  LayoutKey(0xBF, '/', '؟'),
  LayoutKey(0xC0, '÷', '×'),
  LayoutKey(0xDB, 'ج', '}'),
  LayoutKey(0xDC, 'پ', '|'),
  LayoutKey(0xDD, 'چ', '{'),
  LayoutKey(0xDE, 'گ', '"'),

  LayoutKey(0xE2, 'پ', '|'),
  LayoutKey(0x20, ' ', ' '),
];

KeyTranslator staticTranslator(List<LayoutKey> keys) {
  final Map<int, LayoutKey> byVk = <int, LayoutKey>{
    for (final LayoutKey k in keys) k.virtualKey: k,
  };
  return (int vk, bool shift, bool capsLock) {
    final LayoutKey? key = byVk[vk];
    if (key == null) return '';
    bool s = shift;
    if (key.capsLockAffects && capsLock) s = !s;
    return s ? key.shifted : key.normal;
  };
}
