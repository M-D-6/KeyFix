import 'dart:ffi';

import 'package:ffi/ffi.dart';

void enableSystemThemedMenus() {
  try {
    final DynamicLibrary kernel = DynamicLibrary.open('kernel32.dll');

    final int Function(Pointer<Utf16>) loadLibrary = kernel.lookupFunction<
        IntPtr Function(Pointer<Utf16>),
        int Function(Pointer<Utf16>)>('LoadLibraryW');
    final int Function(int, int) getProcAddress = kernel.lookupFunction<
        IntPtr Function(IntPtr, IntPtr),
        int Function(int, int)>('GetProcAddress');

    final Pointer<Utf16> name = 'uxtheme.dll'.toNativeUtf16();
    final int module = loadLibrary(name);
    calloc.free(name);
    if (module == 0) {
      return;
    }

    final int setMode = getProcAddress(module, 135);
    final int flush = getProcAddress(module, 136);

    if (setMode != 0) {

      Pointer<NativeFunction<Int32 Function(Int32)>>.fromAddress(setMode)
          .asFunction<int Function(int)>()(1);
    }
    if (flush != 0) {
      Pointer<NativeFunction<Void Function()>>.fromAddress(flush)
          .asFunction<void Function()>()();
    }
  } catch (_) {

  }
}
