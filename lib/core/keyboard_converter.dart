import 'keyboard_layout_map.dart';

enum ConversionDirection { englishToPersian, persianToEnglish }

class KeyboardConverter {
  KeyboardConverter({
    required KeyboardLayoutMap englishMap,
    required KeyboardLayoutMap persianMap,
  })  : _englishMap = englishMap,
        _persianMap = persianMap;

  final KeyboardLayoutMap _englishMap;
  final KeyboardLayoutMap _persianMap;

  bool ignoreShiftPersianToEnglish = false;
  bool ignoreShiftEnglishToPersian = false;
  bool detectCapsLockInMixedCaseEnglish = true;

  String convertAutomatically(String text) {
    if (text.isEmpty) {
      return text;
    }

    if (text.length == 1) {
      return _convertSingleCharacter(text);
    }

    final StringBuffer result = StringBuffer();
    final StringBuffer segment = StringBuffer();

    ConversionDirection? currentDirection;

    for (int i = 0; i < text.length; i++) {
      final int unit = text.codeUnitAt(i);
      final String character = String.fromCharCode(unit);

      final ConversionDirection? direction = _getLetterDirection(unit);

      if (direction == null) {
        segment.write(character);
        continue;
      }

      if (currentDirection == null) {
        currentDirection = direction;
        segment.write(character);
        continue;
      }

      if (currentDirection == direction) {
        segment.write(character);
        continue;
      }

      _flushSegment(result, segment, currentDirection);

      currentDirection = direction;
      segment.write(character);
    }

    _flushSegment(result, segment, currentDirection);

    return result.toString();
  }

  String _convertSingleCharacter(String value) {
    final KeyStroke? persianKey = _persianMap.keyFor(value);
    if (persianKey != null) {
      return _convertSingleKey(
        value,
        persianKey,
        _persianMap,
        _englishMap,
        ConversionDirection.persianToEnglish,
        ignoreShiftPersianToEnglish,
      );
    }

    final KeyStroke? englishKey = _englishMap.keyFor(value);
    if (englishKey != null) {
      return _convertSingleKey(
        value,
        englishKey,
        _englishMap,
        _persianMap,
        ConversionDirection.englishToPersian,
        ignoreShiftEnglishToPersian,
      );
    }

    return value;
  }

  String _convertSingleKey(
    String original,
    KeyStroke keyStroke,
    KeyboardLayoutMap source,
    KeyboardLayoutMap target,
    ConversionDirection direction,
    bool ignoreShift,
  ) {
    return _mapStroke(
      original,
      keyStroke,
      target,
      direction,
      ignoreShift,
    );
  }

  void _flushSegment(
    StringBuffer result,
    StringBuffer segment,
    ConversionDirection? direction,
  ) {
    if (segment.isEmpty || direction == null) {
      return;
    }

    final String value = segment.toString();

    result.write(_convertSegment(value, direction));

    segment.clear();
  }

  String _convertSegment(String text, ConversionDirection direction) {
    String working = text;

    if (direction == ConversionDirection.englishToPersian) {
      working = _normalizeEnglishCaps(working);
    }

    final KeyboardLayoutMap source;
    final KeyboardLayoutMap target;
    final bool ignoreShift;

    if (direction == ConversionDirection.persianToEnglish) {
      source = _persianMap;
      target = _englishMap;
      ignoreShift = ignoreShiftPersianToEnglish;
    } else {
      source = _englishMap;
      target = _persianMap;
      ignoreShift = ignoreShiftEnglishToPersian;
    }

    return _convertSegmentUsingMaps(
      working,
      source,
      target,
      direction,
      ignoreShift,
    );
  }

  String _convertSegmentUsingMaps(
    String text,
    KeyboardLayoutMap source,
    KeyboardLayoutMap target,
    ConversionDirection direction,
    bool ignoreShift,
  ) {
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final String character = String.fromCharCode(text.codeUnitAt(i));

      final KeyStroke? keyStroke = source.keyFor(character);

      if (keyStroke == null) {
        result.write(character);
        continue;
      }

      result.write(
        _mapStroke(character, keyStroke, target, direction, ignoreShift),
      );
    }

