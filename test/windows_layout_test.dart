@TestOn('windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:keyfix/core/keyboard_layout_map.dart';
import 'package:keyfix/platform/windows/key_translator.dart';

import 'support/static_layouts.dart';

void main() {
  test('real US layout matches reference table', () {
    final KeyTranslator os = WindowsKeyTranslator.forLayout('00000409').translate;
    final KeyTranslator ref = staticTranslator(kUsEnglishLayout);
    for (final int vk in kVirtualKeyOrder) {
      for (final bool shift in <bool>[false, true]) {
        for (final bool caps in <bool>[false, true]) {
          expect(os(vk, shift, caps), ref(vk, shift, caps),
              reason: 'vk=0x${vk.toRadixString(16)} shift=$shift caps=$caps');
        }
      }
    }
  });

  test('real Persian layout matches reference table', () {
    final KeyTranslator os = WindowsKeyTranslator.forLayout('00000429').translate;
    final KeyTranslator ref = staticTranslator(kPersianLayout);
    for (final int vk in kVirtualKeyOrder) {

      if (vk >= 0x30 && vk <= 0x39) continue;
      for (final bool shift in <bool>[false, true]) {
        for (final bool caps in <bool>[false, true]) {
          expect(os(vk, shift, caps), ref(vk, shift, caps),
              reason: 'vk=0x${vk.toRadixString(16)} shift=$shift caps=$caps');
        }
      }
    }
  });
}
