// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

final DynamicLibrary _cf = DynamicLibrary.open(
  '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
);
final DynamicLibrary _cg = DynamicLibrary.open(
  '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics',
);
final DynamicLibrary _app = DynamicLibrary.open(
  '/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices',
);
final DynamicLibrary _carbon = DynamicLibrary.open(
  '/System/Library/Frameworks/Carbon.framework/Carbon',
);
final DynamicLibrary _objc = DynamicLibrary.open('/usr/lib/libobjc.A.dylib');

const int cfStringEncodingUtf8 = 0x08000100;

const int cgSessionEventTap = 1;
const int cgHeadInsertEventTap = 0;
const int cgHidEventTap = 0;
const int cgEventKeyDown = 10;
const int cgEventKeyUp = 11;
const int cgEventFlagsChanged = 12;
const int cgEventTapDisabledByTimeout = 0xFFFFFFFE;
const int cgEventTapDisabledByUserInput = 0xFFFFFFFF;

const int cgKeyboardEventKeycode = 9;
const int cgEventSourceUserData = 42;

const int cgFlagShift = 0x20000;
const int cgFlagControl = 0x40000;
const int cgFlagOption = 0x80000;
const int cgFlagCommand = 0x100000;

const int cgSourceStatePrivate = -1;
const int cgSourceStateCombined = 0;

int _global(DynamicLibrary lib, String name) {
  return lib.lookup<IntPtr>(name).value;
}

final int kCFRunLoopCommonModes = _global(_cf, 'kCFRunLoopCommonModes');
final int kCFRunLoopDefaultMode = _global(_cf, 'kCFRunLoopDefaultMode');
final int kCFBooleanTrue = _global(_cf, 'kCFBooleanTrue');
final int kAXTrustedCheckOptionPrompt =
    _global(_app, 'kAXTrustedCheckOptionPrompt');
final int kTISPropertyInputSourceID = _global(_carbon, 'kTISPropertyInputSourceID');
final int kTISPropertyUnicodeKeyLayoutData =
    _global(_carbon, 'kTISPropertyUnicodeKeyLayoutData');

final void Function(int) CFRelease = _cf
    .lookupFunction<Void Function(IntPtr), void Function(int)>('CFRelease');

final int Function(int) CFArrayGetCount = _cf
    .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
        'CFArrayGetCount');

final int Function(int, int) CFArrayGetValueAtIndex = _cf.lookupFunction<
    IntPtr Function(IntPtr, IntPtr),
    int Function(int, int)>('CFArrayGetValueAtIndex');

final int Function(int, Pointer<Utf8>, int, int) CFStringGetCString =
    _cf.lookupFunction<
        Uint8 Function(IntPtr, Pointer<Utf8>, IntPtr, Uint32),
        int Function(int, Pointer<Utf8>, int, int)>('CFStringGetCString');

final int Function(int) CFDataGetBytePtr = _cf
    .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
        'CFDataGetBytePtr');

final int Function(int, int, int) CFMachPortCreateRunLoopSource =
    _cf.lookupFunction<IntPtr Function(IntPtr, IntPtr, IntPtr),
        int Function(int, int, int)>('CFMachPortCreateRunLoopSource');

final void Function(int) CFMachPortInvalidate = _cf
    .lookupFunction<Void Function(IntPtr), void Function(int)>(
        'CFMachPortInvalidate');

final int Function() CFRunLoopGetCurrent = _cf
    .lookupFunction<IntPtr Function(), int Function()>('CFRunLoopGetCurrent');

final void Function(int, int, int) CFRunLoopAddSource = _cf.lookupFunction<
    Void Function(IntPtr, IntPtr, IntPtr),
    void Function(int, int, int)>('CFRunLoopAddSource');

final int Function(int, double, int) CFRunLoopRunInMode = _cf.lookupFunction<
    Int32 Function(IntPtr, Double, Uint8),
    int Function(int, double, int)>('CFRunLoopRunInMode');

final int Function(int, Pointer<IntPtr>, Pointer<IntPtr>, int, int, int)
    CFDictionaryCreate = _cf.lookupFunction<
        IntPtr Function(
          IntPtr,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          IntPtr,
          IntPtr,
          IntPtr,
        ),
        int Function(
          int,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          int,
          int,
          int,
        )>('CFDictionaryCreate');

