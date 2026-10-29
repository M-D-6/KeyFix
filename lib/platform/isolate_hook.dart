import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../core/shortcut_definition.dart';
import 'shortcut_hook.dart';

typedef HookEntry = void Function(List<Object?> args);

class _Resources {
  _Resources(this.port, this.flag);

  final ReceivePort port;
  final Pointer<Int32> flag;
  Isolate? isolate;
  bool released = false;

  void release() {
    if (released) {
      return;
    }
    released = true;
    port.close();
    calloc.free(flag);
  }
}

class IsolateShortcutHook implements ShortcutHook {
  IsolateShortcutHook._(
    this.shortcut,
    this._resources,
    this.installed,
    this.errorCode,
  );

  @override
  final ShortcutDefinition shortcut;

  @override
  final bool installed;

  @override
  final int errorCode;

  final _Resources? _resources;
  final StreamController<void> _pressed = StreamController<void>.broadcast();
  bool _disposed = false;

  static void Function(String line)? onLog;

  @override
  Stream<void> get pressed => _pressed.stream;

  static Future<IsolateShortcutHook> start(
    ShortcutDefinition shortcut,
    HookEntry entry,
    String name,
  ) async {
    final _Resources resources = _Resources(
      ReceivePort(),
      calloc<Int32>(),
    );
    final Completer<List<Object?>> ready = Completer<List<Object?>>();
    StreamController<void>? forward;

    resources.port.listen((dynamic message) {
      if (message is List && message.isNotEmpty) {
        final Object? tag = message[0];
        if (tag == 'ready') {
          if (!ready.isCompleted) {
            ready.complete(message.cast<Object?>());
          }
        } else if (tag == 'log') {
          onLog?.call(message[1] as String);
        } else if (tag == 'exited') {
          resources.release();
        }
        return;
      }

      if (message == 'pressed') {
        final StreamController<void>? sink = forward;
        if (sink != null && !sink.isClosed) {
          sink.add(null);
        }
      }
    });

    try {
      resources.isolate = await Isolate.spawn<List<Object?>>(
        entry,
        <Object?>[
          resources.port.sendPort,
          shortcut.modifiers,
          shortcut.virtualKey,
          resources.flag.address,
        ],
        debugName: name,
      );
    } catch (_) {
      resources.release();
      final IsolateShortcutHook failed =
          IsolateShortcutHook._(shortcut, null, false, kHookUnsupported);
      failed._pressed.close();
      return failed;
    }

    final List<Object?> info = await ready.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => <Object?>['ready', false, kHookUnsupported],
    );

    final bool ok = info[1] as bool;
    final int error = info[2] as int;

    final IsolateShortcutHook hook =
        IsolateShortcutHook._(shortcut, resources, ok, error);
    forward = hook._pressed;

    if (!ok) {
      hook.dispose();
    }

    return hook;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;

    final _Resources? resources = _resources;
    if (resources != null && !resources.released) {
      resources.flag.value = 1;

      Timer(const Duration(seconds: 2), () {
        if (!resources.released) {
          resources.isolate?.kill(priority: Isolate.immediate);
          resources.release();
        }
      });
    }

    _pressed.close();
  }
}