    return result.toString();
  }

  String _mapStroke(
    String original,
    KeyStroke keyStroke,
    KeyboardLayoutMap target,
    ConversionDirection direction,
    bool ignoreShift,
  ) {
    KeyStroke stroke = keyStroke;

    if (direction == ConversionDirection.englishToPersian &&
        _isEnglishUppercase(original.codeUnitAt(0)) &&
        !ignoreShift) {
      stroke = stroke.copyWith(shift: true, capsLock: false);
    }

    if (ignoreShift) {
      stroke = stroke.copyWith(shift: false);
    }

    String? replacement = target.textFor(stroke);
    if (replacement != null) {
      return replacement;
    }

    if (stroke.capsLock) {
      replacement = target.textFor(stroke.copyWith(capsLock: false));
      if (replacement != null) {
        return replacement;
      }
    }

    if (stroke.shift) {
      replacement = target.textFor(stroke.copyWith(shift: false));
      if (replacement != null) {
        return replacement;
      }
    }

    return original;
  }

  String _normalizeEnglishCaps(String text) {
    int uppercaseCount = 0;
    int lowercaseCount = 0;

    for (int i = 0; i < text.length; i++) {
      final int unit = text.codeUnitAt(i);

      if (unit >= 0x41 && unit <= 0x5A) {
        uppercaseCount++;
        continue;
      }

      if (unit >= 0x61 && unit <= 0x7A) {
        lowercaseCount++;
      }
    }

    if (uppercaseCount + lowercaseCount == 0) {
      return text;
    }

    if (detectCapsLockInMixedCaseEnglish && uppercaseCount > lowercaseCount) {
      return _reverseEnglishCase(text);
    }

    return text;
  }

  static String _reverseEnglishCase(String text) {
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final int unit = text.codeUnitAt(i);

      if (unit >= 0x41 && unit <= 0x5A) {
        result.writeCharCode(unit + 0x20);
        continue;
      }

      if (unit >= 0x61 && unit <= 0x7A) {
        result.writeCharCode(unit - 0x20);
        continue;
      }

      result.writeCharCode(unit);
    }

    return result.toString();
  }

  static ConversionDirection? _getLetterDirection(int unit) {
    if (_isEnglishLetter(unit)) {
      return ConversionDirection.englishToPersian;
    }

    if (isPersianLetterOrMark(unit)) {
      return ConversionDirection.persianToEnglish;
    }

    return null;
  }

  static bool _isEnglishLetter(int unit) {
    return (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);
  }

  static bool _isEnglishUppercase(int unit) {
    return unit >= 0x41 && unit <= 0x5A;
  }

  static bool isPersianLetterOrMark(int unit) {
    for (int i = 0; i < _persianLetterRanges.length; i += 2) {
      if (unit >= _persianLetterRanges[i] &&
          unit <= _persianLetterRanges[i + 1]) {
        return true;
      }
    }
    return false;
  }

  static const List<int> _persianLetterRanges = <int>[
    0x610, 0x61A, 0x620, 0x65F, 0x66E, 0x6D3, 0x6D5, 0x6DC, 0x6DF, 0x6E8,
    0x6EA, 0x6EF, 0x6FA, 0x6FC, 0x6FF, 0x6FF, 0x750, 0x77F, 0x8A0, 0x8E1,
    0x8E3, 0x8FF, 0xFB50, 0xFBB1, 0xFBD3, 0xFD3D, 0xFD50, 0xFD8F, 0xFD92,
    0xFDC7, 0xFDF0, 0xFDFB, 0xFE70, 0xFE74, 0xFE76, 0xFEFC,
  ];

  static bool isPersianCharacter(int unit) {
    return (unit >= 0x0600 && unit <= 0x06FF) ||
        (unit >= 0x0750 && unit <= 0x077F) ||
        (unit >= 0x08A0 && unit <= 0x08FF) ||
        (unit >= 0xFB50 && unit <= 0xFDFF) ||
        (unit >= 0xFE70 && unit <= 0xFEFF);
  }

  static bool isEnglishLetter(int unit) => _isEnglishLetter(unit);
}