int get cfTypeDictionaryKeyCallBacks =>
    _cf.lookup<Void>('kCFTypeDictionaryKeyCallBacks').address;

int get cfTypeDictionaryValueCallBacks =>
    _cf.lookup<Void>('kCFTypeDictionaryValueCallBacks').address;

typedef TapCallbackNative = IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr);

final int Function(
  int,
  int,
  int,
  int,
  Pointer<NativeFunction<TapCallbackNative>>,
  int,
) CGEventTapCreate = _cg.lookupFunction<
    IntPtr Function(
      Uint32,
      Uint32,
      Uint32,
      Uint64,
      Pointer<NativeFunction<TapCallbackNative>>,
      IntPtr,
    ),
    int Function(
      int,
      int,
      int,
      int,
      Pointer<NativeFunction<TapCallbackNative>>,
      int,
    )>('CGEventTapCreate');

final void Function(int, int) CGEventTapEnable = _cg.lookupFunction<
    Void Function(IntPtr, Uint8), void Function(int, int)>('CGEventTapEnable');

final int Function(int, int) CGEventGetIntegerValueField = _cg.lookupFunction<
    Int64 Function(IntPtr, Uint32),
    int Function(int, int)>('CGEventGetIntegerValueField');

final void Function(int, int, int) CGEventSetIntegerValueField =
    _cg.lookupFunction<Void Function(IntPtr, Uint32, Int64),
        void Function(int, int, int)>('CGEventSetIntegerValueField');

final int Function(int) CGEventGetFlags = _cg
    .lookupFunction<Uint64 Function(IntPtr), int Function(int)>(
        'CGEventGetFlags');

final void Function(int, int) CGEventSetFlags = _cg.lookupFunction<
    Void Function(IntPtr, Uint64), void Function(int, int)>('CGEventSetFlags');

final int Function(int, int, int) CGEventCreateKeyboardEvent =
    _cg.lookupFunction<IntPtr Function(IntPtr, Uint16, Uint8),
        int Function(int, int, int)>('CGEventCreateKeyboardEvent');

final void Function(int, int) CGEventPost = _cg.lookupFunction<
    Void Function(Uint32, IntPtr), void Function(int, int)>('CGEventPost');

final int Function(int) CGEventSourceCreate = _cg
    .lookupFunction<IntPtr Function(Int32), int Function(int)>(
        'CGEventSourceCreate');

final int Function(int) CGEventSourceFlagsState = _cg
    .lookupFunction<Uint64 Function(Int32), int Function(int)>(
        'CGEventSourceFlagsState');

final int Function(int, int) CGEventSourceKeyState = _cg.lookupFunction<
    Uint8 Function(Int32, Uint16),
    int Function(int, int)>('CGEventSourceKeyState');

final int Function() AXIsProcessTrusted = _app
    .lookupFunction<Uint8 Function(), int Function()>('AXIsProcessTrusted');

final int Function(int) AXIsProcessTrustedWithOptions = _app
    .lookupFunction<Uint8 Function(IntPtr), int Function(int)>(
        'AXIsProcessTrustedWithOptions');

final int Function(int, int) TISCreateInputSourceList = _carbon.lookupFunction<
    IntPtr Function(IntPtr, Uint8),
    int Function(int, int)>('TISCreateInputSourceList');

final int Function(int, int) TISGetInputSourceProperty = _carbon.lookupFunction<
    IntPtr Function(IntPtr, IntPtr),
    int Function(int, int)>('TISGetInputSourceProperty');

final int Function(int) TISSelectInputSource = _carbon
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'TISSelectInputSource');

final int Function() LMGetKbdType = _carbon
    .lookupFunction<Uint8 Function(), int Function()>('LMGetKbdType');

final int Function(
  int,
  int,
  int,
  int,
  int,
  int,
  Pointer<Uint32>,
  int,
  Pointer<IntPtr>,
  Pointer<Uint16>,
) UCKeyTranslate = _carbon.lookupFunction<
    Int32 Function(
      IntPtr,
      Uint16,
      Uint16,
      Uint32,
      Uint32,
      Uint32,
      Pointer<Uint32>,
      IntPtr,
      Pointer<IntPtr>,
      Pointer<Uint16>,
    ),
    int Function(
      int,
      int,
      int,
      int,
      int,
      int,
      Pointer<Uint32>,
      int,
      Pointer<IntPtr>,
      Pointer<Uint16>,
    )>('UCKeyTranslate');

