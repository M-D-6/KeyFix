// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

DynamicLibrary _open(List<String> names) {
  Object? last;
  for (final String name in names) {
    try {
      return DynamicLibrary.open(name);
    } catch (e) {
      last = e;
    }
  }
  throw StateError('Unable to load ${names.first}: $last');
}

final DynamicLibrary _x11 = _open(<String>['libX11.so.6', 'libX11.so']);
final DynamicLibrary _xi = _open(<String>['libXi.so.6', 'libXi.so']);
final DynamicLibrary _xtst = _open(<String>['libXtst.so.6', 'libXtst.so']);
final DynamicLibrary _libc = DynamicLibrary.process();

const int xKeyPress = 2;
const int xKeyRelease = 3;
const int xGenericEvent = 35;

const int xShiftMask = 1;
const int xLockMask = 2;
const int xControlMask = 4;
const int xMod1Mask = 8;
const int xMod2Mask = 16;
const int xMod4Mask = 64;

const int xiRawKeyPress = 13;
const int xiRawKeyRelease = 14;
const int xiAllMasterDevices = 1;
const int xiKeyRepeatFlag = 1 << 16;
const int xiMaskLength = 4;

const int xEventSize = 192;
const int xUseCoreKeyboard = 0x100;

final int Function(Pointer<Utf8>) XOpenDisplay = _x11.lookupFunction<
    IntPtr Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('XOpenDisplay');

final int Function(int) XCloseDisplay = _x11
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('XCloseDisplay');

final int Function(int) XDefaultRootWindow = _x11.lookupFunction<
    IntPtr Function(IntPtr), int Function(int)>('XDefaultRootWindow');

final int Function(int) XConnectionNumber = _x11.lookupFunction<
    Int32 Function(IntPtr), int Function(int)>('XConnectionNumber');

final int Function(int) XPending =
    _x11.lookupFunction<Int32 Function(IntPtr), int Function(int)>('XPending');

final int Function(int, Pointer<Uint8>) XNextEvent = _x11.lookupFunction<
    Int32 Function(IntPtr, Pointer<Uint8>),
    int Function(int, Pointer<Uint8>)>('XNextEvent');

final int Function(int) XFlush =
    _x11.lookupFunction<Int32 Function(IntPtr), int Function(int)>('XFlush');

final int Function(int, int) XSync = _x11.lookupFunction<
    Int32 Function(IntPtr, Int32), int Function(int, int)>('XSync');

final int Function(int, int, int, int, int, int, int) XGrabKey =
    _x11.lookupFunction<
        Int32 Function(IntPtr, Int32, Uint32, IntPtr, Int32, Int32, Int32),
        int Function(int, int, int, int, int, int, int)>('XGrabKey');

final int Function(int, int, int, int) XUngrabKey = _x11.lookupFunction<
    Int32 Function(IntPtr, Int32, Uint32, IntPtr),
    int Function(int, int, int, int)>('XUngrabKey');

final int Function(int, Pointer<Uint8>) XQueryKeymap = _x11.lookupFunction<
    Int32 Function(IntPtr, Pointer<Uint8>),
    int Function(int, Pointer<Uint8>)>('XQueryKeymap');

final int Function(int, int, Pointer<Int32>) XkbSetDetectableAutoRepeat =
    _x11.lookupFunction<Int32 Function(IntPtr, Int32, Pointer<Int32>),
        int Function(int, int, Pointer<Int32>)>('XkbSetDetectableAutoRepeat');

final int Function(int, int, int) XkbLockGroup = _x11.lookupFunction<
    Int32 Function(IntPtr, Uint32, Uint32),
    int Function(int, int, int)>('XkbLockGroup');

final int Function(int, Pointer<IntPtr>, Pointer<Int32>) XGetInputFocus =
    _x11.lookupFunction<
        Int32 Function(IntPtr, Pointer<IntPtr>, Pointer<Int32>),
        int Function(int, Pointer<IntPtr>, Pointer<Int32>)>('XGetInputFocus');

final int Function(
  int,
  Pointer<Utf8>,
  Pointer<Int32>,
  Pointer<Int32>,
  Pointer<Int32>,
) XQueryExtension = _x11.lookupFunction<
    Int32 Function(
      IntPtr,
      Pointer<Utf8>,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<Int32>,
    ),
    int Function(
      int,
      Pointer<Utf8>,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<Int32>,
    )>('XQueryExtension');

