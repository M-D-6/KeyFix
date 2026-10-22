import 'package:flutter_test/flutter_test.dart';
import 'package:keyfix/core/shortcut_definition.dart';
import 'package:keyfix/core/shortcut_rules.dart';
import 'package:keyfix/services/shortcut_recorder.dart';

void main() {
  const int ctrl = 0x11, alt = 0x12, shift = 0x10, keyK = 0x4B, pause = 0x13;

  test('Ctrl + K is recorded and builds the default shortcut', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();

    r.processKeyDown(ctrl);
    expect(r.recorderText('x'), 'Ctrl');
    expect(r.retryVisible, isTrue);

    r.processKeyDown(keyK);
    expect(r.recorderText('x'), 'Ctrl + K');
    expect(r.recording, isFalse);
    expect(r.helpKey, 'ValidShortcut');

    final ShortcutDefinition? s = r.tryBuild();
    expect(s, const ShortcutDefinition(0x0002, 0x4B));
    expect(s.toString(), 'Ctrl + K');
  });

  test('Alt + Shift alone is accepted after release', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(alt);
    r.processKeyDown(shift);
    expect(r.recording, isTrue);
    r.processKeyUp(shift);
    expect(r.recording, isTrue);
    r.processKeyUp(alt);
    expect(r.recording, isFalse);
    expect(r.modifierOnly, isTrue);
    expect(r.recorderText('x'), 'Alt + Shift');

    final ShortcutDefinition? s = r.tryBuild();
    expect(s, const ShortcutDefinition(0x0005, 0));
    expect(s.toString(), 'Alt + Shift');
  });

  test('a single modifier released alone starts over', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(ctrl);
    r.processKeyUp(ctrl);
    expect(r.recording, isTrue);
    expect(r.modifierOnly, isFalse);
    expect(r.recorderText('x'), 'x');
  });

  test('Pause alone is accepted', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(pause);
    expect(r.hasMainKey, isTrue);
    expect(r.tryBuild(), const ShortcutDefinition(0, 0x13));
    expect(r.recorderText('x'), 'Pause');
  });

  test('a letter alone is rejected', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(keyK);
    expect(r.helpKey, 'LoneKeyNotAllowed');
    expect(r.recording, isTrue);
  });

  test('Shift + letter is rejected, Shift + F9 is fine', () {
    expect(ShortcutRules.validate(0x4, keyK), 'ShiftOnlyNotAllowed');
    expect(ShortcutRules.validate(0x4, 0x78), isNull);
  });

  test('reserved combinations', () {
    expect(ShortcutRules.validate(0x1, 0x09), 'ShortcutReserved');
    expect(ShortcutRules.validate(0x1, 0x73), 'ShortcutReserved');
    expect(ShortcutRules.validate(0x2, 0x43), 'ShortcutReserved');
    expect(ShortcutRules.validate(0x2, keyK), isNull);
  });

  test('a single modifier is not a shortcut', () {
    expect(ShortcutRules.validate(0x2, 0), 'InvalidShortcut');
    expect(ShortcutRules.validate(0x3, 0), isNull);
  });

  test('modifier order is shown as pressed', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(shift);
    r.processKeyDown(ctrl);
    r.processKeyDown(alt);
    expect(r.recorderText('x'), 'Shift + Ctrl + Alt');
  });

  test('a second main key resets', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(ctrl);
    r.processKeyDown(keyK);
    r.recording = true;
    r.processKeyDown(0x4C);
    expect(r.helpKey, 'ResetShortcut');
  });

  test('pausing keeps the keys and offers retry', () {
    final ShortcutRecorder r = ShortcutRecorder()..begin();
    r.processKeyDown(ctrl);
    r.pause();
    expect(r.recording, isFalse);
    expect(r.paused, isTrue);
    expect(r.retryVisible, isTrue);
    expect(r.recorderText('x'), 'Ctrl');
    expect(r.helpKey, 'ShortcutRecordingStopped');
  });
}
