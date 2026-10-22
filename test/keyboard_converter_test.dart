import 'package:flutter_test/flutter_test.dart';
import 'package:keyfix/core/keyboard_converter.dart';
import 'package:keyfix/core/keyboard_layout_map.dart';

import 'support/static_layouts.dart';

void main() {
  late KeyboardConverter converter;

  setUp(() {
    converter = KeyboardConverter(
      englishMap: KeyboardLayoutMap(staticTranslator(kUsEnglishLayout)),
      persianMap: KeyboardLayoutMap(staticTranslator(kPersianLayout)),
    );
  });

  group('README examples', () {
    test('English typed on Persian layout -> Persian', () {
      expect(converter.convertAutomatically('sghl'), 'سلام');
    });

    test('Persian typed on English layout -> English', () {
      expect(converter.convertAutomatically('اثممخ'), 'hello');
    });
  });

  group('automatic direction', () {
    test('whole words, spaces and punctuation', () {
      expect(converter.convertAutomatically('hello world'), 'اثممخ صخقمی');
      expect(converter.convertAutomatically('سلام دنیا'), 'sghl nkdh');
      expect(converter.convertAutomatically('sghl, ihdh'), 'سلامو هایا');
    });

    test('leading digits stay, letters are converted', () {
      expect(converter.convertAutomatically('1 sghl'), '1 سلام');
      expect(converter.convertAutomatically('سلام1'), 'sghl1');
    });

    test('mixed text is converted segment by segment', () {
      expect(converter.convertAutomatically('ش سلام a'), 'a sghl ش');
    });

    test('text without letters converts to empty = "nothing to convert"', () {
      expect(converter.convertAutomatically('123'), '');
      expect(converter.convertAutomatically(''), '');
    });
  });

  group('shift / caps handling', () {
    test('uppercase English means the Shift layer', () {
      expect(converter.convertAutomatically('Hello'), 'آثممخ');
      expect(converter.convertAutomatically('abc ABC'), 'شذز َإژ');
    });

    test('Caps Lock detection reverses all-uppercase words', () {
      expect(converter.convertAutomatically('HELLO'), 'اثممخ');
    });

    test('Caps Lock detection can be turned off', () {
      converter.detectCapsLockInMixedCaseEnglish = false;
      expect(converter.convertAutomatically('HELLO'), 'آٍ»»[');
    });

    test('Shift+R on the Persian layout is the ligature "ریال"', () {
      expect(converter.convertAutomatically('Hello R'), 'آثممخ ريال');
    });

    test('ignore-shift options', () {
      converter
        ..ignoreShiftEnglishToPersian = true
        ..ignoreShiftPersianToEnglish = true;

      expect(converter.convertAutomatically('Hello'), 'اثممخ');
      expect(converter.convertAutomatically('abc ABC'), 'شذز شذز');
      expect(converter.convertAutomatically('ً'), 'q');
    });
  });

  group('single characters', () {
    test('letters', () {
      expect(converter.convertAutomatically('a'), 'ش');
      expect(converter.convertAutomatically('A'), 'َ');
      expect(converter.convertAutomatically('q'), 'ض');
      expect(converter.convertAutomatically('Q'), 'ً');
      expect(converter.convertAutomatically('R'), 'ريال');
    });

    test('punctuation', () {
      expect(converter.convertAutomatically(';'), 'ک');
      expect(converter.convertAutomatically('ک'), ';');
      expect(converter.convertAutomatically('('), ')');
      expect(converter.convertAutomatically(')'), '(');
    });

    test('Persian letters / marks', () {
      expect(converter.convertAutomatically('ً'), 'Q');
      expect(converter.convertAutomatically('ي'), 'X');
    });

    test('digits are unchanged', () {
      expect(converter.convertAutomatically('1'), '1');
    });
  });

  group('classification helpers', () {
    test('Persian letter / mark detection matches the original ranges', () {
      expect(KeyboardConverter.isPersianLetterOrMark(0x0633), isTrue);
      expect(KeyboardConverter.isPersianLetterOrMark(0x064B), isTrue);
      expect(KeyboardConverter.isPersianLetterOrMark(0x060C), isFalse);
      expect(KeyboardConverter.isPersianLetterOrMark(0x0661), isFalse);
      expect(KeyboardConverter.isPersianLetterOrMark(0x0041), isFalse);
    });

    test('keyboard language decision helpers', () {
      expect(KeyboardConverter.isPersianCharacter(0x0633), isTrue);
      expect(KeyboardConverter.isPersianCharacter(0x0061), isFalse);
      expect(KeyboardConverter.isEnglishLetter(0x0061), isTrue);
      expect(KeyboardConverter.isEnglishLetter(0x0031), isFalse);
    });
  });
}
