import 'package:flutter_test/flutter_test.dart';
import 'package:keyfix/core/shortcut_definition.dart';
import 'package:keyfix/core/shortcut_matcher.dart';

const int alt = ShortcutDefinition.modAlt;
const int ctrl = ShortcutDefinition.modControl;
const int shift = ShortcutDefinition.modShift;

void main() {
  group('modifier-only chord', () {
    test('fires once when the chord is released', () {
      final ShortcutMatcher m = ShortcutMatcher(alt | shift, 0);

      expect(
        m.handle(modifierEvent: true, virtualKey: 0, down: true, mods: alt).fire,
        false,
      );
      expect(
        m
            .handle(
              modifierEvent: true,
              virtualKey: 0,
              down: true,
              mods: alt | shift,
            )
            .fire,
        false,
      );
      expect(
        m
            .handle(
              modifierEvent: true,
              virtualKey: 0,
              down: false,
              mods: shift,
            )
            .fire,
        true,
      );
      expect(
        m.handle(modifierEvent: true, virtualKey: 0, down: false, mods: 0).fire,
        false,
      );
    });

    test('a key between the modifiers cancels the chord', () {
      final ShortcutMatcher m = ShortcutMatcher(alt | shift, 0);

      m.handle(modifierEvent: true, virtualKey: 0, down: true, mods: alt);
      m.handle(modifierEvent: false, virtualKey: 0x41, down: true, mods: alt);
      m.handle(
        modifierEvent: true,
        virtualKey: 0,
        down: true,
        mods: alt | shift,
      );

      expect(
        m.handle(modifierEvent: true, virtualKey: 0, down: false, mods: shift).fire,
        false,
      );
    });

    test('an extra modifier cancels the chord', () {
      final ShortcutMatcher m = ShortcutMatcher(alt | shift, 0);

      m.handle(modifierEvent: true, virtualKey: 0, down: true, mods: alt);
      m.handle(
        modifierEvent: true,
        virtualKey: 0,
        down: true,
        mods: alt | ctrl,
      );
      m.handle(
        modifierEvent: true,
        virtualKey: 0,
        down: true,
        mods: alt | ctrl | shift,
      );

      expect(
        m
            .handle(
              modifierEvent: true,
              virtualKey: 0,
              down: false,
              mods: ctrl | shift,
            )
            .fire,
        false,
      );
    });
  });

  group('key chord', () {
    test('fires and swallows the key and its repeats', () {
      final ShortcutMatcher m = ShortcutMatcher(ctrl, 0x4B);

      final MatchDecision first =
          m.handle(modifierEvent: false, virtualKey: 0x4B, down: true, mods: ctrl);
      expect(first.fire, true);
      expect(first.swallow, true);

      final MatchDecision repeat =
          m.handle(modifierEvent: false, virtualKey: 0x4B, down: true, mods: ctrl);
      expect(repeat.fire, false);
      expect(repeat.swallow, true);

      final MatchDecision up =
          m.handle(modifierEvent: false, virtualKey: 0x4B, down: false, mods: ctrl);
      expect(up.fire, false);
      expect(up.swallow, true);
    });

    test('ignores the key with other modifiers', () {
      final ShortcutMatcher m = ShortcutMatcher(ctrl, 0x4B);

      final MatchDecision d = m.handle(
        modifierEvent: false,
        virtualKey: 0x4B,
        down: true,
        mods: ctrl | shift,
      );
      expect(d.fire, false);
      expect(d.swallow, false);
    });

    test('a single special key works without modifiers', () {
      final ShortcutMatcher m = ShortcutMatcher(0, 0x13);

      expect(
        m.handle(modifierEvent: false, virtualKey: 0x13, down: true, mods: 0).fire,
        true,
      );
    });
  });
}
