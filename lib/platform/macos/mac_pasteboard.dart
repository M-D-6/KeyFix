import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../platform_interop.dart';
import 'mac_bindings.dart';

const String _textType = 'public.utf8-plain-text';
const String _transientType = 'org.nspasteboard.TransientType';
const int _snapshotLimit = 32 * 1024 * 1024;

class MacPasteboardSnapshot implements ClipboardSnapshotHandle {
  MacPasteboardSnapshot(this.items, this.canRestore);

  final List<Map<String, Uint8List>> items;

  @override
  final bool canRestore;
}

int _general() => msg0(objcClass('NSPasteboard'), objcSel('generalPasteboard'));

bool _bool(int value) => (value & 0xFF) != 0;

class MacPasteboard {
  static int changeCount() {
    return withAutoreleasePool<int>(() {
      final int pb = _general();
      return pb == 0 ? 0 : msg0(pb, objcSel('changeCount'));
    });
  }

  static String? readText() {
    return withAutoreleasePool<String?>(() {
      final int pb = _general();
      if (pb == 0) {
        return null;
      }
      final int value = msg1(pb, objcSel('stringForType:'), nsString(_textType));
      return dartStringFromNs(value);
    });
  }

  static bool writeText(String text, {bool transient = true}) {
    return withAutoreleasePool<bool>(() {
      final int pb = _general();
      if (pb == 0) {
        return false;
      }
      msg0(pb, objcSel('clearContents'));
      final bool ok = _bool(
        msg2(pb, objcSel('setString:forType:'), nsString(text),
            nsString(_textType)),
      );
      if (ok && transient) {
        final int empty = msg2(objcClass('NSData'), objcSel('dataWithBytes:length:'), 0, 0);
        msg2(pb, objcSel('setData:forType:'), empty, nsString(_transientType));
      }
      return ok;
    });
  }

  static MacPasteboardSnapshot snapshot() {
    return withAutoreleasePool<MacPasteboardSnapshot>(() {
      final List<Map<String, Uint8List>> result = <Map<String, Uint8List>>[];
      final int pb = _general();
      if (pb == 0) {
        return MacPasteboardSnapshot(result, false);
      }

      int total = 0;
      final int items = msg0(pb, objcSel('pasteboardItems'));
      final int count = items == 0 ? 0 : msg0(items, objcSel('count'));

      for (int i = 0; i < count; i++) {
        final int item = msg1(items, objcSel('objectAtIndex:'), i);
        final int types = msg0(item, objcSel('types'));
        final int typeCount = types == 0 ? 0 : msg0(types, objcSel('count'));
        final Map<String, Uint8List> entry = <String, Uint8List>{};

        for (int t = 0; t < typeCount; t++) {
          final String? type =
              dartStringFromNs(msg1(types, objcSel('objectAtIndex:'), t));
          if (type == null || type.startsWith('dyn.')) {
            continue;
          }

          final int data = msg1(item, objcSel('dataForType:'), nsString(type));
          if (data == 0) {
            continue;
          }

          final int length = msg0(data, objcSel('length'));
          if (length < 0 || total + length > _snapshotLimit) {
            continue;
          }

          final int bytes = msg0(data, objcSel('bytes'));
          if (length == 0 || bytes == 0) {
            entry[type] = Uint8List(0);
          } else {
            entry[type] = Uint8List.fromList(
              Pointer<Uint8>.fromAddress(bytes).asTypedList(length),
            );
          }
          total += length;
        }

        if (entry.isNotEmpty) {
          result.add(entry);
        }
      }

      return MacPasteboardSnapshot(result, true);
    });
  }

  static bool restore(MacPasteboardSnapshot snapshot) {
    return withAutoreleasePool<bool>(() {
      final int pb = _general();
      if (pb == 0) {
        return false;
      }

      msg0(pb, objcSel('clearContents'));
      if (snapshot.items.isEmpty) {
        return true;
      }

      final Pointer<IntPtr> objects = calloc<IntPtr>(snapshot.items.length);
      try {
        int filled = 0;

        for (final Map<String, Uint8List> entry in snapshot.items) {
          final int item = msg0(
            msg0(objcClass('NSPasteboardItem'), objcSel('alloc')),
            objcSel('init'),
          );
          if (item == 0) {
            continue;
          }

          for (final MapEntry<String, Uint8List> e in entry.entries) {
            final Pointer<Uint8> native = calloc<Uint8>(e.value.length + 1);
            try {
              native.asTypedList(e.value.length).setAll(0, e.value);
              final int data = msg2(
                objcClass('NSData'),
                objcSel('dataWithBytes:length:'),
                native.address,
                e.value.length,
              );
              msg2(item, objcSel('setData:forType:'), data, nsString(e.key));
            } finally {
              calloc.free(native);
            }
          }

          objects[filled++] = item;
        }

        if (filled == 0) {
          return false;
        }

        final int array = msg2(
          objcClass('NSArray'),
          objcSel('arrayWithObjects:count:'),
          objects.address,
          filled,
        );
        final bool ok = _bool(msg1(pb, objcSel('writeObjects:'), array));

        for (int i = 0; i < filled; i++) {
          msg0(objects[i], objcSel('release'));
        }
        return ok;
      } finally {
        calloc.free(objects);
      }
    });
  }
}
