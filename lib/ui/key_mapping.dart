import 'package:flutter/services.dart';

int windowsVirtualKeyFor(KeyEvent event) {
  final PhysicalKeyboardKey physical = event.physicalKey;
  final LogicalKeyboardKey logical = event.logicalKey;

  if (logical == LogicalKeyboardKey.controlLeft ||
      logical == LogicalKeyboardKey.controlRight ||
      logical == LogicalKeyboardKey.control) {
    return 0x11;
  }
  if (logical == LogicalKeyboardKey.altLeft ||
      logical == LogicalKeyboardKey.altRight ||
      logical == LogicalKeyboardKey.alt) {
    return 0x12;
  }
  if (logical == LogicalKeyboardKey.shiftLeft ||
      logical == LogicalKeyboardKey.shiftRight ||
      logical == LogicalKeyboardKey.shift) {
    return 0x10;
  }
  if (logical == LogicalKeyboardKey.metaLeft ||
      logical == LogicalKeyboardKey.metaRight ||
      logical == LogicalKeyboardKey.meta) {
    return 0x5B;
  }

  final int? vk = _physicalToVirtualKey[physical];
  return vk ?? 0xFF;
}

final Map<PhysicalKeyboardKey, int> _physicalToVirtualKey =
    <PhysicalKeyboardKey, int>{

  PhysicalKeyboardKey.keyA: 0x41,
  PhysicalKeyboardKey.keyB: 0x42,
  PhysicalKeyboardKey.keyC: 0x43,
  PhysicalKeyboardKey.keyD: 0x44,
  PhysicalKeyboardKey.keyE: 0x45,
  PhysicalKeyboardKey.keyF: 0x46,
  PhysicalKeyboardKey.keyG: 0x47,
  PhysicalKeyboardKey.keyH: 0x48,
  PhysicalKeyboardKey.keyI: 0x49,
  PhysicalKeyboardKey.keyJ: 0x4A,
  PhysicalKeyboardKey.keyK: 0x4B,
  PhysicalKeyboardKey.keyL: 0x4C,
  PhysicalKeyboardKey.keyM: 0x4D,
  PhysicalKeyboardKey.keyN: 0x4E,
  PhysicalKeyboardKey.keyO: 0x4F,
  PhysicalKeyboardKey.keyP: 0x50,
  PhysicalKeyboardKey.keyQ: 0x51,
  PhysicalKeyboardKey.keyR: 0x52,
  PhysicalKeyboardKey.keyS: 0x53,
  PhysicalKeyboardKey.keyT: 0x54,
  PhysicalKeyboardKey.keyU: 0x55,
  PhysicalKeyboardKey.keyV: 0x56,
  PhysicalKeyboardKey.keyW: 0x57,
  PhysicalKeyboardKey.keyX: 0x58,
  PhysicalKeyboardKey.keyY: 0x59,
  PhysicalKeyboardKey.keyZ: 0x5A,

  PhysicalKeyboardKey.digit0: 0x30,
  PhysicalKeyboardKey.digit1: 0x31,
  PhysicalKeyboardKey.digit2: 0x32,
  PhysicalKeyboardKey.digit3: 0x33,
  PhysicalKeyboardKey.digit4: 0x34,
  PhysicalKeyboardKey.digit5: 0x35,
  PhysicalKeyboardKey.digit6: 0x36,
  PhysicalKeyboardKey.digit7: 0x37,
  PhysicalKeyboardKey.digit8: 0x38,
  PhysicalKeyboardKey.digit9: 0x39,

  PhysicalKeyboardKey.numpad0: 0x60,
  PhysicalKeyboardKey.numpad1: 0x61,
  PhysicalKeyboardKey.numpad2: 0x62,
  PhysicalKeyboardKey.numpad3: 0x63,
  PhysicalKeyboardKey.numpad4: 0x64,
  PhysicalKeyboardKey.numpad5: 0x65,
  PhysicalKeyboardKey.numpad6: 0x66,
  PhysicalKeyboardKey.numpad7: 0x67,
  PhysicalKeyboardKey.numpad8: 0x68,
  PhysicalKeyboardKey.numpad9: 0x69,
  PhysicalKeyboardKey.numpadMultiply: 0x6A,
  PhysicalKeyboardKey.numpadAdd: 0x6B,
  PhysicalKeyboardKey.numpadComma: 0x6C,
  PhysicalKeyboardKey.numpadSubtract: 0x6D,
  PhysicalKeyboardKey.numpadDecimal: 0x6E,
  PhysicalKeyboardKey.numpadDivide: 0x6F,

  PhysicalKeyboardKey.f1: 0x70,
  PhysicalKeyboardKey.f2: 0x71,
  PhysicalKeyboardKey.f3: 0x72,
  PhysicalKeyboardKey.f4: 0x73,
  PhysicalKeyboardKey.f5: 0x74,
  PhysicalKeyboardKey.f6: 0x75,
  PhysicalKeyboardKey.f7: 0x76,
  PhysicalKeyboardKey.f8: 0x77,
  PhysicalKeyboardKey.f9: 0x78,
  PhysicalKeyboardKey.f10: 0x79,
  PhysicalKeyboardKey.f11: 0x7A,
  PhysicalKeyboardKey.f12: 0x7B,
  PhysicalKeyboardKey.f13: 0x7C,
  PhysicalKeyboardKey.f14: 0x7D,
  PhysicalKeyboardKey.f15: 0x7E,
  PhysicalKeyboardKey.f16: 0x7F,
  PhysicalKeyboardKey.f17: 0x80,
  PhysicalKeyboardKey.f18: 0x81,
  PhysicalKeyboardKey.f19: 0x82,
  PhysicalKeyboardKey.f20: 0x83,
  PhysicalKeyboardKey.f21: 0x84,
  PhysicalKeyboardKey.f22: 0x85,
  PhysicalKeyboardKey.f23: 0x86,
  PhysicalKeyboardKey.f24: 0x87,

  PhysicalKeyboardKey.pause: 0x13,
  PhysicalKeyboardKey.scrollLock: 0x91,
  PhysicalKeyboardKey.printScreen: 0x2C,
  PhysicalKeyboardKey.numLock: 0x90,
  PhysicalKeyboardKey.contextMenu: 0x5D,

  PhysicalKeyboardKey.space: 0x20,
  PhysicalKeyboardKey.semicolon: 0xBA,
  PhysicalKeyboardKey.equal: 0xBB,
  PhysicalKeyboardKey.comma: 0xBC,
  PhysicalKeyboardKey.minus: 0xBD,
  PhysicalKeyboardKey.period: 0xBE,
  PhysicalKeyboardKey.slash: 0xBF,
  PhysicalKeyboardKey.backquote: 0xC0,
  PhysicalKeyboardKey.bracketLeft: 0xDB,
  PhysicalKeyboardKey.backslash: 0xDC,
  PhysicalKeyboardKey.bracketRight: 0xDD,
  PhysicalKeyboardKey.quote: 0xDE,
  PhysicalKeyboardKey.intlBackslash: 0xE2,

  PhysicalKeyboardKey.enter: 0x0D,
  PhysicalKeyboardKey.escape: 0x1B,
  PhysicalKeyboardKey.tab: 0x09,
  PhysicalKeyboardKey.backspace: 0x08,
  PhysicalKeyboardKey.capsLock: 0x14,
  PhysicalKeyboardKey.arrowLeft: 0x25,
  PhysicalKeyboardKey.arrowUp: 0x26,
  PhysicalKeyboardKey.arrowRight: 0x27,
  PhysicalKeyboardKey.arrowDown: 0x28,
  PhysicalKeyboardKey.insert: 0x2D,
  PhysicalKeyboardKey.delete: 0x2E,
  PhysicalKeyboardKey.home: 0x24,
  PhysicalKeyboardKey.end: 0x23,
  PhysicalKeyboardKey.pageUp: 0x21,
  PhysicalKeyboardKey.pageDown: 0x22,
};
