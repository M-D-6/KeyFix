import 'dart:io';

import '../autostart.dart';

class LinuxAutoStart implements AutoStart {
  static String get _path {
    final Map<String, String> env = Platform.environment;
    final String home = env['HOME'] ?? '.';
    final String base = env['XDG_CONFIG_HOME'] ?? '$home/.config';
    return '$base/autostart/keyfix.desktop';
  }

  static String _escapeExecArgument(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('%', '%%');
  }

  static String get _content {
    final Map<String, String> env = Platform.environment;
    final String? appImage = env['APPIMAGE'];
    final String executable = appImage != null && appImage.trim().isNotEmpty
        ? appImage
        : File(Platform.resolvedExecutable).absolute.path;
    final String escaped = _escapeExecArgument(executable);
    return '[Desktop Entry]\n'
        'Type=Application\n'
        'Name=KeyFix\n'
        'Exec="$escaped" --startup\n'
        'Icon=keyfix\n'
        'Terminal=false\n'
        'X-GNOME-Autostart-enabled=true\n';
  }

  @override
  bool isEnabled() {
    try {
      return File(_path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  bool setEnabled(bool enabled) {
    try {
      final File file = File(_path);
      if (!enabled) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        return true;
      }
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(_content);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void refreshCurrentPath() {
    try {
      final File file = File(_path);
      if (file.existsSync()) {
        final String content = _content;
        if (file.readAsStringSync() != content) {
          file.writeAsStringSync(content);
        }
      }
    } catch (_) {}
  }
}