final int Function(Pointer<Utf8>) objc_getClass = _objc.lookupFunction<
    IntPtr Function(Pointer<Utf8>),
    int Function(Pointer<Utf8>)>('objc_getClass');

final int Function(Pointer<Utf8>) sel_registerName = _objc.lookupFunction<
    IntPtr Function(Pointer<Utf8>),
    int Function(Pointer<Utf8>)>('sel_registerName');

final int Function(int, int) msg0 = _objc.lookupFunction<
    IntPtr Function(IntPtr, IntPtr), int Function(int, int)>('objc_msgSend');

final int Function(int, int, int) msg1 = _objc.lookupFunction<
    IntPtr Function(IntPtr, IntPtr, IntPtr),
    int Function(int, int, int)>('objc_msgSend');

final int Function(int, int, int, int) msg2 = _objc.lookupFunction<
    IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr),
    int Function(int, int, int, int)>('objc_msgSend');

final int Function() objc_autoreleasePoolPush = _objc
    .lookupFunction<IntPtr Function(), int Function()>(
        'objc_autoreleasePoolPush');

final void Function(int) objc_autoreleasePoolPop = _objc
    .lookupFunction<Void Function(IntPtr), void Function(int)>(
        'objc_autoreleasePoolPop');

final Map<String, int> _classes = <String, int>{};
final Map<String, int> _selectors = <String, int>{};

int objcClass(String name) {
  return _classes.putIfAbsent(name, () {
    final Pointer<Utf8> native = name.toNativeUtf8();
    try {
      return objc_getClass(native);
    } finally {
      calloc.free(native);
    }
  });
}

int objcSel(String name) {
  return _selectors.putIfAbsent(name, () {
    final Pointer<Utf8> native = name.toNativeUtf8();
    try {
      return sel_registerName(native);
    } finally {
      calloc.free(native);
    }
  });
}

T withAutoreleasePool<T>(T Function() body) {
  final int pool = objc_autoreleasePoolPush();
  try {
    return body();
  } finally {
    objc_autoreleasePoolPop(pool);
  }
}

int nsString(String value) {
  final Pointer<Utf8> native = value.toNativeUtf8();
  try {
    return msg1(
      objcClass('NSString'),
      objcSel('stringWithUTF8String:'),
      native.address,
    );
  } finally {
    calloc.free(native);
  }
}

String? dartStringFromNs(int string) {
  if (string == 0) {
    return null;
  }
  final int pointer = msg0(string, objcSel('UTF8String'));
  if (pointer == 0) {
    return null;
  }
  return Pointer<Utf8>.fromAddress(pointer).toDartString();
}

String? cfStringToDart(int string) {
  if (string == 0) {
    return null;
  }
  final Pointer<Utf8> buffer = calloc<Uint8>(512).cast<Utf8>();
  try {
    if (CFStringGetCString(string, buffer, 512, cfStringEncodingUtf8) == 0) {
      return null;
    }
    return buffer.toDartString();
  } finally {
    calloc.free(buffer);
  }
}

bool requestAccessibilityPrompt() {
  final Pointer<IntPtr> keys = calloc<IntPtr>();
  final Pointer<IntPtr> values = calloc<IntPtr>();
  try {
    keys[0] = kAXTrustedCheckOptionPrompt;
    values[0] = kCFBooleanTrue;
    final int dictionary = CFDictionaryCreate(
      0,
      keys,
      values,
      1,
      cfTypeDictionaryKeyCallBacks,
      cfTypeDictionaryValueCallBacks,
    );
    if (dictionary == 0) {
      return AXIsProcessTrusted() != 0;
    }
    final bool trusted = (AXIsProcessTrustedWithOptions(dictionary) & 0xFF) != 0;
    CFRelease(dictionary);
    return trusted;
  } finally {
    calloc.free(keys);
    calloc.free(values);
  }
}
