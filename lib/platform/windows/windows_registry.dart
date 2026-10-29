import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../autostart.dart';
import 'win32.dart' as w;

class WindowsRegistry {
  const WindowsRegistry._();

  static String? readString(String subKey, String name) {
    final Pointer<Utf16> sub = subKey.toNativeUtf16();
    final Pointer<Utf16> valueName = name.toNativeUtf16();
    final Pointer<IntPtr> key = calloc<IntPtr>();

    try {
      final int open = w.RegOpenKeyExW(
        w.HKEY_CURRENT_USER,
        sub,
        0,
        w.KEY_READ,
        key,
      );
      if (open != w.ERROR_SUCCESS) {
        return null;
      }

      try {
        final Pointer<Uint32> type = calloc<Uint32>();
        final Pointer<Uint32> size = calloc<Uint32>();

        try {
          int rc = w.RegQueryValueExW(
            key.value,
            valueName,
            nullptr,
            type,
            nullptr,
            size,
          );
          if (rc != w.ERROR_SUCCESS ||
              type.value != w.REG_SZ ||
              size.value == 0) {
            return null;
          }

          final Pointer<Uint8> data = calloc<Uint8>(size.value + 2);
          try {
            rc = w.RegQueryValueExW(
              key.value,
              valueName,
              nullptr,
              type,
              data,
              size,
            );
            if (rc != w.ERROR_SUCCESS) {
              return null;
            }
            return data.cast<Utf16>().toDartString();
          } finally {
            calloc.free(data);
          }
        } finally {
          calloc.free(type);
          calloc.free(size);
        }
      } finally {
        w.RegCloseKey(key.value);
      }
    } finally {
      calloc.free(sub);
      calloc.free(valueName);
      calloc.free(key);
    }
  }

  static int? readDword(String subKey, String name) {
    final Pointer<Utf16> sub = subKey.toNativeUtf16();
    final Pointer<Utf16> valueName = name.toNativeUtf16();
    final Pointer<IntPtr> key = calloc<IntPtr>();

    try {
      final int open = w.RegOpenKeyExW(
        w.HKEY_CURRENT_USER,
        sub,
        0,
        w.KEY_READ,
        key,
      );
      if (open != w.ERROR_SUCCESS) {
        return null;
      }

      try {
        final Pointer<Uint32> type = calloc<Uint32>();
        final Pointer<Uint32> size = calloc<Uint32>()..value = 4;
        final Pointer<Uint32> data = calloc<Uint32>();

        try {
          final int rc = w.RegQueryValueExW(
            key.value,
            valueName,
            nullptr,
            type,
            data.cast<Uint8>(),
            size,
          );
          if (rc != w.ERROR_SUCCESS || type.value != w.REG_DWORD) {
            return null;
          }
          return data.value;
        } finally {
          calloc.free(type);
          calloc.free(size);
          calloc.free(data);
        }
      } finally {
        w.RegCloseKey(key.value);
      }
    } finally {
      calloc.free(sub);
      calloc.free(valueName);
      calloc.free(key);
    }
  }

  static bool writeString(String subKey, String name, String value) {
    final Pointer<Utf16> sub = subKey.toNativeUtf16();
    final Pointer<Utf16> valueName = name.toNativeUtf16();
    final Pointer<Utf16> data = value.toNativeUtf16();
    final Pointer<IntPtr> key = calloc<IntPtr>();

    try {
      final int rc = w.RegCreateKeyExW(
        w.HKEY_CURRENT_USER,
        sub,
        0,
        nullptr,
        0,
        w.KEY_WRITE,
        nullptr,
        key,
        nullptr,
      );
      if (rc != w.ERROR_SUCCESS) {
        return false;
      }

      try {

        final int bytes = (value.length + 1) * 2;
        final int set = w.RegSetValueExW(
          key.value,
          valueName,
          0,
          w.REG_SZ,
          data.cast<Uint8>(),
          bytes,
        );
        return set == w.ERROR_SUCCESS;
      } finally {
        w.RegCloseKey(key.value);
      }
    } finally {
      calloc.free(sub);
      calloc.free(valueName);
      calloc.free(data);
      calloc.free(key);
    }
  }

  static bool deleteKey(String subKey) {
    final Pointer<Utf16> sub = subKey.toNativeUtf16();
    try {
      final int rc = w.RegDeleteKeyW(w.HKEY_CURRENT_USER, sub);
      return rc == w.ERROR_SUCCESS || rc == 2;
    } finally {
      calloc.free(sub);
    }
  }

  static bool deleteValue(String subKey, String name) {
    final Pointer<Utf16> sub = subKey.toNativeUtf16();
    final Pointer<Utf16> valueName = name.toNativeUtf16();
    final Pointer<IntPtr> key = calloc<IntPtr>();

    try {
      final int open = w.RegOpenKeyExW(
        w.HKEY_CURRENT_USER,
        sub,
        0,
        w.KEY_WRITE,
        key,
      );
      if (open != w.ERROR_SUCCESS) {

        return true;
      }

      try {
        final int rc = w.RegDeleteValueW(key.value, valueName);

        return rc == w.ERROR_SUCCESS || rc == 2;
      } finally {
        w.RegCloseKey(key.value);
      }
    } finally {
      calloc.free(sub);
      calloc.free(valueName);
      calloc.free(key);
    }
  }
}

class AutoStartManager implements AutoStart {
  static const String _registryPath =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _valueName = 'KeyFix';
  static const String startupArgument = '--startup';

  String _buildCommand(String executablePath) {
    final String full = File(executablePath).absolute.path;
    return '"$full" $startupArgument';
  }

  @override
  bool isEnabled() {
    try {
      final String? command = WindowsRegistry.readString(
        _registryPath,
        _valueName,
      );
      if (command == null) {
        return false;
      }

      final String expected = _buildCommand(Platform.resolvedExecutable);
      return command.toLowerCase() == expected.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  @override
  bool setEnabled(bool enabled) {
    try {
      if (!enabled) {
        return WindowsRegistry.deleteValue(_registryPath, _valueName);
      }

      return WindowsRegistry.writeString(
        _registryPath,
        _valueName,
        _buildCommand(Platform.resolvedExecutable),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void refreshCurrentPath() {
    try {
      final String? existing = WindowsRegistry.readString(
        _registryPath,
        _valueName,
      );
      if (existing == null) {
        return;
      }

      WindowsRegistry.writeString(
        _registryPath,
        _valueName,
        _buildCommand(Platform.resolvedExecutable),
      );
    } catch (_) {}
  }
}