final int Function(int, Pointer<Uint8>) XGetEventData = _x11.lookupFunction<
    Int32 Function(IntPtr, Pointer<Uint8>),
    int Function(int, Pointer<Uint8>)>('XGetEventData');

final void Function(int, Pointer<Uint8>) XFreeEventData = _x11.lookupFunction<
    Void Function(IntPtr, Pointer<Uint8>),
    void Function(int, Pointer<Uint8>)>('XFreeEventData');

final int Function(int, Pointer<Utf8>, int) XInternAtom = _x11.lookupFunction<
    IntPtr Function(IntPtr, Pointer<Utf8>, Int32),
    int Function(int, Pointer<Utf8>, int)>('XInternAtom');

final int Function(
  int,
  int,
  int,
  int,
  int,
  int,
  int,
  Pointer<IntPtr>,
  Pointer<Int32>,
  Pointer<IntPtr>,
  Pointer<IntPtr>,
  Pointer<IntPtr>,
) XGetWindowProperty = _x11.lookupFunction<
    Int32 Function(
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      IntPtr,
      Int32,
      IntPtr,
      Pointer<IntPtr>,
      Pointer<Int32>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
    ),
    int Function(
      int,
      int,
      int,
      int,
      int,
      int,
      int,
      Pointer<IntPtr>,
      Pointer<Int32>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
    )>('XGetWindowProperty');

final int Function(int, int, Pointer<IntPtr>) XGetClassHint =
    _x11.lookupFunction<Int32 Function(IntPtr, IntPtr, Pointer<IntPtr>),
        int Function(int, int, Pointer<IntPtr>)>('XGetClassHint');

final int Function(int) XFree =
    _x11.lookupFunction<Int32 Function(IntPtr), int Function(int)>('XFree');

typedef XErrorHandlerNative = Int32 Function(IntPtr, IntPtr);

final int Function(Pointer<NativeFunction<XErrorHandlerNative>>)
    XSetErrorHandler = _x11.lookupFunction<
        IntPtr Function(Pointer<NativeFunction<XErrorHandlerNative>>),
        int Function(
            Pointer<NativeFunction<XErrorHandlerNative>>)>('XSetErrorHandler');

final int Function(int, Pointer<Int32>, Pointer<Int32>) XIQueryVersion =
    _xi.lookupFunction<
        Int32 Function(IntPtr, Pointer<Int32>, Pointer<Int32>),
        int Function(int, Pointer<Int32>, Pointer<Int32>)>('XIQueryVersion');

final int Function(int, int, Pointer<Uint8>, int) XISelectEvents =
    _xi.lookupFunction<
        Int32 Function(IntPtr, IntPtr, Pointer<Uint8>, Int32),
        int Function(int, int, Pointer<Uint8>, int)>('XISelectEvents');

final int Function(int, int, int, int) XTestFakeKeyEvent = _xtst.lookupFunction<
    Int32 Function(IntPtr, Uint32, Int32, IntPtr),
    int Function(int, int, int, int)>('XTestFakeKeyEvent');

final int Function(Pointer<Uint8>, int, int) poll = _libc.lookupFunction<
    Int32 Function(Pointer<Uint8>, Uint64, Int32),
    int Function(Pointer<Uint8>, int, int)>('poll');

int _xErrorCount = 0;

int _onXError(int display, int event) {
  _xErrorCount++;
  return 0;
}

T withoutXErrors<T>(int display, T Function() body, {void Function()? onError}) {
  final int previous = XSetErrorHandler(
    Pointer.fromFunction<XErrorHandlerNative>(_onXError, 0),
  );
  final int before = _xErrorCount;
  try {
    final T result = body();
    XSync(display, 0);
    if (_xErrorCount != before) {
      onError?.call();
    }
    return result;
  } finally {
    XSetErrorHandler(
      Pointer<NativeFunction<XErrorHandlerNative>>.fromAddress(previous),
    );
  }
}

int get xErrorCount => _xErrorCount;

bool keymapBit(Pointer<Uint8> keymap, int keycode) {
  return ((keymap[keycode >> 3] >> (keycode & 7)) & 1) != 0;
}

int readInt32At(Pointer<Uint8> base, int offset) {
  return Pointer<Int32>.fromAddress(base.address + offset).value;
}

int readIntPtrAt(Pointer<Uint8> base, int offset) {
  return Pointer<IntPtr>.fromAddress(base.address + offset).value;
}

Pointer<T> offsetPointer<T extends NativeType>(Pointer<T> base, int bytes) {
  return Pointer<T>.fromAddress(base.address + bytes);
}
